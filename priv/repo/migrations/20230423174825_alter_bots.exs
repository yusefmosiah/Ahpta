defmodule Capstone.Repo.Migrations.AlterBots do
  use Ecto.Migration

  def change do
    alter table(:bots) do
      add :bot_server_pid, :binary
    end
  end
end
