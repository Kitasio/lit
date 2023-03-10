defmodule Litcovers.Media.Cover do
  use Ecto.Schema
  import Ecto.Changeset

  schema "covers" do
    field :seen, :boolean, default: false
    field :url, :string

    belongs_to :image, Litcovers.Media.Image
    belongs_to :user, Litcovers.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(cover, attrs) do
    cover
    |> cast(attrs, [:url, :seen])
    |> validate_required([:url, :seen])
  end
end
