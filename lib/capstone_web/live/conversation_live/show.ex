defmodule CapstoneWeb.ConversationLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.Conversations

  @impl true
  def mount(%{"id" => id}, %{"user_token" => user_token}, socket) do
    if connected?(socket) do
      CapstoneWeb.Endpoint.subscribe("convo:#{id}")
      conversation = Conversations.get_conversation!(id)

      {:ok, pid} = Capstone.Bots.BotServerSupervisor.start_bot_server([])
      Capstone.Bots.BotServer.join_conversation(pid, conversation)

      user = Capstone.Accounts.get_user_by_session_token(user_token)

      {:ok,
       socket
       |> assign(:conversation, conversation)
       |> assign(:messages, conversation.messages)
       |> assign(:current_user, user)}
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
  def handle_event("new_message", %{"message" => message_params} = message, socket) do
    IO.inspect(message, label: "hhhhhandle_event message")

    attrs =
      message_params
      |> Map.put("conversation_id", socket.assigns.conversation.id)
      |> Map.put("sender_id", socket.assigns.current_user.id)

    case Capstone.Messages.create_message(attrs) do
      {:ok, message} ->
        CapstoneWeb.Endpoint.broadcast_from(
          self(),
          "convo:#{socket.assigns.conversation.id}",
          "new_message",
          message
        )

        {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}

      {:error, reason} ->
        IO.inspect(reason, label: "rrrrreason")
        {:noreply, socket}


    end
  end

  @impl true
  def handle_info(%{event: "new_message"} = message, socket) do
    IO.inspect(message, label: "rrrrreceived message")

    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message.payload])}
  end

  @impl true
  def handle_info(%{"bot_message" => payload} = message, socket) do
    IO.inspect(message, label: "xxxxx message")

    {:ok, new_message} =
      Capstone.Messages.create_message(%{
        "conversation_id" => socket.assigns.conversation.id,
        "sender_id" => socket.assigns.current_user.id,
        "content" => payload.content,
        "message_type" => "bot"
      })

    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [new_message])}
  end

  defp page_title(:show), do: "Show Conversation"
  defp page_title(:edit), do: "Edit Conversation"
end
