defmodule Capstone.Repo.Migrations.CreateConversationParticipants do
  use Ecto.Migration

  def change do
    create table(:conversation_participants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :participant_type, :string
      add :owner_permission, :boolean, default: false, null: false
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :binary_id)
      add :participant_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:conversation_participants, [:conversation_id])
    create index(:conversation_participants, [:participant_id])
  end
end
