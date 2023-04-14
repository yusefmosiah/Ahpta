defmodule Capstone.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Capstone.Conversations` context.
  """

  @doc """
  Generate a conversation.
  """
  def conversation_fixture(attrs \\ %{}) do
    {:ok, conversation} =
      attrs
      |> Enum.into(%{
        is_published: true,
        topic: "some topic"
      })
      |> Capstone.Conversations.create_conversation()

    conversation
  end

  @doc """
  Generate a conversation_participant.
  """
  def conversation_participant_fixture(attrs \\ %{}) do
    {:ok, conversation_participant} =
      attrs
      |> Enum.into(%{
        owner_permission: true,
        participant_type: "some participant_type"
      })
      |> Capstone.Conversations.create_conversation_participant()

    conversation_participant
  end
end
