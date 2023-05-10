defmodule AhptaWeb.UserLoginLive do
  use AhptaWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-screen-xl px-4">
      <div class="mx-auto py-6 dark:bg-black">
        <div class="mb-10 flex items-center justify-between">
          <h1 class="mt-7 mb-6 text-5xl font-bold text-gray-900 dark:text-gray-100">Sign in</h1>
        </div>

        <div class="rounded-lg bg-white bg-opacity-40 p-4 shadow-md backdrop-blur-md dark:border-2 dark:border-double dark:border-gray-700 dark:bg-gray-800 dark:bg-opacity-75 dark:text-white">
          <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <div class="flex items-center justify-between">
              <div class="space-x-2">
                <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
                <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
                  Forgot your password?
                </.link>
              </div>
              <div class="space-x-2">
                <.button
                  phx-disable-with="Signing in..."
                  class="font-mono rounded-lg border-4 border-double border-green-400 bg-none p-4 text-green-500 hover:border-green-200 hover:bg-green-500 hover:text-white dark:border-green-400 dark:text-green-500 dark:hover:bg-green-700 dark:hover:text-white"
                >
                  Sign in
                </.button>
              </div>
            </div>
          </.simple_form>

          <div class="mt-6 mb-10 flex items-center justify-center">
            <.link navigate={~p"/users/register"} class="text-brand font-semibold hover:underline">
              Don't have an account? Sign up
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
