defmodule AhptaWeb.Components.MessageListComponent do
  use Phoenix.Component

  def message_list(assigns) do
    ~H"""
    <div
      id="messages_list_scrolling_container"
      class="message-container overflow-y-scroll"
      phx-hook="ScrollDown"
    >
      <ul id="message-list" phx-update="replace" class="space-y-4">
        <md-block :for={message <- @messages} class="mt-5 mb-5 block" id={Ecto.UUID.generate()}>
          <li
            id={message.id}
            class="transform rounded-lg bg-white bg-opacity-40 p-4 shadow-lg backdrop-blur-md transition-all hover:-translate-y-1 dark:border-2 dark:border-double dark:border-gray-700 dark:bg-black dark:bg-opacity-50"
          >
            <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300">
              <%= message.content %>
            </p>
          </li>
        </md-block>

        <md-block
          :for={{id, message} <- @ongoing_messages}
          }
          class="mt-5 mb-5 block"
          id={Ecto.UUID.generate()}
        >
          <li
            id={id}
            class="transform rounded-lg bg-white bg-opacity-40 p-4 shadow-lg backdrop-blur-md transition-all hover:-translate-y-1 dark:border-2 dark:border-double dark:border-gray-700 dark:bg-black dark:bg-opacity-50"
          >
            <p class="whitespace-pre-wrap text-gray-900 dark:text-gray-300"><%= message %></p>
          </li>
        </md-block>
      </ul>
    </div>
    """
  end
end
