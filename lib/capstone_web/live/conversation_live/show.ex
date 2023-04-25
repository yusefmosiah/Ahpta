defmodule CapstoneWeb.ConversationLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.Conversations

  @impl true
  def mount(%{"id" => id}, %{"user_token" => user_token}, socket) do
    if connected?(socket) do

    CapstoneWeb.Endpoint.subscribe("convo:#{id}")
    conversation = Conversations.get_conversation!(id)

    user = Capstone.Accounts.get_user_by_session_token(user_token)

    {:ok, pid} = Capstone.Bots.BotServerSupervisor.start_bot_server([])
    IO.inspect(pid, label: "pid")
    Capstone.Bots.BotServer.join_conversation(pid, conversation)

    {:ok,
     socket
     |> assign(:conversation, conversation)
     |> assign(:messages, conversation.messages)
     |> assign(:current_user, user)}
    else
      {:ok, :socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:conversation, Conversations.get_conversation!(id))}
  end

  @impl true
  def handle_event("new_message", %{"message" => message_params}, socket) do
    attrs =
      message_params
      |> Map.put("conversation_id", socket.assigns.conversation.id)
      |> Map.put("sender_id", socket.assigns.current_user.id)
      |> IO.inspect(label: "aaaatrs sage_params")

    case Capstone.Messages.create_message(attrs) do
      {:ok, message} ->
        CapstoneWeb.Endpoint.broadcast(
          "convo:#{socket.assigns.conversation.id}",
          "new_message",
          message
        )

        {:noreply, socket}

      {:error, reason} ->
        IO.inspect(reason, label: "rrrrreason")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "new_message"} = message, socket) do
    IO.inspect(message, label: "rrrrreceived message")

    IO.inspect(socket, label: "socket")
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message.payload])}
  end

  defp page_title(:show), do: "Show Conversation"
  defp page_title(:edit), do: "Edit Conversation"
end
