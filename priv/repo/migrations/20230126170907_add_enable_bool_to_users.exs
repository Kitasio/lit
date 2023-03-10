defmodule Litcovers.Repo.Migrations.AddEnableBoolToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :enabled, :boolean, default: false
    end
  end
end
