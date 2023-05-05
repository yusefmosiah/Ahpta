defmodule CapstoneWeb.ConversationLive.Show do
  require Logger
  use CapstoneWeb, :live_view
  use ExOpenAI.StreamingClient

  alias Capstone.Conversations
  alias Capstone.Bots
  alias Capstone.Messages
  alias Phoenix.LiveView.Components.MultiSelect

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_token = Map.get(session, "user_token")

    conversation = Conversations.get_conversation!(id)
    subscribed_bots = Bots.list_subscribed_bots_for_conversation(conversation)

    if connected?(socket), do: CapstoneWeb.Endpoint.subscribe("convo:#{id}")

    socket =
      socket
      |> assign(:conversation, conversation)
      |> assign(:messages, conversation.messages)
      |> assign(:ongoing_messages, %{})
      |> assign(:dropdown_visible, false)
      |> assign(:subscribed_bots, subscribed_bots)
      |> assign(:context, get_context(conversation.messages))
      |> assign(:summary, "")

    if connected?(socket) && user_token do
      user = Capstone.Accounts.get_user_by_session_token(user_token)
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

  def handle_event("subscribe_bot", %{"bot_id" => bot_id}, socket) do
    bot = Bots.get_bot!(bot_id)
    conversation = socket.assigns.conversation

    case Bots.subscribe_to_conversation(bot, conversation) do
      {:ok, _} ->
        {:noreply, assign(socket, :subscribed_bots, [bot | socket.assigns.subscribed_bots])}

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
        user_msg = %{role: "user", content: message.content}
        context = get_context(socket.assigns.messages) ++ [user_msg]
        # fixme - summarziation not getting called.
        # how do i have a safe seed from which to begin recursive summarization?
        summarize_if_needed(context)

        IO.inspect(socket.assigns.subscribed_bots, label: "IIIIN create_message subscribed bots")

        for bot <- socket.assigns.subscribed_bots do
          messages = [%{role: "system", content: bot.system_message} | context]

          chat_module().create_chat_completion(messages, "gpt-3.5-turbo",
            stream: true,
            stream_to: self()
          )
        end

        CapstoneWeb.Endpoint.broadcast_from(
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

  def handle_info({:summary, message}, socket) do
    Logger.info("Summary: #{inspect(message)}")

    {:noreply,
     socket
     |> assign(:context, [message | get_context(socket.assigns.messages)])
     |> assign(:summary, message.content)}
  end

  def handle_info({ref, {:summary, message}}, socket) do
    Logger.info("Summary (ref: #{inspect(ref)}): #{inspect(message)}")

    {:noreply,
     socket
     |> assign(:context, [message | get_context(socket.assigns.messages)])
     |> assign(:summary, message.content)}
  end

  # def handle_info({:updated_options, options}, socket) do
  #   Logger.info("Updated options: #{inspect(options)}")
  #   IO.inspect(socket.assigns.bot_options, label: "socket.assigns.bot_options")

  #   subscribed_bots =
  #     for option <- options, option.selected do
  #       bot = Bots.get_bot_by_name(option.label)
  #       Bots.subscribe_to_conversation(bot, socket.assigns.conversation)
  #       bot
  #     end

  #   unsubscribed_bots =
  #     for option <- options, !option.selected do
  #       bot = Bots.get_bot_by_name(option.label)
  #       Bots.unsubscribe_from_conversation(bot, socket.assigns.conversation)
  #       bot
  #     end
  #     |> IO.inspect(label: "uuuuunsubscribed_bots")

  #   subscribed_bot_options =
  #     subscribed_bots
  #     |> Enum.with_index(fn bot, index ->
  #       %{id: index, label: bot.name, selected: true}
  #     end)
  #     |> IO.inspect(label: "sssssubscribed_bot_options")

  #   unsubscribed_bot_options =
  #     unsubscribed_bots
  #     |> Enum.with_index(fn bot, index ->
  #       %{id: index, label: bot.name, selected: false}
  #     end)
  #     |> IO.inspect(label: "uuuuunsubscribed_bot_options")

  #   bot_options =
  #     Bots.merge_lists_by_id(
  #       socket.assigns.bot_options,
  #       subscribed_bot_options
  #     )
  #     |> IO.inspect(label: "aaaaabot_options")
  #     |> Bots.merge_lists_by_id(unsubscribed_bot_options)
  #     |> IO.inspect(label: "bbbbbot_options")

  #   {:noreply,
  #    socket
  #    |> assign(:subscribed_bots, subscribed_bots)
  #    |> assign(:bot_options, bot_options)}
  # end

  def handle_info({:updated_options, options}, socket) do
    Logger.info("Updated options: #{inspect(options)}")
    IO.inspect(socket.assigns.bot_options, label: "socket.assigns.bot_options")

    {subscribed_options, unsubscribed_options} = Enum.split_with(options, & &1.selected)

    process_options = fn opts, is_subscribed ->
      Enum.map(opts, fn option ->
        bot = Bots.get_bot_by_name(option.label)

        if is_subscribed do
          Bots.subscribe_to_conversation(bot, socket.assigns.conversation)
        else
          Bots.unsubscribe_from_conversation(bot, socket.assigns.conversation)
        end

        bot
      end)
    end

    subscribed_bots = process_options.(subscribed_options, true)

    bot_options =
      options
      |> Enum.with_index()
      |> Enum.map(fn {option, index} ->
        %{id: index, label: option.label, selected: option.selected}
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

    CapstoneWeb.Endpoint.broadcast_from(
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

    {:ok, bot_message} = Capstone.Messages.create_message(attrs)

    CapstoneWeb.Endpoint.broadcast(
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

  def get_context(messages, max_chars \\ 14000) do
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

  def summarize_if_needed(messages) do
    if messages |> Enum.map(& &1.content) |> Enum.join("\n") |> String.length() > 9000 do
      summarize(messages)
    end
  end

  def summarize(context, model \\ "gpt-3.5-turbo") do
    msgs = [
      %{
        role: "system",
        content: """
        Make a checkpoint (aka snapshot, summary) that consisely represents the content of the previous messages, possibly including a previous checkpoint.
        Begin the checkpoint message with "Checkpoint:".
        Remember, the checkpoint message will be included in the context of the next messages, and the user expects the chat to continue as though the context limit doesn't exist.
        """
      }
      | context
    ]

    Task.async(fn ->
      {:ok, response} = chat_module().create_chat_completion(msgs, model)
      summary = response.choices |> List.first() |> Map.get(:message)
      Logger.info("$$$$ got summary: #{inspect(summary)}")
      send(self(), {:summary, summary})
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-screen-xl px-4">
      <div class="mx-auto px-2 py-6 dark:bg-black">
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
              Edit conversation
            </.button>
          </.link>
        </.header>

        <div class="rounded-lg bg-white bg-opacity-40 p-6 text-lg shadow-md backdrop-blur-md dark:bg-black dark:bg-opacity-50 dark:text-white">
          <h3>Summary</h3>
          <p class="space-y-2 whitespace-pre-wrap leading-relaxed text-gray-900 dark:text-gray-300">
            <%= @summary %>
          </p>
        </div>

        <div class="mt-6 space-y-4">
          <h3>Subscribed Bots:</h3>
          <ul>
            <%= for bot <- @subscribed_bots do %>
              <li class="whitespace-pre-wrap text-gray-900 dark:text-gray-300">
                <%= bot.name %>
              </li>
            <% end %>
          </ul>
        </div>

        <div class="mt-6 space-y-4">
          <h3>Topic:</h3>
          <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300">
            <%= @conversation.topic %>
          </p>
          <h3>Is published:</h3>
          <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300">
            <%= @conversation.is_published %>
          </p>
        </div>

        <div>
          <h2>Messages:</h2>
          <ul id="message-list" phx-update="replace" class="space-y-4">
            <%= for message <- @messages do %>
              <li
                id={message.id}
                class="transform rounded-lg bg-white bg-opacity-40 p-4 shadow-lg backdrop-blur-md transition-all hover:-translate-y-1 dark:border-2 dark:border-double dark:border-gray-700 dark:bg-black dark:bg-opacity-50"
              >
                <strong></strong>
                <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300">
                  <%= message.content %>
                </p>
              </li>
            <% end %>
            <%= for {id, content} <- @ongoing_messages do %>
              <li
                id={id}
                class="transform rounded-lg bg-white bg-opacity-40 p-4 shadow-lg backdrop-blur-md transition-all hover:-translate-y-1 dark:border-2 dark:border-double dark:border-gray-700 dark:bg-black dark:bg-opacity-50"
              >
                <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300"><%= content %></p>
              </li>
            <% end %>
          </ul>
        </div>
        <div class="mt-6 space-y-4">
          <h2>New Message:</h2>
          <.form
            :let={f}
            for={%{}}
            as={:input}
            phx-submit="new_message"
            class="mt-10 flex items-center"
          >
            <MultiSelect.multi_select
              id="multi"
              options={@bot_options}
              form={f}
              on_change={fn opts -> send(self(), {:updated_options, opts}) end}
              placeholder="bots to send this message to..."
              search_placeholder="search bots..."
              class="autoresize w-full rounded border border-gray-300 p-2 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100"
            />
            <label for="content">Content:</label>
            <input
              type="textarea"
              id="content"
              name="message[content]"
              required
              class="autoresize w-full rounded border border-gray-300 p-2 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100"
            />
            <input
              type="hidden"
              id="message_type"
              name="message[message_type]"
              value="human"
              required
            />
            <.button
              type="submit"
              class="font-mono ml-2 rounded rounded-md border-4 border-double border-blue-400 bg-none p-1.5 py-4 text-blue-500 hover:border-blue-200 hover:bg-blue-500 hover:text-white dark:hover:border-blue-200 dark:hover:text-white"
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
              module={CapstoneWeb.ConversationLive.FormComponent}
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
    Application.get_env(:capstone, :chat_module)
  end
end
