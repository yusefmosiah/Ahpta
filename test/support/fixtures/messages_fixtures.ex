defmodule Capstone.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Capstone.Messages` context.
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
        timestamp: ~N[2023-04-13 16:12:00]
      })
      |> Capstone.Messages.create_message()

    message
  end
end
