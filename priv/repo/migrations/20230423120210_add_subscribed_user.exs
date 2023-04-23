defmodule Litcovers.Repo.Migrations.AddSubscribedUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :subscribed, :boolean, default: false
      add :subscription_expires_at, :naive_datetime
    end
  end
end
