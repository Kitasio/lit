defmodule Litcovers.Repo.Migrations.AddAspectRatioToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :aspect_ratio, :string
    end
  end
end
