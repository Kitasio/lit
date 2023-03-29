defmodule Litcovers.Campaign.Referral do
  use Ecto.Schema
  import Ecto.Changeset

  schema "referrals" do
    field :code, :string
    field :discount, :float
    field :host, :string

    timestamps()
  end

  @doc false
  def changeset(referral, attrs) do
    referral
    |> cast(attrs, [:host, :discount, :code])
    |> validate_required([:host, :discount, :code])
  end
end
