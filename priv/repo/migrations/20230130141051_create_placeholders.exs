defmodule Litcovers.Repo.Migrations.CreatePlaceholders do
  use Ecto.Migration

  def change do
    create table(:placeholders) do
      add :author, :string
      add :title, :string
      add :description, :text

      timestamps()
    end
  end
end
