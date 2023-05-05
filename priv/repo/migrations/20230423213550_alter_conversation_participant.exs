defmodule Ahpta.Repo.Migrations.AlterConversationParticipant do
  use Ecto.Migration

  def change do
    alter table(:conversation_participants) do
      add(:bot_id, references(:bots, type: :binary_id))
    end

    create(index(:conversation_participants, [:bot_id]))
  end
end
