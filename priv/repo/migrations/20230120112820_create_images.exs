defmodule Litcovers.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :url, :string
      add :description, :text
      add :completed, :boolean, default: false, null: false
      add :width, :integer
      add :height, :integer
      add :prompt, :text
      add :character_gender, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:images, [:user_id])
  end
end
