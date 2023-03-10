defmodule Litcovers.Repo.Migrations.AddSessionGenerationsAndRelaxedModeToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :relaxed_mode, :boolean, default: false
      add :recent_generations, :integer, default: 0
    end
  end
end
