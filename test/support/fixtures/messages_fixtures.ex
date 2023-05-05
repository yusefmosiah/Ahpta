defmodule Ahpta.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ahpta.Messages` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        message_type: "some message_type",
        conversation_id: Ecto.UUID.generate(),
        sender_id: Ecto.UUID.generate()
      })
      |> Ahpta.Messages.create_message()

    message
  end
end
