defmodule Litcovers.Repo.Migrations.AddDiscountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :discount, :float, default: 1
    end
  end
end
