defmodule Litcovers.Repo.Migrations.CreateTutorials do
  use Ecto.Migration

  def change do
    create table(:tutorials) do
      add :title, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:tutorials, [:user_id])
  end
end
