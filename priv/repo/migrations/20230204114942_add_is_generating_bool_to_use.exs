defmodule Litcovers.Repo.Migrations.AddIsGeneratingBoolToUse do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_generating, :boolean, default: false
    end
  end
end
