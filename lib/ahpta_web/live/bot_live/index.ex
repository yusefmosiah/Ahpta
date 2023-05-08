defmodule AhptaWeb.BotLive.Index do
  use AhptaWeb, :live_view

  alias Ahpta.Bots
  alias Ahpta.Bots.Bot
  alias Ahpta.Conversations

  @impl true
  def mount(_params, _session, socket) do
    conversations = Conversations.list_conversations()

    bots = Bots.list_bots()

    {:ok, stream(socket, :bots, bots) |> assign(:conversations, conversations)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Bot")
    |> assign(:bot, Bots.get_bot!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Bot")
    |> assign(:bot, %Bot{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Bots")
    |> assign(:bot, nil)
  end

  @impl true
  def handle_info({AhptaWeb.BotLive.FormComponent, {:saved, bot}}, socket) do
    {:noreply, stream_insert(socket, :bots, bot)}
  end

  # fixme: use push_navigate to reload page to workaround bug where bots (and convos) disappear after creation/editing/deleting
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bot = Bots.get_bot!(id)
    {:ok, _} = Bots.delete_bot(bot)

    {:noreply,
     stream_delete(socket, :bots, bot)
     |> put_flash(:info, "Bot deleted")}
  end

  @impl true
  def handle_event(
        "subscribe",
        %{"bot_id" => bot_id, "conversation_id" => conversation_id},
        socket
      ) do
    bot = Bots.get_bot!(bot_id)
    conversation = Conversations.get_conversation!(conversation_id)

    case Bots.subscribe_to_conversation(bot, conversation) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, :already_subscribed} ->
        {:noreply, socket |> put_flash(:error, "Bot is already subscribed to this conversation.")}
    end
  end

  @impl true
  def handle_event(
        "unsubscribe",
        %{"bot_id" => bot_id, "conversation_id" => conversation_id},
        socket
      ) do
    bot = Bots.get_bot!(bot_id)
    conversation = Conversations.get_conversation!(conversation_id)

    case Bots.unsubscribe_from_conversation(bot, conversation) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, :not_subscribed} ->
        {:noreply, socket |> put_flash(:error, "Bot is not subscribed to this conversation.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-screen-xl px-4">
      <div class="mx-auto px-4 py-6 dark:bg-black">
        <div class="mb-10 flex items-center justify-between">
          <h1 class="mt-7 mb-6 text-5xl font-bold text-gray-900 dark:text-gray-100">Bots</h1>
          <span class="space-x-2">
            <.link
              patch={~p"/bots/new"}
              class="font-mono rounded-lg border-4 border-double border-green-400 bg-none p-4 text-green-500 hover:border-green-200 hover:bg-green-500 hover:text-white dark:border-green-400 dark:text-green-500 dark:hover:bg-green-700 dark:hover:text-white"
            >
              New Bot
            </.link>
          </span>
        </div>

        <div class="space-y-4">
          <%= for {id, bot} <- @streams.bots do %>
            <div
              class="rounded-lg bg-white bg-opacity-40 p-4 shadow-md backdrop-blur-md dark:border-2 dark:border-double dark:border-gray-700 dark:bg-gray-800 dark:bg-opacity-75 dark:text-white"
              data-bot-id={bot.id}
            >
              <.link navigate={~p"/bots/#{bot}"} class="block">
                <h2 class="mb-2 text-2xl font-bold">
                  <%= bot.name %>
                </h2>
                <p>
                  Is available for rent: <%= bot.is_available_for_rent %>
                </p>
                <p>
                  System Message: <%= bot.system_message %>
                </p>
              </.link>
              <div class="mt-4 flex space-x-4">
                <.link
                  patch={~p"/bots/#{bot}/edit"}
                  class="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
                >
                  Edit
                </.link>
                <.link
                  phx-click={JS.push("delete", value: %{id: bot.id}) |> hide("##{id}")}
                  data-confirm="Are you sure?"
                  class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300"
                >
                  Delete
                </.link>
              </div>
            </div>
          <% end %>
        </div>

        <div class="mt-6 mb-10 flex items-center justify-between">
          <.link
            navigate={~p"/conversations"}
            class="font-mono inline-block rounded-lg border-4 border-double border-gray-500 p-4 text-gray-500 hover:border-white hover:bg-gray-500 hover:text-white dark:border-gray-400 dark:text-gray-400 dark:hover:border-gray-300 dark:hover:bg-gray-700 dark:hover:text-white"
          >
            Convos
          </.link>
          <.link
            navigate={~p"/bots"}
            class="font-mono inline-block rounded-lg border-4 border-double border-gray-500 p-4 text-gray-500 hover:border-white hover:bg-gray-500 hover:text-white dark:border-gray-400 dark:text-gray-400 dark:hover:border-gray-300 dark:hover:bg-gray-700 dark:hover:text-white"
          >
            Bots
          </.link>
        </div>

        <.dark_modal
          :if={@live_action in [:new, :edit]}
          id="bot-modal"
          show
          on_cancel={JS.patch(~p"/bots")}
        >
          <.live_component
            module={AhptaWeb.BotLive.FormComponent}
            id={@bot.id || :new}
            title={@page_title}
            action={@live_action}
            bot={@bot}
            patch={~p"/bots"}
          />
        </.dark_modal>
      </div>
    </div>
    """
  end
end
