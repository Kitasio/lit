defmodule Litcovers.Repo.Migrations.AddUnlockedBoolToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :unlocked, :boolean, default: false
    end
  end
end
