defmodule CapstoneWeb.ConversationLive.Index do
  use CapstoneWeb, :live_view

  alias Capstone.Conversations
  alias Capstone.Conversations.Conversation

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :conversations, Conversations.list_conversations())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Conversation")
    |> assign(:conversation, Conversations.get_conversation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Conversation")
    |> assign(:conversation, %Conversation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, nil)
  end

  @impl true
  def handle_info({CapstoneWeb.ConversationLive.FormComponent, {:saved, conversation}}, socket) do
    {:noreply, stream_insert(socket, :conversations, conversation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    conversation = Conversations.get_conversation!(id)
    {:ok, _} = Conversations.delete_conversation(conversation)

    {:noreply, stream_delete(socket, :conversations, conversation)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-screen-xl px-4">
      <div class="mx-auto px-4 py-6 dark:bg-black">
        <div class="mb-10 flex items-center justify-between">
          <h1 class="mt-7 mb-6 text-5xl font-bold text-gray-900 dark:text-gray-100">Conversations</h1>
          <span class="space-x-2">
            <.link
              patch={~p"/conversations/new"}
              class="font-mono rounded-lg border-4 border-double border-green-400 bg-none p-4 text-green-500 hover:border-green-200 hover:bg-green-500 hover:text-white dark:border-green-400 dark:text-green-500 dark:hover:bg-green-700 dark:hover:text-white"
            >
              New Conversation
            </.link>
          </span>
        </div>

        <div class="space-y-4">
          <%= for {id, conversation} <- @streams.conversations do %>
            <.link navigate={~p"/conversations/#{conversation}"} class="block">
              <div class="rounded-lg bg-white bg-opacity-40 p-4 shadow-md backdrop-blur-md dark:border-2 dark:border-double dark:border-gray-700 dark:bg-gray-800 dark:bg-opacity-75 dark:text-white">
                <h2 class="mb-2 text-2xl font-bold">
                  <%= conversation.topic %>
                </h2>
                <p class="font-narrow text-gray-400">
                  Is published: <%= conversation.is_published %>
                </p>
                <div class="mt-4 flex space-x-4">
                  <.link
                    patch={~p"/conversations/#{conversation}/edit"}
                    class="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
                  >
                    Edit
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: conversation.id}) |> hide("##{id}")}
                    data-confirm="Are you sure?"
                    class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300"
                  >
                    Delete
                  </.link>
                </div>
              </div>
            </.link>
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

        <.modal
          :if={@live_action in [:new, :edit]}
          id="conversation-modal"
          show
          on_cancel={JS.patch(~p"/conversations")}
        >
          <.live_component
            module={CapstoneWeb.ConversationLive.FormComponent}
            id={@conversation.id || :new}
            title={@page_title}
            action={@live_action}
            conversation={@conversation}
            patch={~p"/conversations"}
          />
        </.modal>
      </div>
    </div>
    """
  end
end
