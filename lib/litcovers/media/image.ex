defmodule Litcovers.Media.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :character_gender, :string
    field :completed, :boolean, default: false
    field :description, :string
    field :height, :integer
    field :url, :string
    field :width, :integer
    field :favorite, :boolean, default: false
    field :unlocked, :boolean, default: true
    field :seen, :boolean, default: false
    field :model_name, :string
    field :lit_ai, :boolean, default: false
    field :final_prompt, :string

    belongs_to :user, Litcovers.Accounts.User
    belongs_to :prompt, Litcovers.Metadata.Prompt

    has_many :ideas, Litcovers.Media.Idea, on_delete: :delete_all
    has_many :covers, Litcovers.Media.Cover, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [
      :url,
      :description,
      :completed,
      :unlocked,
      :width,
      :height,
      :character_gender,
      :favorite,
      :seen,
      :model_name,
      :lit_ai,
      :final_prompt
    ])
    |> validate_required([
      :description,
      :width,
      :height,
      :character_gender
    ])
    |> validate_length(:description, max: 600)
  end

  def ai_changeset(image, attrs) do
    image
    |> cast(attrs, [:completed, :url, :model_name])
  end

  def unlocked_changeset(image, attrs) do
    image
    |> cast(attrs, [:unlocked])
  end
end
