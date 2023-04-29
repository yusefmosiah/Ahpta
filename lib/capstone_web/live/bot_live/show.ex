defmodule CapstoneWeb.BotLive.Show do
  use CapstoneWeb, :live_view

  alias Capstone.Bots

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:bot, Bots.get_bot!(id))
     |> assign(:subscribed_conversations, Bots.list_subscribed_conversations(id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
        <.header>
      Bot <%= @bot.id %>
      <:subtitle>This is a bot record from your database.</:subtitle>
      <:actions>
        <.link patch={~p"/bots/#{@bot}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit bot</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Name"><%= @bot.name %></:item>
      <:item title="Is available for rent"><%= @bot.is_available_for_rent %></:item>
      <:item title="System Message"><%= @bot.system_message %></:item>
      <:item title="Subscribed to topics"><%= @subscribed_conversations |> Enum.map(& &1 <> " | ") %></:item>

    </.list>

    <.back navigate={~p"/bots"}>Back to bots</.back>

    <.modal :if={@live_action == :edit} id="bot-modal" show on_cancel={JS.patch(~p"/bots/#{@bot}")}>
      <.live_component
        module={CapstoneWeb.BotLive.FormComponent}
        id={@bot.id}
        title={@page_title}
        action={@live_action}
        bot={@bot}
        patch={~p"/bots/#{@bot}"}
      />
    </.modal>
    """
  end

  defp page_title(:show), do: "Show Bot"
  defp page_title(:edit), do: "Edit Bot"
end
