defmodule Litcovers.Metadata.UserChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chats" do
    field :content, :string
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> validate_length(:content, min: 3, max: 100)
  end
end
