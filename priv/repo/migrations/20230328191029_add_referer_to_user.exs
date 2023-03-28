defmodule Litcovers.Repo.Migrations.AddRefererToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :referer, :string, default: nil
    end
  end
end
