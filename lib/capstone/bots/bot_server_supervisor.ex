defmodule Capstone.Bots.BotServerSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_bot_server(bot_id) do
    key = bot_id

    case Registry.lookup(Capstone.BotRegistry, key) do
      [{pid, _key}] ->
        {:ok, pid}

      [] ->
        with {:ok, pid} <- start_bot_server_child([]),
             {:ok, pid} <- Registry.register(Capstone.BotRegistry, key, pid) do
          {:ok, pid}
        end
    end
    |> IO.inspect(label: "llllookup start_bot_server")
  end

  defp start_bot_server_child(args) do
    spec = {Capstone.Bots.BotServer, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_bot_server(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
