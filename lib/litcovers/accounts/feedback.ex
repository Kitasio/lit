defmodule Litcovers.Accounts.Feedback do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feedbacks" do
    field :rating, :integer
    field :text, :string

    belongs_to :user, Litcovers.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:text, :rating])
    |> validate_required([:text])
    |> validate_length(:text, max: 600)
  end
end
