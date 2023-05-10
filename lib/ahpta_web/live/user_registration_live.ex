defmodule AhptaWeb.UserRegistrationLive do
  use AhptaWeb, :live_view

  alias Ahpta.Accounts
  alias Ahpta.Accounts.User

  # def render(assigns) do
  #   ~H"""
  #   <div class="mx-auto max-w-sm">
  #     <.header class="text-center">
  #       Register for an account
  #       <:subtitle>
  #         Already registered?
  #         <.link navigate={~p"/users/log_in"} class="text-brand font-semibold hover:underline">
  #           Sign in
  #         </.link>
  #         to your account now.
  #       </:subtitle>
  #     </.header>

  #     <.simple_form
  #       for={@form}
  #       id="registration_form"
  #       phx-submit="save"
  #       phx-change="validate"
  #       phx-trigger-action={@trigger_submit}
  #       action={~p"/users/log_in?_action=registered"}
  #       method="post"
  #     >
  #       <.error :if={@check_errors}>
  #         Oops, something went wrong! Please check the errors below.
  #       </.error>

  #       <.input field={@form[:email]} type="email" label="Email" required />
  #       <.input field={@form[:password]} type="password" label="Password" required />

  #       <:actions>
  #         <.button
  #           phx-disable-with="Creating account..."
  #           class="font-mono w-full rounded-lg border-4 border-double border-green-400 bg-none p-4 text-green-500 hover:border-green-200 hover:bg-green-500 hover:text-white dark:border-green-400 dark:text-green-500 dark:hover:bg-green-700 dark:hover:text-white"
  #         >
  #           Create an account
  #         </.button>
  #       </:actions>
  #     </.simple_form>
  #   </div>
  #   """
  # end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-screen-xl px-4">
      <div class="mx-auto py-6 dark:bg-black">
        <div class="mb-10 flex items-center justify-between">
          <h1 class="mt-7 mb-6 text-5xl font-bold text-gray-900 dark:text-gray-100">
            Register for an account
          </h1>
        </div>

        <div class="rounded-lg bg-white bg-opacity-40 p-4 shadow-md backdrop-blur-md dark:border-2 dark:border-double dark:border-gray-700 dark:bg-gray-800 dark:bg-opacity-75 dark:text-white">
          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
          >
            <.error :if={@check_errors}>
              Oops, something went wrong! Please check the errors below.
            </.error>

            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <:actions>
              <.button
                phx-disable-with="Creating account..."
                class="font-mono w-full rounded-lg border-4 border-double border-green-400 bg-none p-4 text-green-500 hover:border-green-200 hover:bg-green-500 hover:text-white dark:border-green-400 dark:text-green-500 dark:hover:bg-green-700 dark:hover:text-white"
              >
                Create an account
              </.button>
            </:actions>
          </.simple_form>
        </div>

        <div class="mt-6 mb-10 flex items-center justify-center">
          <.link
            navigate={~p"/users/log_in"}
            class="text-brand font-semibold hover:underline dark:text-gray-100"
          >
            Already registered? Sign in
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
