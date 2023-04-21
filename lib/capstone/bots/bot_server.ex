defmodule Capstone.Bots.BotServer do
  @moduledoc """
  The BotServer.
  """
  use GenServer
  alias ExOpenAI.Chat

  def start_link(opts) do
    name = opts[:name] || __MODULE__

    # refactor after testing to be system_messages list.
    system_messages =
      opts[:system_message] ||
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

  @doc """
  Sends a chat message to the bot server expecting a response. really, should be a cast not GenServer.call.
  When this bot server gets hooked up to pubsub, the bot will handle a "chat" message and publish its response.

  Handler hanldes a `chat` call to the bot server by calling `do_chat` message valid.
  If the message length exceeds 15000 characters, the bot server will reply with an error message.
  The 15000 character limit equals my first approximation of 4000 tokens (~ 3000 words).
  Further versions will adopt more intelligent token counting, using a tokenizer module.
  """
  def chat(pid_or_module \\ __MODULE__, message, model \\ "gpt-3.5-turbo") do
    GenServer.call(pid_or_module, {:chat, message, model}, 50000)
  end

  @doc """
  Gets the `context` of the bot server.

  Handler handles a `get_cotext` call to the bot server.
  Context, unlike history, gets summarized by the bot server to keep within the token limit.
  Context, like history, includes the system_message(s).
  """
  def get_context(pid_or_module \\ __MODULE__) do
    GenServer.call(pid_or_module, :get_context)
  end

  @doc """
  Gets the `history` of the bot server.

  Handler handles a `get_history` call to the bot server.
  History, unlike context, does not get summarized by the bot server.
  History, like context, includes the system_message(s).
  """
  def get_history(pid_or_module \\ __MODULE__) do
    GenServer.call(pid_or_module, :get_history)
  end

  ######################################## CAlLLBACKS  ########################################

  @doc """
  Initializes the bot server.
  """
  @impl true
  def init([system_messages]) do
    {:ok,
     %{
       system_message: system_messages,
       context: [],
       history: [],
       total_tokens_used: 0
     }}
  end

  @impl true
  def handle_call(:get_context, _from, state) do
    {:reply, [state.context | [state.system_message]] |> List.flatten(), state}
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, [state.history | [state.system_message]], state}
  end

  @impl true
  def handle_call({:chat, message, model}, _from, state) do
    cond do
      String.length(message) > 15000 ->
        reply = "Message too long. Please keep it under 3000 words."
        {:reply, {reply, %{total_tokens: 0}}, state}

      String.length(message) <= 15000 ->
        do_chat(message, model, state)
    end
  end

  @doc """
    do_chat does most of the work for the bot server.
    It calls the OpenAI API, and handles the response.
    With an error response, it calls `summarize` to summarize the context and then calls the API again.
    Other API errors should be handled as well; context should not be lost because of an API error.
  """
  def do_chat(message, model, state) do
    context = [state.context | [state.system_message]] |> List.flatten()
    user_message = %{role: "user", content: message}

    msgs = [user_message | context]

    case Chat.create_chat_completion(msgs |> Enum.reverse(), model) do
      {:ok, response} ->
        assistant_msg = unpack({:ok, response})

        new_state = %{
          state
          | context: [assistant_msg | [user_message | state.context]],
            history: [assistant_msg | [user_message | state.history]],
            total_tokens_used: state.total_tokens_used + response.usage.total_tokens
        }

        {:reply, {assistant_msg, response.usage}, new_state}

      {:error, _error} ->
        {:ok, response} = summarize(state.context)
        summary = unpack({:ok, response})
        new_msgs = [user_message | [summary | [state.system_message]]]

        {:ok, response2} = Chat.create_chat_completion(new_msgs |> Enum.reverse(), model)
        assistant_msg2 = unpack({:ok, response2})

        new_state = %{
          state
          | context: [assistant_msg2 | [user_message | [summary]]],
            history: [assistant_msg2 | [user_message | state.history]],
            total_tokens_used:
              state.total_tokens_used + response.usage.total_tokens +
                response2.usage.total_tokens
        }

        {:reply, {assistant_msg2, response2.usage}, new_state}
    end
  end

  @doc """
  Summarizes the context of the bot server.
  Future versions will take a summarization prompt as an argument.
  """
  def summarize(context, model \\ "gpt-3.5-turbo") do
    msgs = [
      %{
        role: "user",
        content: "summarize the previous messages, and begin your messags with \"Summary:\""
      }
      | context
    ]

    Chat.create_chat_completion(msgs |> Enum.reverse(), model)
  end

  defp unpack({:ok, response}) do
    response.choices |> List.first() |> Map.get(:message)
  end
end
