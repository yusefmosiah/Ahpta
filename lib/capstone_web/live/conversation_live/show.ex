defmodule CapstoneWeb.ConversationLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.Conversations
  alias Capstone.Bots.BotServer

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_token = Map.get(session, "user_token")
    conversation = Conversations.get_conversation!(id)

    if connected?(socket), do: CapstoneWeb.Endpoint.subscribe("convo:#{id}")

    if connected?(socket) && user_token do
      user = Capstone.Accounts.get_user_by_session_token(user_token)
      bots = Capstone.Bots.get_bots_by_availability_and_ownership(user.id)

      pids =
        Conversations.get_bots_in_conversation(id)
        |> IO.inspect(label: "boooooot ids")
        |> Enum.map(fn bot_id ->
          IO.inspect(bot_id, label: "bbbbot id")
          {:ok, pid} = Capstone.Bots.BotServerSupervisor.start_bot_server(bot_id)
          pid
        end)

      IO.inspect(pids, label: "bot ppppids")
      IO.inspect(self(), label: "seeeeeeelf pid")

      pids
      |> Enum.each(fn pid -> Capstone.Bots.BotServer.join_conversation(pid, conversation) end)

      {:ok,
       socket
       |> assign(:conversation, conversation)
       |> assign(:messages, conversation.messages)
       |> assign(:current_user, user)
       |> assign(:bot_server_pids, pids)
       |> assign(
         :available_bots,
         bots.availables_owned_by_user ++ bots.availables_not_owned_by_user
       )}
    else
      {:ok,
       socket
       |> assign(:conversation, conversation)
       |> assign(:messages, conversation.messages)
       |> assign(:available_bots, [])}
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
      |> IO.inspect(label: "aaaatrs sage_params")

    case Capstone.Messages.create_message(attrs) do
      {:ok, message} ->
        IO.inspect(message, label: "mmmmmessage")

        socket.assigns.bot_server_pids
        |> IO.inspect(label: "sssssocket.assigns.bot_server_pids")
        |> Enum.each(fn pid ->
          BotServer.chat(
            pid,
            message_params["content"],
            socket.assigns.conversation.id,
            socket.assigns.current_user.id
          )
        end)

        CapstoneWeb.Endpoint.broadcast_from(
          self(),
          "convo:#{socket.assigns.conversation.id}",
          "saved_message",
          message
        )

        {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}

      {:error, reason} ->
        IO.inspect(reason, label: "rrrrreason")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_bot", %{"bot_id" => bot_id}, socket) do
    Conversations.get_bots_in_conversation(socket.assigns.conversation.id)
    |> IO.inspect(label: "b4 add cp")

    attrs =
      %{
        "conversation_id" => socket.assigns.conversation.id,
        "participant_id" => nil,
        "bot_id" => bot_id,
        "participant_type" => "bot",
        "owner_permission" => "true"
      }
      |> IO.inspect(label: "aaaaattttrs")

    case Capstone.Conversations.create_conversation_participant(attrs) do
      {:ok, conversation_participant} ->
        IO.inspect(conversation_participant, label: "ccccconversation_participant")

        Conversations.get_bots_in_conversation(socket.assigns.conversation.id)
        |> IO.inspect(label: "after add cp")

        {:noreply, socket}

      {:error, reason} ->
        IO.inspect(reason, label: "rrrrreason")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "saved_message"} = message, socket) do
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
