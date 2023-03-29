defmodule Litcovers.CampaignFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Litcovers.Campaign` context.
  """

  @doc """
  Generate a referral.
  """
  def referral_fixture(attrs \\ %{}) do
    {:ok, referral} =
      attrs
      |> Enum.into(%{
        code: "some code",
        discount: 120.5,
        host: "some host"
      })
      |> Litcovers.Campaign.create_referral()

    referral
  end
end
