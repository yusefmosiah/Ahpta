defmodule AhptaWeb.MessageLive.Index do
  use AhptaWeb, :live_view

  alias Ahpta.Messages
  alias Ahpta.Messages.Message

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: AhptaWeb.Endpoint.subscribe("messages")
    messages = Messages.list_messages()
    conversation_id = messages |> List.last() |> Map.get(:conversation_id)

    {:ok,
     socket
     |> stream(:messages, Messages.list_messages())
     |> assign(:conversation_id, conversation_id)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Message")
    |> assign(:message, Messages.get_message!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Message")
    |> assign(:message, %Message{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Messages")
    |> assign(:message, nil)
  end

  @impl true
  def handle_info({AhptaWeb.MessageLive.FormComponent, {:saved, message}}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  @impl true
  def handle_info(%{topic: "messages"} = message, socket) do
    {:noreply, stream_insert(socket, :messages, message.payload)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    message = Messages.get_message!(id)
    {:ok, _} = Messages.delete_message(message)

    {:noreply, stream_delete(socket, :messages, message)}
  end
end
