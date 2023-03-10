defmodule Litcovers.Repo.Migrations.AddSeenBoolToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :seen, :boolean, default: false
    end
  end
end
