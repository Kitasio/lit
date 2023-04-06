defmodule Litcovers.Repo.Migrations.AddLitAiBoolToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :lit_ai, :boolean, default: false
    end
  end
end
