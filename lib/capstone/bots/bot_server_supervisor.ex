defmodule Capstone.Bots.BotServerSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_bot_server(args) do
    spec = {Capstone.Bots.BotServer, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_bot_server(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
