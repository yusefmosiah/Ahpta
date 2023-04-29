defmodule CapstoneWeb.BotLive.Index do
  use CapstoneWeb, :live_view

  alias Capstone.Bots
  alias Capstone.Bots.Bot
  alias Capstone.Conversations

  @impl true
  def mount(_params, _session, socket) do
    conversations = Conversations.list_conversations()

    bots =
      Bots.list_bots()
      |> IO.inspect(label: "bbbbbots")

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
  def handle_info({CapstoneWeb.BotLive.FormComponent, {:saved, bot}}, socket) do
    {:noreply, stream_insert(socket, :bots, bot)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bot = Bots.get_bot!(id)
    {:ok, _} = Bots.delete_bot(bot)

    {:noreply, stream_delete(socket, :bots, bot)}
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
    <.header>
      Listing Bots
      <:actions>
        <.link patch={~p"/bots/new"}>
          <.button>New Bot</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="bots"
      rows={@streams.bots}
      row_click={fn {_id, bot} -> JS.navigate(~p"/bots/#{bot}") end}
    >
      <:col :let={{_id, bot}} label="Name"><%= bot.name %></:col>
      <:col :let={{_id, bot}} label="Is available for rent"><%= bot.is_available_for_rent %></:col>
      <:col :let={{_id, bot}} label="System Message"><%= bot.system_message %></:col>
      <:action :let={{_id, bot}}>
        <div class="sr-only">
          <.link navigate={~p"/bots/#{bot}"}>Show</.link>
        </div>
        <.link patch={~p"/bots/#{bot}/edit"}>Edit</.link>
      </:action>

      <:action :let={{id, bot}}>
        <.link
          phx-click={JS.push("delete", value: %{id: bot.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="bot-modal" show on_cancel={JS.patch(~p"/bots")}>
      <.live_component
        module={CapstoneWeb.BotLive.FormComponent}
        id={@bot.id || :new}
        title={@page_title}
        action={@live_action}
        bot={@bot}
        patch={~p"/bots"}
      />
    </.modal>
    """
  end
end
