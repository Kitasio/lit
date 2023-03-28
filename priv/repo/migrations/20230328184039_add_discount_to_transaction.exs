defmodule Litcovers.Repo.Migrations.AddDiscountToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :discount, :integer, default: 0
    end
  end
end
