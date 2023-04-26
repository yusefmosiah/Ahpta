defmodule CapstoneWeb.ConversationLive.Show do
  use CapstoneWeb, :live_view
  use ExOpenAI.StreamingClient

  alias Capstone.Conversations
  alias Capstone.Bots.BotServer

  defp dummy_message() do
    %Capstone.Messages.Message{
      content: "",
      message_type: "dummy",
      sender_id: Ecto.UUID.generate(),
      conversation_id: Ecto.UUID.generate()
    }
  end

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_token = Map.get(session, "user_token")
    conversation = Conversations.get_conversation!(id)

    if connected?(socket), do: CapstoneWeb.Endpoint.subscribe("convo:#{id}")

    if connected?(socket) && user_token do
      user = Capstone.Accounts.get_user_by_session_token(user_token)

      {
        :ok,
        socket
        |> assign(:conversation, conversation)
        |> assign(:messages, conversation.messages)
        |> assign(:current_user, user)
        |> assign(:streaming_message, dummy_message())
        #  |> assign(:bot_server_pids, pids)
        #  |> assign(
        #    :available_bots,
        #    bots.availables_owned_by_user ++ bots.availables_not_owned_by_user
        #  )
      }
    else
      {
        :ok,
        socket
        |> assign(:conversation, conversation)
        |> assign(:messages, conversation.messages)
        |> assign(:streaming_message, dummy_message())
        #  |> assign(:available_bots, [])
      }
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

        messages = [%{role: "user", content: message.content}]

        ExOpenAI.Chat.create_chat_completion(messages, "gpt-3.5-turbo",
          stream: true,
          stream_to: self()
        )

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
  def handle_data(data, socket) do
    with %ExOpenAI.Components.CreateChatCompletionResponse{
           choices: [%{delta: %{content: content}}]
         } <- data do
      IO.puts("got data: #{inspect(data)}")

      message = %Capstone.Messages.Message{
        conversation_id: socket.assigns.conversation.id,
        sender_id: socket.assigns.current_user.id,
        content: content,
        message_type: "bot"
      }

      IO.inspect(message, lable: "mmmmmessage created")

      CapstoneWeb.Endpoint.broadcast(
        "convo:#{socket.assigns.conversation.id}",
        "streaming_message",
        content
      )

      {:noreply, socket}
    else
      _ ->
        IO.puts("got data: #{inspect(data)}")
        {:noreply, socket}
    end
  end

  def handle_info(%{event: "streaming_message", payload: payload}, socket) do
    IO.inspect(payload, label: "ppppayload")

    streaming_message =
      socket.assigns.streaming_message
      |> Map.put(:content, socket.assigns.streaming_message.content <> payload)
      |> IO.inspect(label: "sssstreaming_message")

    IO.inspect(socket.assigns.messages |> List.last(), label: "lllllast message")
    {:noreply, socket |> assign(:streaming_message, streaming_message)}
  end

  @impl true
  # callback on error
  def handle_error(e, socket) do
    IO.puts("got error: #{inspect(e)}")
    {:noreply, socket}
  end

  @impl true
  # callback on finish
  def handle_finish(socket) do
    attrs = %{
      "conversation_id" => socket.assigns.conversation.id,
      "sender_id" => socket.assigns.current_user.id,
      "content" => socket.assigns.streaming_message.content,
      "message_type" => "bot"
    }

    # fixme: error handling
    {:ok, message} = Capstone.Messages.create_message(attrs)

    CapstoneWeb.Endpoint.broadcast(
      "convo:#{socket.assigns.conversation.id}",
      "finished_streaming",
      message
    )

    {:noreply, socket}
  end

  def handle_info(%{event: "finished_streaming"} = message, socket) do
    IO.inspect(message, label: "rrrrreceived message")

    {:noreply,
     assign(socket,
       streaming_message: dummy_message(),
       messages: socket.assigns.messages ++ [message.payload]
     )}
  end

  defp page_title(:show), do: "Show Conversation"
  defp page_title(:edit), do: "Edit Conversation"
end
