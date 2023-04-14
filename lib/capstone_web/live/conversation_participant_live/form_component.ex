defmodule CapstoneWeb.ConversationParticipantLive.FormComponent do
  use CapstoneWeb, :live_component

  alias Capstone.Conversations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          Use this form to manage conversation_participant records in your database.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="conversation_participant-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:participant_type]} type="text" label="Participant type" />
        <.input field={@form[:owner_permission]} type="checkbox" label="Owner permission" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Conversation participant</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{conversation_participant: conversation_participant} = assigns, socket) do
    changeset = Conversations.change_conversation_participant(conversation_participant)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"conversation_participant" => conversation_participant_params},
        socket
      ) do
    changeset =
      socket.assigns.conversation_participant
      |> Conversations.change_conversation_participant(conversation_participant_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event(
        "save",
        %{"conversation_participant" => conversation_participant_params},
        socket
      ) do
    save_conversation_participant(socket, socket.assigns.action, conversation_participant_params)
  end

  defp save_conversation_participant(socket, :edit, conversation_participant_params) do
    case Conversations.update_conversation_participant(
           socket.assigns.conversation_participant,
           conversation_participant_params
         ) do
      {:ok, conversation_participant} ->
        notify_parent({:saved, conversation_participant})

        {:noreply,
         socket
         |> put_flash(:info, "Conversation participant updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_conversation_participant(socket, :new, conversation_participant_params) do
    case Conversations.create_conversation_participant(conversation_participant_params) do
      {:ok, conversation_participant} ->
        notify_parent({:saved, conversation_participant})

        {:noreply,
         socket
         |> put_flash(:info, "Conversation participant created successfully")
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
