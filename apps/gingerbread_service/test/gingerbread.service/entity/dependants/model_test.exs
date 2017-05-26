defmodule Gingerbread.Service.Entity.Dependants.ModelTest do
    use Gingerbread.Service.Case

    alias Gingerbread.Service.Entity

    @valid_model %Entity.Dependants.Model{
        parent_id: 1,
        child_id: 2,
    }

    test "empty" do
        refute_change(%Entity.Dependants.Model{}, %{})
    end

    test "only parent" do
        refute_change(%Entity.Dependants.Model{}, %{ parent_id: @valid_model.parent_id })
    end

    test "only child" do
        refute_change(%Entity.Dependants.Model{}, %{ child_id: @valid_model.child_id })
    end

    test "without parent" do
        refute_change(@valid_model, %{ parent_id: nil })
    end

    test "without child" do
        refute_change(@valid_model, %{ child_id: nil })
    end

    test "valid model" do
        assert_change(@valid_model, %{})
    end

    test "uniqueness" do
        next_identity = fn
            "0", _ -> "1"
            "1", _ -> "2"
            "2", _ -> "3"
            "3", _ -> "4"
            "4", _ -> "5"
            "5", _ -> "6"
            "6", _ -> "7"
            "7", _ -> "8"
            "8", _ -> "9"
            "9", _ -> "a"
            "a", _ -> "b"
            "b", _ -> "c"
            "c", _ -> "d"
            "d", _ -> "e"
            "e", _ -> "f"
            "f", _ -> "0"
        end

        identity = Ecto.UUID.generate()
        identity2 = Regex.replace(~r/[\da-f]/, identity, next_identity)
        identity3 = Regex.replace(~r/[\da-f]/, identity2, next_identity)
        entity = Gingerbread.Service.Repo.insert!(Entity.Model.insert_changeset(%Entity.Model{}, %{ identity: Ecto.UUID.generate(), entity: identity }))
        entity2 = Gingerbread.Service.Repo.insert!(Entity.Model.insert_changeset(%Entity.Model{}, %{ identity: Ecto.UUID.generate(), entity: identity2 }))
        entity3 = Gingerbread.Service.Repo.insert!(Entity.Model.insert_changeset(%Entity.Model{}, %{ identity: Ecto.UUID.generate(), entity: identity3 }))

        dependant = Gingerbread.Service.Repo.insert!(Entity.Dependants.Model.changeset(%Entity.Dependants.Model{}, %{ parent_id: entity.id, child_id: entity2.id }))

        assert_change(%Entity.Dependants.Model{}, %{ parent_id: dependant.parent_id, child_id: dependant.child_id })
        |> assert_insert(:error)
        |> assert_error_value(:relationship, { "has already been taken", [] })

        assert_change(%Entity.Dependants.Model{}, %{ parent_id: dependant.parent_id, child_id: entity3.id })
        |> assert_insert(:ok)

        assert_change(%Entity.Dependants.Model{}, %{ parent_id: entity3.id, child_id: dependant.child_id })
        |> assert_insert(:ok)
    end
end
