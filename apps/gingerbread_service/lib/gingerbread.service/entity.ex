defmodule Gingerbread.Service.Entity do
    @moduledoc """
      Manages unique (optionally tagged) entities.

      Entities are unique IDs that are associated with an identity and can have a tag to
      help identify them. Entities can be connected to other entities in order to map out
      various relationships between the entities.

      An entities unique ID will be static and remain unique for the entire lifetime of
      the database. This means that destroyed entities, only destroys the entity itself
      but does not make that ID re-available.
    """
    use GenServer

    alias Gingerbread.Service.Entity
    require Logger
    import Ecto.Query

    @type uuid :: String.t

    def start_link() do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def handle_call({ :create, { identity } }, _from, state), do: { :reply, create(identity), state }
    def handle_call({ :create, { identity, name } }, _from, state), do: { :reply, create(identity, name), state }
    def handle_call({ :destroy, { entity } }, _from, state), do: { :reply, destroy(entity), state }
    def handle_call({ :transfer, { entity, identity } }, _from, state), do: { :reply, transfer(entity, identity), state }
    def handle_call({ :add_child, { parent, child } }, _from, state), do: { :reply, add_child(parent, child), state }
    def handle_call({ :remove_child, { parent, child } }, _from, state), do: { :reply, remove_child(parent, child), state }
    def handle_call({ :entities, { identity } }, _from, state), do: { :reply, entities(identity), state }
    def handle_call({ :dependants, { entity } }, _from, state), do: { :reply, dependants(entity), state }
    def handle_call({ :name, { entity } }, _from, state), do: { :reply, name(entity), state }

    defp unique_entity({ :error, %{ errors: [entity: _] } }), do: unique_entity(Gingerbread.Service.Repo.insert(Entity.Model.insert_changeset(%Entity.Model{})))
    defp unique_entity(entity), do: entity

    @doc """
      Create a unique entity with a name (to help classify it) and an identity for it
      to be associated with.

      Returns `{ :ok, { name, entity } }` if the entity was created. Otherwise returns
      the reason for failure.
    """
    @spec create(uuid, atom | nil) :: { :ok, { atom | nil, uuid } } | { :error, String.t }
    def create(identity, name \\ nil) do
        case unique_entity(Gingerbread.Service.Repo.insert(Entity.Model.insert_changeset(%Entity.Model{}, %{ identity: identity, name: if(name != nil, do: to_string(name), else: nil) }))) do
            { :ok, %Entity.Model{ entity: entity, name: nil } } -> { :ok, { nil, entity } }
            { :ok, %Entity.Model{ entity: entity, name: name } } -> { :ok, { String.to_atom(name), entity } }
            { :error, changeset } ->
                Logger.debug("create entity: #{inspect(changeset.errors)}")
                { :error, "Failed to create entity" }
        end
    end

    @doc """
      Destroy an entity.

      After destruction an entity can no longer be used. But it's unique ID will remain,
      so services that depend on that ID being unique can work unaffected.

      Returns `:ok` if the entity was destroyed. Otherwise returns the reason for failure.
    """
    @spec destroy(uuid) :: :ok | { :error, String.t }
    def destroy(entity_id) do
        entity_query = from entity in Entity.Model,
            where: entity.entity == ^entity_id and entity.active == true

        case Gingerbread.Service.Repo.one(entity_query) do
            nil -> { :error, "Entity does not exist" }
            entity ->
                relationship_query = from relationship in Entity.Relationship.Model,
                    where: relationship.child_id == ^entity.id,
                    or_where: relationship.parent_id == ^entity.id

                transaction = Ecto.Multi.new
                |> Ecto.Multi.delete_all(:remove_relationships, relationship_query)
                |> Ecto.Multi.update(:make_inactive, Entity.Model.update_changeset(entity, %{ active: false }))

                case Gingerbread.Service.Repo.transaction(transaction) do
                    { :ok, _ } -> :ok
                    _ -> { :error, "Failed to destroy entity" }
                end
        end
    end

    @doc """
      Transfer an entity to a new identity.

      Returns `:ok` if the entity was transferred. Otherwise returns the reason for
      failure.
    """
    @spec transfer(uuid, uuid) :: :ok | { :error, String.t }
    def transfer(entity_id, identity) do
        query = from entity in Entity.Model,
            where: entity.entity == ^entity_id and entity.active == true

        with { :entity, entity = %Entity.Model{} } <- { :entity, Gingerbread.Service.Repo.one(query) },
             { :update, { :ok, _ } } <- { :update, Gingerbread.Service.Repo.update(Entity.Model.update_changeset(entity, %{ identity: identity })) } do
                :ok
        else
            { :entity, _ } -> { :error, "Entity does not exist" }
            { :update, _ } -> { :error, "Failed to transfer entity" }
        end
    end

    @doc """
      Create a parent-child relationship between two entities.

      Entity relationships can consist of any form (tree, circular, self, etc.).

      Returns `:ok` if the relationship was created. Otherwise returns the reason for
      failure.
    """
    @spec add_child(uuid, uuid) :: :ok | { :error, String.t }
    def add_child(parent, child) do
        parent_query = from entity in Entity.Model,
            where: entity.entity == ^parent and entity.active == true

        child_query = from entity in Entity.Model,
            where: entity.entity == ^child and entity.active == true

        with { :parent_entity, parent_entity = %Entity.Model{} } <- { :parent_entity, Gingerbread.Service.Repo.one(parent_query) },
             { :child_entity, child_entity = %Entity.Model{} } <- { :child_entity, Gingerbread.Service.Repo.one(child_query) },
             { :create_relationship, { :ok, _ } } <- { :create_relationship, Gingerbread.Service.Repo.insert(Entity.Relationship.Model.changeset(%Entity.Relationship.Model{}, %{ parent_id: parent_entity.id, child_id: child_entity.id })) } do
                :ok
        else
            { :parent_entity, _ } -> { :error, "Parent entity does not exist" }
            { :child_entity, _ } -> { :error, "Child entity does not exist" }
            { :create_relationship, _ } -> { :error, "Failed to create relationship" }
        end
    end

    @doc """
      Remove a parent-child relationship between two entities.

      Returns `:ok` if the relationship was removed. Otherwise returns the reason for
      failure.
    """
    @spec remove_child(uuid, uuid) :: :ok | { :error, String.t }
    def remove_child(parent, child) do
        query = from relationship in Entity.Relationship.Model,
            join: parent_entity in Entity.Model, on: parent_entity.id == relationship.parent_id and parent_entity.entity == ^parent,
            join: child_entity in Entity.Model, on: child_entity.id == relationship.child_id and child_entity.entity == ^child

        with { :relationship, relationship = %Entity.Relationship.Model{} } <- { :relationship, Gingerbread.Service.Repo.one(query) },
             { :delete, { :ok, _ } } <- { :delete, Gingerbread.Service.Repo.delete(relationship) } do
                :ok
        else
            { :relationship, _ } -> { :error, "Relationship does not exist" }
            { :delete, _ } -> { :error, "Failed to remove relationship" }
        end
    end

    @doc """
      Get the entities associated with the given identity.

      Returns the list of entities belonging to the identity, where each entity is a
      tagged entity `{ name, entity }`.
    """
    @spec entities(uuid) :: [{ atom | nil, uuid }]
    def entities(identity) do
        query = from entity in Entity.Model,
            where: entity.identity == ^identity and entity.active == true,
            select: { entity.name, entity.entity }

        Gingerbread.Service.Repo.all(query)
        |> Enum.map(fn
            { nil, entity } -> { nil, entity }
            { name, entity } -> { String.to_atom(name), entity }
        end)
    end

    @doc """
      Get the children of an entity.

      Returns the list of entities belonging to the entity, where each entity is a tagged
      entity `{ name, entity }`.
    """
    @spec dependants(uuid) :: [{ atom | nil, uuid }]
    def dependants(entity) do
        query = from relationship in Entity.Relationship.Model,
            join: parent_entity in Entity.Model, on: parent_entity.id == relationship.parent_id and parent_entity.entity == ^entity,
            join: child_entity in Entity.Model, on: child_entity.id == relationship.child_id,
            select: { child_entity.name, child_entity.entity }

        Gingerbread.Service.Repo.all(query)
        |> Enum.map(fn
            { nil, entity } -> { nil, entity }
            { name, entity } -> { String.to_atom(name), entity }
        end)
    end

    @doc """
      Get the name of an entity.

      Returns `{ :ok, name }` if successful. Otherwise returns the reason for failure.
    """
    @spec name(uuid) :: { :ok, atom | nil } | { :error, String.t }
    def name(entity_id) do
        query = from entity in Entity.Model,
            where: entity.entity == ^entity_id and entity.active == true

        case Gingerbread.Service.Repo.one(query) do
            %Entity.Model{ name: nil } -> { :ok, nil }
            %Entity.Model{ name: name } -> { :ok, String.to_atom(name) }
            nil -> { :error, "Entity does not exist" }
        end
    end
end
