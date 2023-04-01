defmodule Litcovers.Repo.Migrations.ModifyDefaultLicoinsOne do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :litcoins, :integer, default: 1
    end
  end
end
