defmodule Gingerbread.Service.Entity.ModelTest do
    use Gingerbread.Service.Case

    alias Gingerbread.Service.Entity

    @valid_model %Entity.Model{
        identity: Ecto.UUID.generate(),
        entity: Ecto.UUID.generate(),
        active: false,
        name: "test"
    }

    test "empty" do
        refute_change(%Entity.Model{}, %{}, :insert_changeset)
    end

    test "only identity" do
        refute_change(%Entity.Model{}, %{ identity: @valid_model.identity }, :insert_changeset)

        assert_change(@valid_model, %{ identity: Ecto.UUID.generate() }, :update_changeset)
    end

    test "only entity" do
        refute_change(%Entity.Model{}, %{ entity: @valid_model.entity }, :insert_changeset)

        assert_change(@valid_model, %{ entity: Ecto.UUID.generate() }, :update_changeset)
    end

    test "only active" do
        refute_change(%Entity.Model{}, %{ active: @valid_model.active }, :insert_changeset)

        assert_change(@valid_model, %{ active: true }, :update_changeset)
    end

    test "only name" do
        refute_change(%Entity.Model{}, %{ name: @valid_model.name }, :insert_changeset)

        assert_change(@valid_model, %{ name: "foo" }, :update_changeset)
    end

    test "without identity" do
        refute_change(@valid_model, %{ identity: nil }, :insert_changeset)
    end

    test "without entity" do
        refute_change(@valid_model, %{ entity: nil }, :insert_changeset)
    end

    test "without active" do
        refute_change(@valid_model, %{ active: nil }, :insert_changeset)
    end

    test "without name" do
        assert_change(@valid_model, %{ name: nil }, :insert_changeset)
    end

    test "valid model" do
        assert_change(@valid_model, %{}, :insert_changeset)

        assert_change(@valid_model, %{}, :update_changeset)
    end

    test "uniqueness" do
        identity = Ecto.UUID.generate()
        identity2 = Regex.replace(~r/[\da-f]/, identity, fn
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
        end)
        entity = Gingerbread.Service.Repo.insert!(Entity.Model.insert_changeset(@valid_model, %{ entity: identity }))

        assert_change(@valid_model, %{ entity: identity }, :insert_changeset)
        |> assert_insert(:error)
        |> assert_error_value(:entity, { "has already been taken", [] })

        assert_change(@valid_model, %{ entity: identity2 }, :insert_changeset)
        |> assert_insert(:ok)
    end
end
