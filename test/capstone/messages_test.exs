defmodule Ahpta.MessagesTest do
  use Ahpta.DataCase

  alias Ahpta.ConversationsFixtures
  alias Ahpta.Messages
  alias Ahpta.AccountsFixtures
  alias Ahpta.ConversationsFixtures

  describe "messages" do
    alias Ahpta.Messages.Message

    import Ahpta.MessagesFixtures

    @invalid_attrs %{content: nil, message_type: nil}

    test "list_messages/0 returns all messages" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      message = message_fixture(valid_attrs)
      assert Messages.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      message = message_fixture(valid_attrs) |> Repo.preload([:sender, :conversation])
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      assert {:ok, %Message{} = message} = Messages.create_message(valid_attrs)
      assert message.content == "some content"
      assert message.message_type == "some message_type"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      message = message_fixture(valid_attrs)

      update_attrs = %{
        content: "some updated content",
        message_type: "some updated message_type"
      }

      assert {:ok, %Message{} = message} = Messages.update_message(message, update_attrs)
      assert message.content == "some updated content"
      assert message.message_type == "some updated message_type"
    end

    test "update_message/2 with invalid data returns error changeset" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      message = message_fixture(valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)

      assert message |> Repo.preload([:sender, :conversation]) ==
               Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      message = message_fixture(valid_attrs)
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      user = AccountsFixtures.user_fixture()
      conversation = ConversationsFixtures.conversation_fixture()

      valid_attrs = %{
        content: "some content",
        message_type: "some message_type",
        conversation_id: conversation.id,
        sender_id: user.id
      }

      message = message_fixture(valid_attrs)
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end
  end
end
