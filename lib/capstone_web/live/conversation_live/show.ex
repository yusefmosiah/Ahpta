defmodule CapstoneWeb.ConversationLive.Show do
  require Logger
  use CapstoneWeb, :live_view
  use ExOpenAI.StreamingClient

  alias Capstone.Conversations
  alias Capstone.Bots

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_token = Map.get(session, "user_token")
    conversation = Conversations.get_conversation!(id)

    if connected?(socket), do: CapstoneWeb.Endpoint.subscribe("convo:#{id}")

    if connected?(socket) && user_token do
      user = Capstone.Accounts.get_user_by_session_token(user_token)

      available_bots =
        Bots.get_bots_by_availability_and_ownership(user.id)
        |> IO.inspect(label: "aaaavailable_bots")

      {
        :ok,
        socket
        |> assign(:conversation, conversation)
        |> assign(:messages, conversation.messages)
        |> assign(:current_user, user)
        |> assign(:ongoing_messages, %{})
        |> assign(
          :available_bots,
          available_bots.availables_owned_by_user ++ available_bots.availables_not_owned_by_user
        )
        |> assign(:dropdown_visible, false)
      }
    else
      {
        :ok,
        socket
        |> assign(:conversation, conversation)
        |> assign(:messages, conversation.messages)
        |> assign(:ongoing_messages, %{})
        |> assign(:available_bots, [])
        |> assign(:dropdown_visible, false)
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

  def handle_event("toggle_dropdown", _, socket) do
    {:noreply, update(socket, :dropdown_visible, &(!&1))}
  end

  def handle_event("subscribe_bot", %{"bot_id" => bot_id}, socket) do
    bot = Bots.get_bot!(bot_id)
    conversation = socket.assigns.conversation

    case Bots.subscribe_to_conversation(bot, conversation) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, :already_subscribed} ->
        {:noreply, socket |> put_flash(:error, "Bot is already subscribed to this conversation")}
    end
  end

  @impl true
  def handle_event("new_message", %{"message" => message_params}, socket) do
    attrs =
      message_params
      |> Map.put("conversation_id", socket.assigns.conversation.id)
      |> Map.put("sender_id", socket.assigns.current_user.id)

    case Capstone.Messages.create_message(attrs) do
      {:ok, message} ->
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
        Logger.error("Error creating message: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_data(data, socket) do
    # refactor to case
    with %ExOpenAI.Components.CreateChatCompletionResponse{
           choices: [%{delta: %{content: content}}],
           id: id
         } <- data do
      Logger.info("got data: #{inspect(data)}")

      ongoing_messages =
        Map.update(socket.assigns.ongoing_messages, id, content, &(&1 <> content))

      CapstoneWeb.Endpoint.broadcast_from(
        self(),
        "convo:#{socket.assigns.conversation.id}",
        "streaming_message",
        %{id: id, content: content}
      )

      {:noreply, assign(socket, :ongoing_messages, ongoing_messages)}
    else
      %ExOpenAI.Components.CreateChatCompletionResponse{
        choices: [%{delta: %{}, finish_reason: "stop"}],
        id: id
      } ->
        content = Map.get(socket.assigns.ongoing_messages, id)
        Logger.info("ccccontent: #{inspect(content)}")

        attrs = %{
          "conversation_id" => socket.assigns.conversation.id,
          "sender_id" => socket.assigns.current_user.id,
          "content" => content,
          "message_type" => "bot"
        }

        {:ok, bot_message} = Capstone.Messages.create_message(attrs)

        CapstoneWeb.Endpoint.broadcast(
          "convo:#{socket.assigns.conversation.id}",
          "finished_streaming",
          %{bot_message: bot_message, id: id}
        )

        {:noreply, socket}

      _ ->
        Logger.info("weird got data: #{inspect(data)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "saved_message"} = message, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message.payload])}
  end

  @impl true
  def handle_info(%{event: "streaming_message", payload: payload}, socket) do
    Logger.info("got streaming message: #{inspect(payload)}")

    ongoing_messages =
      Map.update(
        socket.assigns.ongoing_messages,
        payload.id,
        payload.content,
        &(&1 <> payload.content)
      )

    {:noreply, socket |> assign(:ongoing_messages, ongoing_messages)}
  end

  @impl true
  def handle_info(%{event: "finished_streaming"} = message, socket) do
    ongoing_messages = Map.delete(socket.assigns.ongoing_messages, message.payload.id)

    {:noreply,
     socket
     |> assign(:ongoing_messages, ongoing_messages)
     |> assign(:messages, socket.assigns.messages ++ [message.payload.bot_message])}
  end

  @impl true
  # callback on error
  def handle_error(e, socket) do
    Logger.error("Handle_Error: #{inspect(e)}")
    {:noreply, socket}
  end

  @impl true
  # callback on finish
  def handle_finish(socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Conversation"
  defp page_title(:edit), do: "Edit Conversation"
end
