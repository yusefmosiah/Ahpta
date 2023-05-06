defmodule AhptaWeb.ConversationLive.Show do
  require Logger
  use AhptaWeb, :live_view
  use ExOpenAI.StreamingClient

  alias AhptaWeb.MessageLive
  alias Ahpta.Conversations
  alias Ahpta.Bots
  alias Ahpta.Messages
  alias Phoenix.LiveView.Components.MultiSelect

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_token = Map.get(session, "user_token")

    conversation = Conversations.get_conversation!(id)

    if connected?(socket), do: AhptaWeb.Endpoint.subscribe("convo:#{id}")

    socket =
      socket
      |> assign(:conversation, conversation)
      |> assign(:messages, conversation.messages)
      |> assign(:ongoing_messages, %{})
      |> assign(:dropdown_visible, false)
      |> assign(:subscribed_bots, [])
      |> assign(:context, get_context(conversation.messages))

    if connected?(socket) && user_token do
      user = Ahpta.Accounts.get_user_by_session_token(user_token)
      available_bots = Bots.get_bots_by_availability_and_ownership(user.id)

      available_bots =
        available_bots.availables_owned_by_user ++ available_bots.availables_not_owned_by_user

      bot_options =
        available_bots
        |> Enum.with_index(fn bot, index ->
          %{id: index, label: bot.name, selected: false}
        end)

      {
        :ok,
        socket
        |> assign(:current_user, user)
        |> assign(:available_bots, available_bots)
        |> assign(:bot_options, bot_options)
      }
    else
      {
        :ok,
        socket
        |> assign(:available_bots, [])
        |> assign(:bot_options, [])
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

  @impl true
  def handle_event("new_message", %{"message" => message_params}, socket) do
    attrs =
      message_params
      |> Map.put("conversation_id", socket.assigns.conversation.id)
      |> Map.put("sender_id", socket.assigns.current_user.id)

    case Ahpta.Messages.create_message(attrs) do
      {:ok, message} ->
        user_msg = %{role: "user", content: message.content}
        context = get_context(socket.assigns.messages) ++ [user_msg]

        for bot <- socket.assigns.subscribed_bots do
          messages = [%{role: "system", content: bot.system_message} | context]

          chat_module().create_chat_completion(messages, "gpt-4",
            stream: true,
            stream_to: self()
          )
        end

        AhptaWeb.Endpoint.broadcast_from(
          self(),
          "convo:#{socket.assigns.conversation.id}",
          "saved_message",
          message
        )

        {:noreply,
         socket
         |> assign(:messages, socket.assigns.messages ++ [message])}

      {:error, reason} ->
        Logger.error("Error creating message: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "saved_message"} = message, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message.payload])}
  end

  @impl true
  def handle_info(%{event: "streaming_message", payload: payload}, socket) do
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

  def handle_info({:updated_options, options}, socket) do
    Logger.info("Updated options: #{inspect(options)}")

    subscribed_bots =
      for option <- options, option.selected do
        bot = Bots.get_bot_by_name(option.label)
        Bots.subscribe_to_conversation(bot, socket.assigns.conversation)
        bot
      end

    bot_options =
      Enum.map(options, fn %{label: label, selected: selected} = option ->
        %{option | id: Enum.find_index(options, &(&1.label == label)), selected: selected}
      end)

    {:noreply,
     socket
     |> assign(:subscribed_bots, subscribed_bots)
     |> assign(:bot_options, bot_options)}
  end

  def handle_info(message, socket) do
    Logger.info("Unhandled message: #{inspect(message)}")
    {:noreply, socket}
  end

  def handle_data(%{choices: [%{delta: %{content: content}}], id: id}, socket) do
    ongoing_messages = Map.update(socket.assigns.ongoing_messages, id, content, &(&1 <> content))

    AhptaWeb.Endpoint.broadcast_from(
      self(),
      "convo:#{socket.assigns.conversation.id}",
      "streaming_message",
      %{id: id, content: content}
    )

    {:noreply, assign(socket, :ongoing_messages, ongoing_messages)}
  end

  @impl true
  def handle_data(%{choices: [%{delta: %{}, finish_reason: "stop"}], id: id}, socket) do
    content = Map.get(socket.assigns.ongoing_messages, id)

    attrs = %{
      "conversation_id" => socket.assigns.conversation.id,
      "sender_id" => socket.assigns.current_user.id,
      "content" => content,
      "message_type" => "bot"
    }

    {:ok, bot_message} = Ahpta.Messages.create_message(attrs)

    AhptaWeb.Endpoint.broadcast(
      "convo:#{socket.assigns.conversation.id}",
      "finished_streaming",
      %{bot_message: bot_message, id: id}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_data(data, socket) do
    Logger.info("weird got data: #{inspect(data)}")
    {:noreply, socket}
  end

  @impl true
  def handle_error(e, socket) do
    Logger.error("Handle_Error: #{inspect(e)}")
    {:noreply, socket}
  end

  @impl true
  def handle_finish(socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Conversation"
  defp page_title(:edit), do: "Edit Conversation"

  def get_context(messages, max_chars \\ 14_000) do
    messages
    |> Enum.reverse()
    |> Messages.to_openai_format()
    |> Enum.reduce_while({0, []}, fn message, {sum, result} ->
      content_length = byte_size(message.content)

      if sum + content_length <= max_chars do
        {:cont, {sum + content_length, [message | result]}}
      else
        {:halt, {sum, result}}
      end
    end)
    |> elem(1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-1/2 container mx-auto w-full">
      <div class="mx-auto py-6 dark:bg-black">
        <.header>
          <p class="font-mono mb-6 text-5xl font-bold leading-tight text-gray-900 dark:text-gray-100">
            <%= @conversation.topic %>
          </p>

          <.link
            patch={~p"/conversations/#{@conversation}/show/edit"}
            phx-click={JS.push_focus()}
            class="inline-block"
          >
            <.button class="font-mono inline-block rounded-lg border-4 border-double border-gray-500 p-4 text-gray-500 hover:border-white hover:bg-gray-500 hover:text-white dark:border-gray-400">
              Edit convo
            </.button>
          </.link>
        </.header>



        <div>

          <ul id="message-list" phx-update="replace" class="space-y-4">
            <md-block :for={message <- @messages} class="mt-5 mb-5 block" id={Ecto.UUID.generate()}>
              <li
                id={message.id}
                class="transform rounded-lg bg-white bg-opacity-40 p-4 shadow-lg backdrop-blur-md transition-all hover:-translate-y-1 dark:border-2 dark:border-double dark:border-gray-700 dark:bg-black dark:bg-opacity-50"
              >
                <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300">
                  <%= message.content %>
                </p>
              </li>
            </md-block>

            <md-block
              :for={{id, message} <- @ongoing_messages}
              class="mt-5 mb-5 block"
              id={Ecto.UUID.generate()}
            >
              <li
                id={id}
                class="transform rounded-lg bg-white bg-opacity-40 p-4 shadow-lg backdrop-blur-md transition-all hover:-translate-y-1 dark:border-2 dark:border-double dark:border-gray-700 dark:bg-black dark:bg-opacity-50"
              >
                <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300"><%= message %></p>
              </li>
            </md-block>
          </ul>
        </div>
        <div class="mt-6 space-y-4 dark:text-white">

          <.form :let={f} for={%{}} as={:input} phx-submit="new_message" class="mt-10">
            <MultiSelect.multi_select
              id="multi"
              options={@bot_options}
              form={f}
              on_change={fn opts -> send(self(), {:updated_options, opts}) end}
              placeholder="bots to send this message to..."
              search_placeholder="search bots..."
              class="autoresize w-full rounded border border-gray-300 p-2 dark:border-gray-600 dark:bg-black dark:text-gray-100"
            />

            <.input
              type="textarea"
              id="content"
              name="message[content]"
              placeholder="message content..."
              value=""
              required
              class="autoresize mt-4 w-full rounded border border-gray-300 p-2 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100"
            />
            <.input
              type="hidden"
              id="message_type"
              name="message[message_type]"
              value="human"
              required
            />
            <.button
              type="submit"
              class="font-mono mt-4 ml-2 rounded-md border-4 border-double border-blue-400 bg-none p-1.5 py-4 hover:border-blue-200 hover:bg-blue-400 hover:text-white dark:hover:border-blue-200 text-blue-400"
            >
              Send
            </.button>
          </.form>
        </div>

        <div class="mt-6 mb-10 flex items-center justify-between">
          <.link
            navigate={~p"/conversations"}
            class="font-mono inline-block rounded-lg border-4 border-double border-gray-500 p-4 text-gray-500 hover:border-white hover:bg-gray-500 hover:text-white dark:border-gray-400"
          >
            Convos
          </.link>
          <.link
            navigate={~p"/bots"}
            class="font-mono inline-block rounded-lg border-4 border-double border-gray-500 p-4 text-gray-500 hover:border-white hover:bg-gray-500 hover:text-white dark:border-gray-400"
          >
            Bots
          </.link>
        </div>

        <.modal
          :if={@live_action == :edit}
          id="conversation-modal"
          show
          on_cancel={JS.patch(~p"/conversations/#{@conversation}")}
        >
          <div>
            <.live_component
              module={AhptaWeb.ConversationLive.FormComponent}
              id={@conversation.id}
              title={@page_title}
              action={@live_action}
              conversation={@conversation}
              patch={~p"/conversations/#{@conversation}"}
            />
          </div>
        </.modal>
      </div>
    </div>
    """
  end

  defp chat_module do
    Application.get_env(:ahpta, :chat_module)
  end
end
