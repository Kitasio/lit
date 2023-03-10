defmodule Litcovers.Metadata.Placeholder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "placeholders" do
    field :author, :string
    field :description, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(placeholder, attrs) do
    placeholder
    |> cast(attrs, [:author, :title, :description])
    |> validate_required([:author, :title, :description])
  end
end
