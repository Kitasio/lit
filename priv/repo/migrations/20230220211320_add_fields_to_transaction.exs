defmodule Litcovers.Repo.Migrations.AddFieldsToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :tnx_id, :string
      add :status, :string
      add :paid, :boolean
    end
  end
end
