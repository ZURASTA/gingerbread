defmodule Gingerbread.Service.Entity do
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

    defp unique_entity({ :error, %{ errors: [entity: _] } }), do: unique_entity(Gingerbread.Service.Repo.insert(Entity.Model.insert_changeset(%Entity.Model{})))
    defp unique_entity(entity), do: entity

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

    @spec entities(uuid) :: [uuid]
    def entities(identity) do
        query = from entity in Entity.Model,
            where: entity.identity == ^identity and entity.active == true,
            select: entity.entity

        Gingerbread.Service.Repo.all(query)
    end

    @spec dependants(uuid) :: [uuid]
    def dependants(entity) do
        query = from relationship in Entity.Relationship.Model,
            join: parent_entity in Entity.Model, on: parent_entity.id == relationship.parent_id and parent_entity.entity == ^entity,
            join: child_entity in Entity.Model, on: child_entity.id == relationship.child_id,
            select: child_entity.entity

        Gingerbread.Service.Repo.all(query)
    end
end
