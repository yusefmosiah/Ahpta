defmodule Capstone.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :timestamp, :naive_datetime
      add :message_type, :string
      add :sender_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:messages, [:sender_id])
    create index(:messages, [:conversation_id])
  end
end
