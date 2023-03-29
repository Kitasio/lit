defmodule Litcovers.Repo.Migrations.CreateReferrals do
  use Ecto.Migration

  def change do
    create table(:referrals) do
      add :host, :string
      add :discount, :float
      add :code, :string

      timestamps()
    end
  end
end
