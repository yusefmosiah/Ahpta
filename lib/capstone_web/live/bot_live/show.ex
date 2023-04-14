defmodule CapstoneWeb.BotLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.Bots

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:bot, Bots.get_bot!(id))}
  end

  defp page_title(:show), do: "Show Bot"
  defp page_title(:edit), do: "Edit Bot"
end
