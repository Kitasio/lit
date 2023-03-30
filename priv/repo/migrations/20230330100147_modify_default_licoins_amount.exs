defmodule Litcovers.Repo.Migrations.ModifyDefaultLicoinsAmount do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :litcoins, :integer, default: 0
    end
  end
end
