defmodule Litcovers.Repo.Migrations.CreateCovers do
  use Ecto.Migration

  def change do
    create table(:covers) do
      add :url, :string
      add :seen, :boolean, default: false, null: false
      add :image_id, references(:images, on_delete: :nothing)

      timestamps()
    end

    create index(:covers, [:image_id])
  end
end
