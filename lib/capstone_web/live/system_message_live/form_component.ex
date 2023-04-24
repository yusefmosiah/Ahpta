defmodule CapstoneWeb.SystemMessageLive.FormComponent do
  use CapstoneWeb, :live_component

  alias Capstone.SystemMessages

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage system_message records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="system_message-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:content]} type="text" label="Content" />
        <.input field={@form[:version]} type="number" label="Version" />
        <:actions>
          <.button phx-disable-with="Saving...">Save System message</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{system_message: system_message} = assigns, socket) do
    changeset = SystemMessages.change_system_message(system_message)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"system_message" => system_message_params}, socket) do
    changeset =
      socket.assigns.system_message
      |> SystemMessages.change_system_message(system_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"system_message" => system_message_params}, socket) do
    save_system_message(socket, socket.assigns.action, system_message_params)
  end

  defp save_system_message(socket, :edit, system_message_params) do
    case SystemMessages.update_system_message(
           socket.assigns.system_message,
           system_message_params
         ) do
      {:ok, system_message} ->
        notify_parent({:saved, system_message})

        {:noreply,
         socket
         |> put_flash(:info, "System message updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_system_message(socket, :new, system_message_params) do
    case SystemMessages.create_system_message(system_message_params) do
      {:ok, system_message} ->
        notify_parent({:saved, system_message})

        {:noreply,
         socket
         |> put_flash(:info, "System message created successfully")
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
