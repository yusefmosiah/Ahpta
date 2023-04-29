defmodule Capstone.Repo.Migrations.CreateBots do
  use Ecto.Migration

  def change do
    create table(:bots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :is_available_for_rent, :boolean, default: false, null: false
      add :system_message, :text, default: "", null: false
      add :owner_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:bots, [:owner_id])
  end
end
