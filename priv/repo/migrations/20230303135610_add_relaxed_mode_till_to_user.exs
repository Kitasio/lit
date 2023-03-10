defmodule Litcovers.Repo.Migrations.AddRelaxedModeTillToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :relaxed_mode_till, :naive_datetime
    end
  end
end
