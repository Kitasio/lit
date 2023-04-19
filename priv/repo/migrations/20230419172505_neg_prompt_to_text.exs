defmodule Litcovers.Repo.Migrations.NegPromptToText do
  use Ecto.Migration

  def change do
    alter table(:images) do
      modify :negative_prompt, :text
    end
  end
end
