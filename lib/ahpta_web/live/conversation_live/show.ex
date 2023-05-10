defmodule AhptaWeb.ConversationLive.Show do
  require Logger
  use AhptaWeb, :live_view
  use ExOpenAI.StreamingClient

  alias Ahpta.Conversations
  alias Ahpta.Bots
  alias Ahpta.Messages
  alias Phoenix.LiveView.Components.MultiSelect
  alias AhptaWeb.Components.MessageListComponent

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
      |> assign(:context, Messages.get_context(conversation.messages))
      |> assign(:linked_messages, [])

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
        |> Enum.map(&MultiSelect.Option.new/1)

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

  def handle_event("update_topic", params, socket) do
    IO.inspect(params, label: "uuuuupdate_topic params")
    topic = params["topic"]

    {:ok, updated_convo} =
      Conversations.update_conversation(socket.assigns.conversation, %{topic: topic})

    IO.inspect(updated_convo.topic, label: "updated_convo")
    {:noreply, assign(socket, :conversation, updated_convo)}
  end

  def handle_event("toggle_dropdown", _, socket) do
    {:noreply, update(socket, :dropdown_visible, &(!&1))}
  end

  @impl true
  def handle_event("new_message", %{"message" => message_params}, socket) do
    # parse message_params.content for @bot tags
    # refactor to context
    # refactor attrs map contruction to use pattern matching
    attrs =
      message_params
      |> Map.put("conversation_id", socket.assigns.conversation.id)
      |> Map.put("sender_id", socket.assigns.current_user.id)

    # refactor the body of this code to messages context
    case Messages.create_message(attrs) do
      {:ok, message} ->
        Conversations.add_user_to_conversation(
          socket.assigns.current_user.id,
          socket.assigns.conversation.id
        )

        task_ref =
          Task.Supervisor.async_nolink(Ahpta.TaskSupervisor, fn ->
            Messages.handle_tasks(message)
          end)

        # fixme rename augmented prompt
        {:ok, {_usr_msg, augmented_prompt}} = Task.await(task_ref)

        ids = Enum.map(augmented_prompt, & &1["id"])

        linked_messages =
          Messages.get_messages_from_ids(ids)
          |> IO.inspect(label: "linked_messages")

        linked_messages_content =
          linked_messages
          |> Enum.map_join("\n\n", & &1.content)
          |> IO.inspect(label: "linked_messages_content")

        user_msg_content =
          "SIMILAR MESSAGES:\n#{linked_messages_content}\n\nUSER MESSAGE:\n#{message.content}"

        user_msg = %{role: "user", content: user_msg_content}

        # refactor above into messages context

        context = Messages.get_context(socket.assigns.messages) ++ [user_msg]

        for bot <- socket.assigns.subscribed_bots do
          messages = context ++ [%{role: "assistant", content: bot.system_message}]

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
         |> assign(:messages, socket.assigns.messages ++ [message])
         |> assign(:linked_messages, linked_messages)}

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

    task_ref =
      Task.Supervisor.async_nolink(Ahpta.TaskSupervisor, fn ->
        Messages.perform_bot_tasks(attrs)
      end)

    case Task.await(task_ref, 5000) do
      {:ok, bot_message} ->
        AhptaWeb.Endpoint.broadcast(
          "convo:#{socket.assigns.conversation.id}",
          "finished_streaming",
          %{bot_message: bot_message, id: id}
        )

      {:error, reason} ->
        Logger.error("Error creating message: #{inspect(reason)}")
    end

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-1/2 container mx-auto w-full pb-10">
      <div class="mx-auto dark:bg-black">
        <.header>
          <p class="font-mono mb-1 text-5xl font-bold leading-tight text-gray-900 dark:text-gray-100">
            <div class="flex-grow" id="content_editable" phx-hook="content_editable"></div>

            <form phx-change="update_topic">
              <input
                type="text"
                id={"topic-" <> @conversation.id}
                name="topic"
                value={@conversation.topic}
                spellcheck="false"
                autocomplete="off"
                class="font-mono rounded-lg border-zinc-200 text-5xl font-bold leading-tight dark:border-zinc-700 dark:bg-black dark:text-white"
              />
              <input type="hidden" name="id" value={@conversation.id} />
            </form>
          </p>

          <.link
            patch={~p"/conversations/#{@conversation}/show/edit"}
            phx-click={JS.push_focus()}
            class="inline-block"
          >
          </.link>
        </.header>

        <MessageListComponent.message_list messages={@messages} ongoing_messages={@ongoing_messages} />

        <%!-- new message form component --%>
        <div class="space-y-4 dark:text-white">
          <.form :let={f} for={%{}} as={:input} phx-submit="new_message" data-conversation-id={@conversation.id} class="">
            <.input
              type="textarea"
              id="content"
              name="message[content]"
              placeholder="message content..."
              value=""
              autofocus="true"
              required
              phx-hook="AutoResize"
              class="w-full resize-y rounded border-double border-gray-300 p-2 dark:border-gray-600 dark:bg-black dark:bg-gray-700 dark:text-gray-100"
            />
            <.input
              type="hidden"
              id="message_type"
              name="message[message_type]"
              value="human"
              required
            />
            <MultiSelect.multi_select
              id="multi"
              options={@bot_options}
              form={f}
              on_change={fn opts -> send(self(), {:updated_options, opts}) end}
              placeholder="bots to send this message to..."
              search_placeholder="search bots..."
              class="autoresize mt-4 w-full rounded dark:bg-black dark:text-gray-100"
            />
            <button
              type="submit"
              class="font-mono mt-4 rounded-md border-4 border-double border-blue-400 bg-none p-1 py-4 text-blue-400 hover:border-blue-200 hover:bg-blue-400 hover:text-white dark:hover:border-blue-200"
            >
              Send
            </button>
          </.form>
        </div>
        <%!-- /new message form component --%>

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
