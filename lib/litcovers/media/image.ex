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
    field :parent_image_id, :integer, default: nil
    field :negative_prompt, :string
    field :style_preset, :string
    field :aspect_ratio, :string

    belongs_to :user, Litcovers.Accounts.User
    belongs_to :prompt, Litcovers.Metadata.Prompt

    has_many :ideas, Litcovers.Media.Idea, on_delete: :delete_all
    has_many :covers, Litcovers.Media.Cover, on_delete: :delete_all
    has_many :chats, Litcovers.Metadata.Chat, on_delete: :delete_all

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
      :final_prompt,
      :parent_image_id,
      :negative_prompt,
      :style_preset,
      :aspect_ratio
    ])
    |> validate_required([
      :description
    ])
    |> validate_length(:description, max: 600)
    |> validate_length(:style_preset, max: 50)
    |> validate_inclusion(:aspect_ratio, ["16:9", "1:1", "21:9", "2:3", "3:2", "4:5", "5:4", "9:16", "9:21"])
  end

  def api_changeset(image, attrs) do
    image
    |> cast(attrs, [:description, :style_preset, :model_name, :aspect_ratio])
    |> validate_required([
      :description,
      :style_preset
    ])
    |> validate_length(:description, max: 600)
    |> validate_length(:style_preset, max: 50)
    |> validate_inclusion(:aspect_ratio, ["16:9", "1:1", "21:9", "2:3", "3:2", "4:5", "5:4", "9:16", "9:21"])
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
