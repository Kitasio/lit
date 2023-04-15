defmodule Litcovers.Metadata.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chats" do
    field :content, :string
    field :role, :string

    belongs_to :image, Litcovers.Media.Image

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:role, :content])
    |> validate_required([:role, :content])
  end
end
