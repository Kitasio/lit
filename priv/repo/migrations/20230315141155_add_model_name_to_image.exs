defmodule Litcovers.Repo.Migrations.AddModelNameToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :model_name, :string
    end
  end
end
