defmodule Gingerbread.Service.EntityTest do
    use Gingerbread.Service.Case

    alias Gingerbread.Service.Entity

    setup do
        { :ok, %{ identity: Ecto.UUID.generate() } }
    end

    test "create entity", %{ identity: identity } do
        assert { :ok, { nil, entity1 } } = Entity.create(identity)
        assert { :ok, { :test, entity2 } } = Entity.create(identity, :test)
        assert { :ok, nil } == Entity.name(entity1)
        assert { :ok, :test } == Entity.name(entity2)
    end

    test "destroy entity", %{ identity: identity } do
        { :ok, { nil, entity } } = Entity.create(identity)

        assert :ok == Entity.destroy(entity)
        assert { :error, "Entity does not exist" } == Entity.destroy(entity)
        assert { :error, "Entity does not exist" } == Entity.name(entity)
    end

    test "transferring entity", %{ identity: identity } do
        { :ok, { nil, entity } } = Entity.create(identity)

        assert { :ok, identity } == Entity.identity(entity)

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

        assert :ok == Entity.transfer(entity, identity2)
        assert { :ok, identity2 } == Entity.identity(entity)
        assert [] == Entity.entities(identity)
        assert [{ nil, entity }] == Entity.entities(identity2)

        :ok = Entity.destroy(entity)

        assert { :error, "Entity does not exist" } == Entity.transfer(entity, identity)
        assert { :error, "Entity does not exist" } == Entity.identity(entity)
        assert [] == Entity.entities(identity)
        assert [] == Entity.entities(identity2)
    end

    test "entity relationship", %{ identity: identity } do
        { :ok, { nil, entity1 } } = Entity.create(identity)
        { :ok, { nil, entity2 } } = Entity.create(identity)
        { :ok, { nil, entity3 } } = Entity.create(identity)

        assert :ok == Entity.add_child(entity1, entity1)
        assert :ok == Entity.add_child(entity1, entity2)
        assert :ok == Entity.add_child(entity1, entity3)
        assert :ok == Entity.add_child(entity2, entity1)
        assert :ok == Entity.add_child(entity3, entity2)

        assert { :error, "Failed to create relationship" } == Entity.add_child(entity1, entity1)
        assert { :error, "Failed to create relationship" } == Entity.add_child(entity1, entity2)
        assert { :error, "Failed to create relationship" } == Entity.add_child(entity1, entity3)
        assert { :error, "Failed to create relationship" } == Entity.add_child(entity2, entity1)
        assert { :error, "Failed to create relationship" } == Entity.add_child(entity3, entity2)

        assert Enum.sort([{ nil, entity1 }, { nil, entity2 }, { nil, entity3 }]) == Enum.sort(Entity.dependants(entity1))
        assert Enum.sort([{ nil, entity1 }]) == Enum.sort(Entity.dependants(entity2))
        assert Enum.sort([{ nil, entity2 }]) == Enum.sort(Entity.dependants(entity3))

        assert :ok == Entity.remove_child(entity1, entity1)
        assert { :error, "Relationship does not exist" } == Entity.remove_child(entity1, entity1)

        :ok = Entity.destroy(entity2)

        assert [{ nil, entity3 }] == Enum.sort(Entity.dependants(entity1))
        assert [] == Enum.sort(Entity.dependants(entity2))
        assert [] == Enum.sort(Entity.dependants(entity3))

        assert { :error, "Child entity does not exist" } == Entity.add_child(entity1, entity2)
        assert { :error, "Parent entity does not exist" } == Entity.add_child(entity2, entity1)
    end
end
