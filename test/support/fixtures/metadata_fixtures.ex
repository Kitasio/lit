defmodule Litcovers.MetadataFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Litcovers.Metadata` context.
  """

  @doc """
  Generate a tutotial.
  """
  def tutotial_fixture(attrs \\ %{}) do
    {:ok, tutotial} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> Litcovers.Metadata.create_tutotial()

    tutotial
  end

  @doc """
  Generate a chat.
  """
  def chat_fixture(attrs \\ %{}) do
    {:ok, chat} =
      attrs
      |> Enum.into(%{
        content: "some content",
        role: "some role"
      })
      |> Litcovers.Metadata.create_chat()

    chat
  end
end
