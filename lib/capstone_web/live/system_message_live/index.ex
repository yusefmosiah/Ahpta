defmodule CapstoneWeb.SystemMessageLive.Index do
  use CapstoneWeb, :live_view

  alias Capstone.SystemMessages
  alias Capstone.SystemMessages.SystemMessage

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :system_messages, SystemMessages.list_system_messages())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit System message")
    |> assign(:system_message, SystemMessages.get_system_message!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New System message")
    |> assign(:system_message, %SystemMessage{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing System messages")
    |> assign(:system_message, nil)
  end

  @impl true
  def handle_info({CapstoneWeb.SystemMessageLive.FormComponent, {:saved, system_message}}, socket) do
    {:noreply, stream_insert(socket, :system_messages, system_message)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    system_message = SystemMessages.get_system_message!(id)
    {:ok, _} = SystemMessages.delete_system_message(system_message)

    {:noreply, stream_delete(socket, :system_messages, system_message)}
  end
end
