defmodule AhptaWeb.BotLive.FormComponent do
  use AhptaWeb, :live_component

  alias Ahpta.Bots

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <p class="text-white">Use this form to manage bot records in your database.</p>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="bot-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:system_message]} type="textarea" label="System Message" />
        <.input field={@form[:is_available_for_rent]} type="checkbox" label="Is available for rent" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Bot</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{bot: bot} = assigns, socket) do
    changeset = Bots.change_bot(bot)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"bot" => bot_params}, socket) do
    changeset =
      socket.assigns.bot
      |> Bots.change_bot(bot_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"bot" => bot_params}, socket) do
    save_bot(socket, socket.assigns.action, bot_params)
  end

  defp save_bot(socket, :edit, bot_params) do
    case Bots.update_bot(socket.assigns.bot, bot_params) do
      {:ok, bot} ->
        notify_parent({:saved, bot})

        {:noreply,
         socket
         |> put_flash(:info, "Bot updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_bot(socket, :new, bot_params) do
    case Bots.create_bot(bot_params) do
      {:ok, bot} ->
        notify_parent({:saved, bot})

        {:noreply,
         socket
         |> put_flash(:info, "Bot created successfully")
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
