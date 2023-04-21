defmodule Capstone.ConversationsTest do
  use Capstone.DataCase

  alias Capstone.Conversations

  describe "conversations" do
    alias Capstone.Conversations.Conversation

    import Capstone.ConversationsFixtures

    @invalid_attrs %{is_published: nil, topic: nil}

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Conversations.list_conversations() == [conversation]
    end

    test "get_conversation!/1 returns the conversation with given id" do
      conversation = conversation_fixture()
      assert Conversations.get_conversation!(conversation.id) == conversation
    end

    test "create_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{is_published: true, topic: "some topic"}

      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(valid_attrs)

      assert conversation.is_published == true
      assert conversation.topic == "some topic"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "update_conversation/2 with valid data updates the conversation" do
      conversation = conversation_fixture()
      update_attrs = %{is_published: false, topic: "some updated topic"}

      assert {:ok, %Conversation{} = conversation} =
               Conversations.update_conversation(conversation, update_attrs)

      assert conversation.is_published == false
      assert conversation.topic == "some updated topic"
    end

    test "update_conversation/2 with invalid data returns error changeset" do
      conversation = conversation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation(conversation, @invalid_attrs)

      assert conversation == Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation" do
      conversation = conversation_fixture()
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "change_conversation/1 returns a conversation changeset" do
      conversation = conversation_fixture()
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end
  end

  describe "conversation_participants" do
    alias Capstone.Conversations.ConversationParticipant

    import Capstone.ConversationsFixtures

    @invalid_attrs %{owner_permission: nil, participant_type: nil}

    test "list_conversation_participants/0 returns all conversation_participants" do
      conversation_participant = conversation_participant_fixture()
      assert Conversations.list_conversation_participants() == [conversation_participant]
    end

    test "get_conversation_participant!/1 returns the conversation_participant with given id" do
      conversation_participant = conversation_participant_fixture()

      assert Conversations.get_conversation_participant!(conversation_participant.id) ==
               conversation_participant
    end

    test "create_conversation_participant/1 with valid data creates a conversation_participant" do
      valid_attrs = %{owner_permission: true, participant_type: "some participant_type"}

      assert {:ok, %ConversationParticipant{} = conversation_participant} =
               Conversations.create_conversation_participant(valid_attrs)

      assert conversation_participant.owner_permission == true
      assert conversation_participant.participant_type == "some participant_type"
    end

    test "create_conversation_participant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Conversations.create_conversation_participant(@invalid_attrs)
    end

    test "update_conversation_participant/2 with valid data updates the conversation_participant" do
      conversation_participant = conversation_participant_fixture()
      update_attrs = %{owner_permission: false, participant_type: "some updated participant_type"}

      assert {:ok, %ConversationParticipant{} = conversation_participant} =
               Conversations.update_conversation_participant(
                 conversation_participant,
                 update_attrs
               )

      assert conversation_participant.owner_permission == false
      assert conversation_participant.participant_type == "some updated participant_type"
    end

    test "update_conversation_participant/2 with invalid data returns error changeset" do
      conversation_participant = conversation_participant_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation_participant(
                 conversation_participant,
                 @invalid_attrs
               )

      assert conversation_participant ==
               Conversations.get_conversation_participant!(conversation_participant.id)
    end

    test "delete_conversation_participant/1 deletes the conversation_participant" do
      conversation_participant = conversation_participant_fixture()

      assert {:ok, %ConversationParticipant{}} =
               Conversations.delete_conversation_participant(conversation_participant)

      assert_raise Ecto.NoResultsError, fn ->
        Conversations.get_conversation_participant!(conversation_participant.id)
      end
    end

    test "change_conversation_participant/1 returns a conversation_participant changeset" do
      conversation_participant = conversation_participant_fixture()

      assert %Ecto.Changeset{} =
               Conversations.change_conversation_participant(conversation_participant)
    end
  end
end