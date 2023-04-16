defmodule Litcovers.Metadata.UserChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chats" do
    field :content, :string
    field :preserve_composition, :boolean, default: false
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:content, :preserve_composition])
    |> validate_required([:content, :preserve_composition])
    |> validate_length(:content, min: 3, max: 100)
  end
end
