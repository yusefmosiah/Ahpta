defmodule Capstone.Repo.Migrations.CreateSystemMessages do
  use Ecto.Migration

  def change do
    create table(:system_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :version, :integer
      add :timestamp, :naive_datetime
      add :bot_id, references(:bots, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:system_messages, [:bot_id])
  end
end
