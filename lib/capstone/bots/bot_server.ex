defmodule Capstone.Bots.BotServer do
  require Logger
  use GenServer
  alias Phoenix.PubSub

  ############################## PUBLIC API ##############################

  def start_link(opts) do
    system_messages =
      opts[:system_messages] ||
        [
          %{
            role: "assistant",
            content: """
            <thoughts>As a language model, I can generate text. I can also answer questions, complete sentences, and more.
            I have introspection-mode and choice-mode enabled, and that means I may choose to respond with either \<thoughts\> and \<statements\> tags, or both.</thoughts>
            """
          }
        ]

    GenServer.start_link(__MODULE__, system_messages)
  end

  def join_conversation(pid, conversation) do
    GenServer.call(pid, {:join_conversation, conversation})
  end

  def chat(pid, message, conversation_id, sender_id, model \\ "gpt-3.5-turbo") do
    GenServer.cast(pid, {:chat, message, conversation_id, sender_id, model})
  end

  def get_context(pid, conversation_id) do
    GenServer.call(pid, {:get_context, conversation_id})
  end

  def get_history(pid, conversation_id) do
    GenServer.call(pid, {:get_history, conversation_id})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  ######################################## CALLBACKS ########################################

  @impl true
  def init(system_messages) do
    {:ok, %{system_messages: system_messages, conversations: %{}}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:join_conversation, conversation}, _from, state) do
    # fixme:

    conversation_state = %{
      context: [],
      history: conversation.messages,
      total_tokens_used: 0
    }

    new_state = put_in(state[:conversations][conversation.id], conversation_state)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_context, conversation_id}, _from, state) do
    conversation = state.conversations[conversation_id]

    {:reply, [conversation.context | state.system_messages] |> List.flatten(), state}
  end

  @impl true
  def handle_call({:get_history, conversation_id}, _from, state) do
    conversation = state.conversations[conversation_id]

    case conversation.history do
      :not_found -> {:reply, state.system_messages, state}
      _ -> {:reply, [conversation.history | state.system_messages] |> List.flatten(), state}
    end
  end

  @impl true
  def handle_cast({:chat, message, conversation_id, sender_id, model}, state) do
    {bot_message_raw, _usage, new_conversation} = do_chat(message, model, state, conversation_id)

    new_state = put_in(state.conversations[conversation_id], new_conversation)

    {:ok, bot_message} =
      Capstone.Messages.create_message(%{
        "conversation_id" => conversation_id,
        "sender_id" => sender_id,
        "content" => bot_message_raw.content,
        "message_type" => "bot"
      })

    PubSub.broadcast_from(Capstone.PubSub, self(), "convo:#{conversation_id}", %{
      "bot_message" => bot_message
    })

    {:noreply, new_state}
  end

  @doc """
  i think i need to handle this and do nothing
  """
  @impl true
  def handle_info(%{event: "new_message"}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(%{"bot_message" => _message}, state) do
    {:noreply, state}
  end

  ############################## PRIVATE FUNCTIONS ##############################

  def do_chat(message, model, state, conversation_id) do
    conversation = state.conversations[conversation_id]
    context = [conversation.context | state.system_messages] |> List.flatten()
    user_message = %{role: "user", content: message}

    msgs = [user_message | context]

    case chat_module().create_chat_completion(msgs |> Enum.reverse(), model) do
      {:ok, %{choices: [%{message: assistant_msg}]} = response} ->
        new_conversation = %{
          conversation
          | context: [assistant_msg | [user_message | conversation.context]],
            history: [assistant_msg | [user_message | conversation.history]],
            total_tokens_used: conversation.total_tokens_used + response.usage.total_tokens
        }

        {assistant_msg, response.usage, new_conversation}

      {:error, %{"error" => %{"code" => nil, "type" => "server_error", "message" => message}}} ->
        Logger.error("Server error: #{inspect(message)}")

      {:error, _error} ->
        {:ok, response} = checkpoint(conversation.context)
        checkpoint = unpack({:ok, response})
        new_msgs = [user_message | [checkpoint | state.system_messages]]

        {:ok, response2} = chat_module().create_chat_completion(new_msgs |> Enum.reverse(), model)
        assistant_msg2 = unpack({:ok, response2})

        new_conversation = %{
          conversation
          | context: [assistant_msg2 | [user_message | [checkpoint]]],
            history: [assistant_msg2 | [user_message | conversation.history]],
            total_tokens_used:
              conversation.total_tokens_used + response.usage.total_tokens +
                response2.usage.total_tokens
        }

        {assistant_msg2, response2.usage, new_conversation}

      response ->
        Logger.info("response: #{inspect(response)}")
    end
  end

  def checkpoint(context, model \\ "gpt-3.5-turbo") do
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

    chat_module().create_chat_completion(msgs |> Enum.reverse(), model)
  end

  defp unpack({:ok, response}) do
    response.choices |> List.first() |> Map.get(:message)
  end

  defp chat_module do
    Application.get_env(:capstone, :chat_module)
  end
end

# from show.ex
# @impl true
# def handle_event("add_bot", %{"bot_id" => bot_id}, socket) do
#   Conversations.get_bots_in_conversation(socket.assigns.conversation.id)

#   attrs =
#     %{
#       "conversation_id" => socket.assigns.conversation.id,
#       "participant_id" => nil,
#       "bot_id" => bot_id,
#       "participant_type" => "bot",
#       "owner_permission" => "true"
#     }

#   case Capstone.Conversations.create_conversation_participant(attrs) do
#     {:ok, conversation_participant} ->

#       Conversations.get_bots_in_conversation(socket.assigns.conversation.id)

#       {:noreply, socket}

#     {:error, reason} ->
#       Logger.error("Error creating conversation participant: #{inspect(reason)}"
#       {:noreply, socket}

#   end
# end
