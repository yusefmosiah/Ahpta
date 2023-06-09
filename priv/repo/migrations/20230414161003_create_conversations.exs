defmodule Ahpta.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :topic, :string
      add :is_published, :boolean, default: false, null: false

      timestamps()
    end
  end
end
