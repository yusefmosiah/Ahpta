defmodule CapstoneWeb.ConversationParticipantLive.Index do
  use CapstoneWeb, :live_view

  alias Capstone.Conversations
  alias Capstone.Conversations.ConversationParticipant

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(socket, :conversation_participants, Conversations.list_conversation_participants())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Conversation participant")
    |> assign(:conversation_participant, Conversations.get_conversation_participant!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Conversation participant")
    |> assign(:conversation_participant, %ConversationParticipant{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversation participants")
    |> assign(:conversation_participant, nil)
  end

  @impl true
  def handle_info(
        {CapstoneWeb.ConversationParticipantLive.FormComponent,
         {:saved, conversation_participant}},
        socket
      ) do
    {:noreply, stream_insert(socket, :conversation_participants, conversation_participant)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    conversation_participant = Conversations.get_conversation_participant!(id)
    {:ok, _} = Conversations.delete_conversation_participant(conversation_participant)

    {:noreply, stream_delete(socket, :conversation_participants, conversation_participant)}
  end
end
