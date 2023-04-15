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

  describe "chats" do
    alias Litcovers.Metadata.Chat

    import Litcovers.MetadataFixtures

    @invalid_attrs %{content: nil, role: nil}

    test "list_chats/0 returns all chats" do
      chat = chat_fixture()
      assert Metadata.list_chats() == [chat]
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = chat_fixture()
      assert Metadata.get_chat!(chat.id) == chat
    end

    test "create_chat/1 with valid data creates a chat" do
      valid_attrs = %{content: "some content", role: "some role"}

      assert {:ok, %Chat{} = chat} = Metadata.create_chat(valid_attrs)
      assert chat.content == "some content"
      assert chat.role == "some role"
    end

    test "create_chat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Metadata.create_chat(@invalid_attrs)
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = chat_fixture()
      update_attrs = %{content: "some updated content", role: "some updated role"}

      assert {:ok, %Chat{} = chat} = Metadata.update_chat(chat, update_attrs)
      assert chat.content == "some updated content"
      assert chat.role == "some updated role"
    end

    test "update_chat/2 with invalid data returns error changeset" do
      chat = chat_fixture()
      assert {:error, %Ecto.Changeset{}} = Metadata.update_chat(chat, @invalid_attrs)
      assert chat == Metadata.get_chat!(chat.id)
    end

    test "delete_chat/1 deletes the chat" do
      chat = chat_fixture()
      assert {:ok, %Chat{}} = Metadata.delete_chat(chat)
      assert_raise Ecto.NoResultsError, fn -> Metadata.get_chat!(chat.id) end
    end

    test "change_chat/1 returns a chat changeset" do
      chat = chat_fixture()
      assert %Ecto.Changeset{} = Metadata.change_chat(chat)
    end
  end
end
