defmodule Litcovers.Repo.Migrations.ModifyUserEnabledByDefault do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :enabled, :boolean, default: true
    end
  end
end
