defmodule Capstone.BotsTest do
  use Capstone.DataCase
  import Capstone.BotsFixtures
  import Capstone.ConversationsFixtures
  alias Capstone.Bots
  alias Capstone.Conversations

  setup do
    bot = bot_fixture()
    conversation = conversation_fixture()
    {:ok, bot: bot, conversation: conversation}
  end

  describe "bots" do
    alias Capstone.Bots.Bot

    @invalid_attrs %{is_available_for_rent: nil, name: nil}

    test "list_bots/0 returns all bots", %{bot: bot} do
      assert Bots.list_bots() == [bot]
    end

    test "get_bot!/1 returns the bot with given id", %{bot: bot} do
      assert Bots.get_bot!(bot.id) == bot
    end

    test "create_bot/1 with valid data creates a bot" do
      valid_attrs = %{is_available_for_rent: true, name: "different name"}

      assert {:ok, %Bot{} = bot} = Bots.create_bot(valid_attrs)
      assert bot.is_available_for_rent == true
      assert bot.name == "different name"
    end

    test "create_bot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bots.create_bot(@invalid_attrs)
    end

    test "update_bot/2 with valid data updates the bot", %{bot: bot} do
      update_attrs = %{is_available_for_rent: false, name: "some updated name"}

      assert {:ok, %Bot{} = bot} = Bots.update_bot(bot, update_attrs)
      assert bot.is_available_for_rent == false
      assert bot.name == "some updated name"
    end

    test "update_bot/2 with invalid data returns error changeset", %{bot: bot} do
      assert {:error, %Ecto.Changeset{}} = Bots.update_bot(bot, @invalid_attrs)
      assert bot == Bots.get_bot!(bot.id)
    end

    test "delete_bot/1 deletes the bot", %{bot: bot} do
      assert {:ok, %Bot{}} = Bots.delete_bot(bot)
      assert_raise Ecto.NoResultsError, fn -> Bots.get_bot!(bot.id) end
    end

    test "change_bot/1 returns a bot changeset", %{bot: bot} do
      assert %Ecto.Changeset{} = Bots.change_bot(bot)
    end
  end

  describe "bots subscribing to conversations" do
    alias Capstone.Bots.Bot
    alias Capstone.Conversations.ConversationParticipant

    test "subscribe_to_conversation/2 with valid data subscribes the bot to the conversation",
         %{bot: bot, conversation: conversation} do
      assert {:ok, %ConversationParticipant{} = cp} =
               Bots.subscribe_to_conversation(bot, conversation)

      assert cp.bot_id == bot.id
      assert cp.conversation_id == conversation.id
    end

    test "subscribe_to_conversation/2 with an already subscribed bot returns error", %{
      bot: bot,
      conversation: conversation
    } do
      assert {:ok, %ConversationParticipant{} = _cp} =
               Bots.subscribe_to_conversation(bot, conversation)

      assert {:error, :already_subscribed} = Bots.subscribe_to_conversation(bot, conversation)
    end

    test "unsubscribe_from_conversation/2 unsubscribes the bot from the conversation", %{
      bot: bot,
      conversation: conversation
    } do
      assert {:ok, %ConversationParticipant{} = cp} =
               Bots.subscribe_to_conversation(bot, conversation)

      assert {:ok, %ConversationParticipant{}} =
               Bots.unsubscribe_from_conversation(bot, conversation)

      assert_raise Ecto.NoResultsError, fn ->
        Conversations.get_conversation_participant!(cp.id)
      end
    end

    test "unsubscribe_from_conversation/2 with a not subscribed bot returns error", %{
      bot: bot,
      conversation: conversation
    } do
      assert {:error, :not_subscribed} = Bots.unsubscribe_from_conversation(bot, conversation)
    end

    test "list_subscribed_conversations/1 returns all conversations the bot is subscribed to", %{
      bot: bot,
      conversation: conversation
    } do
      assert [] == Bots.list_subscribed_conversations(bot.id)

      assert {:ok, %ConversationParticipant{} = _cp} =
               Bots.subscribe_to_conversation(bot, conversation)

      assert [conversation.id] == Bots.list_subscribed_conversations(bot.id)
    end
  end
end
