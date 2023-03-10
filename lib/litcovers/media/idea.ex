defmodule Litcovers.Media.Idea do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ideas" do
    field :idea, :string

    belongs_to :image, Litcovers.Media.Image

    timestamps()
  end

  @doc false
  def changeset(idea, attrs) do
    idea
    |> cast(attrs, [:idea])
    |> validate_required([:idea])
  end
end
