defmodule AhptaWeb.ConversationLive.FormComponent do
  use AhptaWeb, :live_component

  alias Ahpta.Conversations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage conversation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="conversation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:topic]} type="text" label="Topic" />
        <.input field={@form[:is_published]} type="checkbox" label="Is published" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Conversation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{conversation: conversation} = assigns, socket) do
    changeset = Conversations.change_conversation(conversation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"conversation" => conversation_params}, socket) do
    changeset =
      socket.assigns.conversation
      |> Conversations.change_conversation(conversation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"conversation" => conversation_params}, socket) do
    save_conversation(socket, socket.assigns.action, conversation_params)
  end

  defp save_conversation(socket, :edit, conversation_params) do
    case Conversations.update_conversation(socket.assigns.conversation, conversation_params) do
      {:ok, conversation} ->
        notify_parent({:saved, conversation})

        {:noreply,
         socket
         |> put_flash(:info, "Conversation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_conversation(socket, :new, conversation_params) do
    case Conversations.create_conversation(conversation_params) do
      {:ok, conversation} ->
        notify_parent({:saved, conversation})

        {:noreply,
         socket
         |> put_flash(:info, "Conversation created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
