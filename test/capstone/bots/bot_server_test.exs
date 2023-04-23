defmodule Capstone.Bots.BotServerTest do
  use ExUnit.Case, async: true
  alias Capstone.Bots.BotServer

  # @system_messages [
  #   %{
  #     content:
  #       "<thoughts>As a language model, I can generate text. I can also answer questions, complete sentences, and more.\nI have introspection-mode and choice-mode enabled, and that means I may choose to respond with either <thoughts> and <statements> tags, or both.</thoughts>\n",
  #     role: "assistant"
  #   }
  # ]

  setup do
    {:ok, pid} = BotServer.start_link(name: :unique_name)
    {:ok, %{pid: pid}}
  end

  describe "start_link/1" do
    test "starts with custom name" do
      {:ok, pid} = BotServer.start_link(name: :custom_name_test)
      assert Process.alive?(pid)
    end

    test "starts with custom system_messages and name" do
      {:ok, pid} =
        BotServer.start_link(
          system_messagess: [%{role: "system", content: "custom message"}],
          name: :custom_name
        )

      assert Process.alive?(pid)
    end
  end

  #chat tests after refactoring to use pubsub, pass in conversation_id, and parameterize the api calling module

  # describe "chat/3" do



  # end

  #refactor with a conversation_id

  # describe "get_context/1" do
  #   test "returns empty context", %{pid: pid} do
  #     context = BotServer.get_context(pid)
  #     assert context == @system_messages
  #   end


  # end

  # describe "get_history/1" do

    # refactor wtih a conversation_id

    # test "returns empty history", %{pid: pid} do
    #   history = BotServer.get_history(pid)
    #   assert history == @system_messages
    # end


  # end
end
