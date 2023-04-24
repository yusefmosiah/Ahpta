defmodule CapstoneWeb.SystemMessageLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.SystemMessages

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:system_message, SystemMessages.get_system_message!(id))}
  end

  defp page_title(:show), do: "Show System message"
  defp page_title(:edit), do: "Edit System message"
end
