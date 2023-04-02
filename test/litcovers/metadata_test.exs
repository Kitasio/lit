defmodule Litcovers.MetadataTest do
  use Litcovers.DataCase

  alias Litcovers.Metadata

  describe "tutorials" do
    alias Litcovers.Metadata.Tutotial

    import Litcovers.MetadataFixtures

    @invalid_attrs %{title: nil}

    test "list_tutorials/0 returns all tutorials" do
      tutotial = tutotial_fixture()
      assert Metadata.list_tutorials() == [tutotial]
    end

    test "get_tutotial!/1 returns the tutotial with given id" do
      tutotial = tutotial_fixture()
      assert Metadata.get_tutotial!(tutotial.id) == tutotial
    end

    test "create_tutotial/1 with valid data creates a tutotial" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Tutotial{} = tutotial} = Metadata.create_tutotial(valid_attrs)
      assert tutotial.title == "some title"
    end

    test "create_tutotial/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Metadata.create_tutotial(@invalid_attrs)
    end

    test "update_tutotial/2 with valid data updates the tutotial" do
      tutotial = tutotial_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Tutotial{} = tutotial} = Metadata.update_tutotial(tutotial, update_attrs)
      assert tutotial.title == "some updated title"
    end

    test "update_tutotial/2 with invalid data returns error changeset" do
      tutotial = tutotial_fixture()
      assert {:error, %Ecto.Changeset{}} = Metadata.update_tutotial(tutotial, @invalid_attrs)
      assert tutotial == Metadata.get_tutotial!(tutotial.id)
    end

    test "delete_tutotial/1 deletes the tutotial" do
      tutotial = tutotial_fixture()
      assert {:ok, %Tutotial{}} = Metadata.delete_tutotial(tutotial)
      assert_raise Ecto.NoResultsError, fn -> Metadata.get_tutotial!(tutotial.id) end
    end

    test "change_tutotial/1 returns a tutotial changeset" do
      tutotial = tutotial_fixture()
      assert %Ecto.Changeset{} = Metadata.change_tutotial(tutotial)
    end
  end
end
