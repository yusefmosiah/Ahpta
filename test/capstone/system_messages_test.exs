defmodule Capstone.SystemMessagesTest do
  use Capstone.DataCase

  alias Capstone.SystemMessages

  describe "system_messages" do
    alias Capstone.SystemMessages.SystemMessage

    import Capstone.SystemMessagesFixtures

    @invalid_attrs %{content: nil, timestamp: nil, version: nil}

    test "list_system_messages/0 returns all system_messages" do
      system_message = system_message_fixture()
      assert SystemMessages.list_system_messages() == [system_message]
    end

    test "get_system_message!/1 returns the system_message with given id" do
      system_message = system_message_fixture()
      assert SystemMessages.get_system_message!(system_message.id) == system_message
    end

    test "create_system_message/1 with valid data creates a system_message" do
      valid_attrs = %{content: "some content", timestamp: ~N[2023-04-13 16:12:00], version: 42}

      assert {:ok, %SystemMessage{} = system_message} =
               SystemMessages.create_system_message(valid_attrs)

      assert system_message.content == "some content"
      assert system_message.timestamp == ~N[2023-04-13 16:12:00]
      assert system_message.version == 42
    end

    test "create_system_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SystemMessages.create_system_message(@invalid_attrs)
    end

    test "update_system_message/2 with valid data updates the system_message" do
      system_message = system_message_fixture()

      update_attrs = %{
        content: "some updated content",
        timestamp: ~N[2023-04-14 16:12:00],
        version: 43
      }

      assert {:ok, %SystemMessage{} = system_message} =
               SystemMessages.update_system_message(system_message, update_attrs)

      assert system_message.content == "some updated content"
      assert system_message.timestamp == ~N[2023-04-14 16:12:00]
      assert system_message.version == 43
    end

    test "update_system_message/2 with invalid data returns error changeset" do
      system_message = system_message_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SystemMessages.update_system_message(system_message, @invalid_attrs)

      assert system_message == SystemMessages.get_system_message!(system_message.id)
    end

    test "delete_system_message/1 deletes the system_message" do
      system_message = system_message_fixture()
      assert {:ok, %SystemMessage{}} = SystemMessages.delete_system_message(system_message)

      assert_raise Ecto.NoResultsError, fn ->
        SystemMessages.get_system_message!(system_message.id)
      end
    end

    test "change_system_message/1 returns a system_message changeset" do
      system_message = system_message_fixture()
      assert %Ecto.Changeset{} = SystemMessages.change_system_message(system_message)
    end
  end
end
