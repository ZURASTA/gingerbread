defmodule Gingerbread.API.Entity do
    @moduledoc """
      Manages unique (optionally tagged) entities.

      Entities are unique IDs that are associated with an identity and can have a tag to
      help identify them. Entities can be connected to other entities in order to map out
      various relationships between the entities.

      An entities unique ID will be static and remain unique for the entire lifetime of
      the database. This means that destroyed entities, only destroys the entity itself
      but does not make that ID re-available.
    """

    @type uuid :: String.t

    @service Gingerbread.Service.Entity

    @doc """
      Create a unique entity with a name (to help classify it) and an identity for it
      to be associated with.

      Returns `{ :ok, { name, entity } }` if the entity was created. Otherwise returns
      the reason for failure.
    """
    @spec create(uuid, atom | nil) :: { :ok, { atom | nil, uuid } } | { :error, String.t }
    def create(identity, name \\ nil) do
        GenServer.call(@service, { :create, { identity, name } })
    end

    @doc """
      Destroy an entity.

      After destruction an entity can no longer be used. But it's unique ID will remain,
      so services that depend on that ID being unique can work unaffected.

      Returns `:ok` if the entity was destroyed. Otherwise returns the reason for failure.
    """
    @spec destroy(uuid) :: :ok | { :error, String.t }
    def destroy(entity) do
        GenServer.call(@service, { :destroy, { entity } })
    end

    @doc """
      Transfer an entity to a new identity.

      Returns `:ok` if the entity was transferred. Otherwise returns the reason for
      failure.
    """
    @spec transfer(uuid, uuid) :: :ok | { :error, String.t }
    def transfer(entity, identity) do
        GenServer.call(@service, { :transfer, { entity, identity } })
    end

    @doc """
      Create a parent-child relationship between two entities.

      Entity relationships can consist of any form (tree, circular, self, etc.).

      Returns `:ok` if the relationship was created. Otherwise returns the reason for
      failure.
    """
    @spec add_child(uuid, uuid) :: :ok | { :error, String.t }
    def add_child(parent, child) do
        GenServer.call(@service, { :add_child, { parent, child } })
    end

    @doc """
      Remove a parent-child relationship between two entities.

      Returns `:ok` if the relationship was removed. Otherwise returns the reason for
      failure.
    """
    @spec remove_child(uuid, uuid) :: :ok | { :error, String.t }
    def remove_child(parent, child) do
        GenServer.call(@service, { :remove_child, { parent, child } })
    end

    @doc """
      Get the entities associated with the given identity.

      Returns the list of entities belonging to the identity, where each entity is a
      tagged entity `{ name, entity }`.
    """
    @spec entities(uuid) :: [{ atom | nil, uuid }]
    def entities(identity) do
        GenServer.call(@service, { :entities, { identity } })
    end

    @doc """
      Get the children of an entity.

      Returns the list of entities belonging to the entity, where each entity is a tagged
      entity `{ name, entity }`.
    """
    @spec dependants(uuid) :: [{ atom | nil, uuid }]
    def dependants(entity) do
        GenServer.call(@service, { :dependants, { entity } })
    end

    @doc """
      Get the name of an entity.

      Returns `{ :ok, name }` if successful. Otherwise returns the reason for failure.
    """
    @spec name(uuid) :: { :ok, atom | nil } | { :error, String.t }
    def name(entity) do
        GenServer.call(@service, { :name, { entity } })
    end
end
