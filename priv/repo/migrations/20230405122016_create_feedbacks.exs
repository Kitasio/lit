defmodule Litcovers.Repo.Migrations.CreateFeedbacks do
  use Ecto.Migration

  def change do
    create table(:feedbacks) do
      add :text, :text
      add :rating, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:feedbacks, [:user_id])
  end
end
