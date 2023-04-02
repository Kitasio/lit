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
end
