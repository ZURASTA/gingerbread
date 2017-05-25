defmodule Gingerbread.Service.Entity.Model do
    use Ecto.Schema
    import Ecto
    import Ecto.Changeset
    import Protecto
    @moduledoc """
      A model representing an entity.

      ##Fields

      ###:id
      Is the unique reference to the entity entry. Is an `integer`.

      ###:identity
      Is the identity the entity belongs to. Is an `UUID`.

      ###:entity
      Is the unique ID to externally reference the entity entry. Is an `UUID`.

      ###:active
      Indicates whether the entity is active or inactive. Is a `boolean`.

      ###:name
      Is the name of the entity. Is a `string`.
    """

    schema "entities" do
        field :identity, Ecto.UUID
        field :entity, Ecto.UUID
        field :active, :boolean
        field :name, :string
        timestamps()
    end

    @doc """
      Builds a changeset for insertion based on the `struct` and `params`.

      Enforces:
      * `identity` field is required
      * `entity` field is required
      * `active` field is not empty
      * `entity` field is unique
    """
    def insert_changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:identity, :entity, :active, :name])
        |> validate_required([:identity, :entity])
        |> validate_emptiness(:active)
        |> unique_constraint(:entity)
    end

    @doc """
      Builds a changeset for update based on the `struct` and `params`.

      Enforces:
      * `identity` field is not empty
      * `entity` field is not empty
      * `active` field is not empty
      * `entity` field is unique
    """
    def update_changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:identity, :entity, :active, :name])
        |> validate_emptiness(:identity)
        |> validate_emptiness(:entity)
        |> validate_emptiness(:active)
        |> unique_constraint(:entity)
    end
end
