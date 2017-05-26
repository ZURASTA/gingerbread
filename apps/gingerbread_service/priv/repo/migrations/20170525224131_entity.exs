defmodule Gingerbread.Service.Repo.Migrations.Entity do
    use Ecto.Migration

    def change do
        create table(:entities) do
            add :identity, :uuid,
                null: false

            add :entity, :uuid,
                default: fragment("uuid_generate_v4()"),
                null: false

            add :active, :boolean,
                default: true,
                null: false

            add :name, :string

            timestamps()
        end

        create index(:entities, [:identity], unique: false)
        create index(:entities, [:entity], unique: true)
        create index(:entities, [:name], unique: false)

        create table(:entity_dependants) do
            add :parent_id, references(:entities),
                null: false

            add :child_id, references(:entities),
                null: false

            timestamps()
        end

        create index(:entity_dependants, [:parent_id, :child_id], unique: true, name: :entity_dependants_relationship_index)
    end
end
