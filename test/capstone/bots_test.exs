defmodule Capstone.BotsTest do
  use Capstone.DataCase

  alias Capstone.Bots

  describe "bots" do
    alias Capstone.Bots.Bot

    import Capstone.BotsFixtures

    @invalid_attrs %{is_available_for_rent: nil, name: nil}

    test "list_bots/0 returns all bots" do
      bot = bot_fixture()
      assert Bots.list_bots() == [bot]
    end

    test "get_bot!/1 returns the bot with given id" do
      bot = bot_fixture()
      assert Bots.get_bot!(bot.id) == bot
    end

    test "create_bot/1 with valid data creates a bot" do
      valid_attrs = %{is_available_for_rent: true, name: "some name"}

      assert {:ok, %Bot{} = bot} = Bots.create_bot(valid_attrs)
      assert bot.is_available_for_rent == true
      assert bot.name == "some name"
    end

    test "create_bot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bots.create_bot(@invalid_attrs)
    end

    test "update_bot/2 with valid data updates the bot" do
      bot = bot_fixture()
      update_attrs = %{is_available_for_rent: false, name: "some updated name"}

      assert {:ok, %Bot{} = bot} = Bots.update_bot(bot, update_attrs)
      assert bot.is_available_for_rent == false
      assert bot.name == "some updated name"
    end

    test "update_bot/2 with invalid data returns error changeset" do
      bot = bot_fixture()
      assert {:error, %Ecto.Changeset{}} = Bots.update_bot(bot, @invalid_attrs)
      assert bot == Bots.get_bot!(bot.id)
    end

    test "delete_bot/1 deletes the bot" do
      bot = bot_fixture()
      assert {:ok, %Bot{}} = Bots.delete_bot(bot)
      assert_raise Ecto.NoResultsError, fn -> Bots.get_bot!(bot.id) end
    end

    test "change_bot/1 returns a bot changeset" do
      bot = bot_fixture()
      assert %Ecto.Changeset{} = Bots.change_bot(bot)
    end
  end
end
