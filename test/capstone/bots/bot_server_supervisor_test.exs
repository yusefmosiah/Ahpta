defmodule Capstone.Bots.BotServerSupervisorTest do
  use ExUnit.Case
  alias Capstone.Bots.BotServerSupervisor

  test "start_bot_server/1 starts a bot server successfully" do
    args = [name: :test_bot_server]
    assert {:ok, pid} = BotServerSupervisor.start_bot_server(args)
    assert is_pid(pid)
  end

  test "stop_bot_server/1 stops a bot server successfully" do
    args = [name: :test_bot_server_to_stop]
    {:ok, pid} = BotServerSupervisor.start_bot_server(args)
    assert is_pid(pid)

    :ok = BotServerSupervisor.stop_bot_server(pid)
    assert Process.alive?(pid) == false
  end

  test "stop_bot_server/1 with an invalid pid returns an error" do
    invalid_pid = self()
    assert {:error, :not_found} = BotServerSupervisor.stop_bot_server(invalid_pid)
  end
end
