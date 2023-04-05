defmodule Litcovers.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Litcovers.Accounts` context.
  """

  @doc """
  Generate a feedback.
  """
  def feedback_fixture(attrs \\ %{}) do
    {:ok, feedback} =
      attrs
      |> Enum.into(%{
        rating: 42,
        text: "some text"
      })
      |> Litcovers.Accounts.create_feedback()

    feedback
  end
end
