defmodule Litcovers.Repo.Migrations.CoversBelongsToUserToo do
  use Ecto.Migration

  def change do
    alter table(:covers) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create index(:covers, [:user_id])
  end
end
