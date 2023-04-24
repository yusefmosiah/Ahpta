defmodule Capstone.SystemMessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Capstone.SystemMessages` context.
  """

  @doc """
  Generate a system_message.
  """
  def system_message_fixture(attrs \\ %{}) do
    {:ok, system_message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        version: 42
      })
      |> Capstone.SystemMessages.create_system_message()

    system_message
  end
end
