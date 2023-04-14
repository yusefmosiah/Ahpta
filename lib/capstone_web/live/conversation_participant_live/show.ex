defmodule CapstoneWeb.ConversationParticipantLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.Conversations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:conversation_participant, Conversations.get_conversation_participant!(id))}
  end

  defp page_title(:show), do: "Show Conversation participant"
  defp page_title(:edit), do: "Edit Conversation participant"
end
