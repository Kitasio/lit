defmodule Litcovers.Metadata.Tutotial do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tutorials" do
    field :title, :string

    belongs_to :user, Litcovers.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(tutotial, attrs) do
    tutotial
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
