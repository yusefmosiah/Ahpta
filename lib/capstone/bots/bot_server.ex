defmodule Capstone.Bots.BotServer do
  use GenServer
  alias Phoenix.PubSub

  ############################## PUBLIC API ##############################

  def start_link(opts) do
    name = opts[:name] || __MODULE__

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

    GenServer.start_link(__MODULE__, system_messages, name: name)
  end

  def join_conversation(pid_or_module \\ __MODULE__, conversation_id) do
    GenServer.call(pid_or_module, {:join_conversation, conversation_id})
  end

  def chat(pid_or_module \\ __MODULE__, conversation_id, message, model \\ "gpt-3.5-turbo") do
    GenServer.cast(pid_or_module, {:chat, conversation_id, message, model})
  end

  def get_context(pid_or_module \\ __MODULE__, conversation_id) do
    GenServer.call(pid_or_module, {:get_context, conversation_id})
  end

  def get_history(pid_or_module \\ __MODULE__, conversation_id) do
    GenServer.call(pid_or_module, {:get_history, conversation_id})
  end

  def get_state(pid_or_module \\ __MODULE__) do
    GenServer.call(pid_or_module, :get_state)
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
  def handle_call({:join_conversation, conversation_id}, _from, state) do
    conversation = %{
      context: [],
      history: [],
      total_tokens_used: 0
    }

    new_state = %{state | conversations: %{conversation_id => conversation}}

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
    {:reply, [conversation.history | state.system_messages] |> List.flatten(), state}
  end

  @impl true
  def handle_cast({:chat, conversation_id, message, model}, state) do
    {bot_message, _usage, new_conversation} = do_chat(message, model, state, conversation_id)

    new_state = put_in(state.conversations[conversation_id], new_conversation)

    PubSub.broadcast(Capstone.PubSub, "convo:#{conversation_id}", %{"bot_id" => bot_message})

    {:noreply, new_state}
  end

  ############################## PRIVATE FUNCTIONS ##############################

  def do_chat(message, model, state, conversation_id) do
    conversation = state.conversations[conversation_id]
    context = [conversation.context | state.system_messages] |> List.flatten()
    user_message = %{role: "user", content: message}

    msgs = [user_message | context]

    case chat_module().create_chat_completion(msgs |> Enum.reverse(), model) do
      {:ok, response} ->
        assistant_msg = unpack({:ok, response})

        new_conversation = %{
          conversation
          | context: [assistant_msg | [user_message | conversation.context]],
            history: [assistant_msg | [user_message | conversation.history]],
            total_tokens_used: conversation.total_tokens_used + response.usage.total_tokens
        }

        {assistant_msg, response.usage, new_conversation}

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
