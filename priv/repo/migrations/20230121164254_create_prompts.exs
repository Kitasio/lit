defmodule Litcovers.Repo.Migrations.CreatePrompts do
  use Ecto.Migration

  def change do
    create table(:prompts) do
      add :name, :string
      add :realm, :string
      add :sentiment, :string
      add :type, :string
      add :style_prompt, :string
      add :image_url, :string

      timestamps()
    end
  end
end
