defmodule Litcovers.Repo.Migrations.AddFavoriteBoolToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :favorite, :boolean, default: false, null: false
    end
  end
end
