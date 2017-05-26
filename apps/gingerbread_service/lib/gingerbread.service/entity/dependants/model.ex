defmodule Gingerbread.Service.Entity.Dependants.Model do
    use Ecto.Schema
    import Ecto
    import Ecto.Changeset
    import Protecto
    @moduledoc """
      A model representing an entity relationship.

      ##Fields

      ###:id
      Is the unique reference to the entity entry. Is an `integer`.

      ###:parent_id
      Is the reference to the entity that is the parent in this relationship. Is an
      `integer` to `Gingerbread.Service.Entity.Model`.

      ###:child_id
      Is the reference to the entity that is the parent in this relationship. Is an
      `integer` to `Gingerbread.Service.Entity.Model`.
    """

    schema "entity_dependants" do
        belongs_to :parent, Gingerbread.Service.Entity.Model
        belongs_to :child, Gingerbread.Service.Entity.Model
        timestamps()
    end

    @doc """
      Builds a changeset for the `struct` and `params`.

      Enforces:
      * `parent_id` field is required
      * `child_id` field is required
      * `parent_id` field is associated with an entry in `Gingerbread.Service.Entity.Model`
      * `child_id` field is associated with an entry in `Gingerbread.Service.Entity.Model`
      * checks uniqueness of relationship
    """
    def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:parent_id, :child_id])
        |> validate_required([:parent_id, :child_id])
        |> assoc_constraint(:parent)
        |> assoc_constraint(:child)
        |> unique_constraint(:relationship)
    end
end
