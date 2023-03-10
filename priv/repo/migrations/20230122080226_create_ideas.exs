defmodule Litcovers.Repo.Migrations.CreateIdeas do
  use Ecto.Migration

  def change do
    create table(:ideas) do
      add :idea, :string
      add :seen, :boolean, default: false
      add :image_id, references(:images, on_delete: :nothing)

      timestamps()
    end

    create index(:ideas, [:image_id])
  end
end
