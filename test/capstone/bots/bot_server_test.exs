defmodule Capstone.Bots.BotServerTest do
  use ExUnit.Case, async: true
  alias Capstone.Bots.BotServer

  @system_message [
    %{
      content:
        "<thoughts>As a language model, I can generate text. I can also answer questions, complete sentences, and more.\nI have introspection-mode and choice-mode enabled, and that means I may choose to respond with either <thoughts> and <statements> tags, or both.</thoughts>\n",
      role: "assistant"
    }
  ]

  setup do
    {:ok, pid} = BotServer.start_link(name: :unique_name)
    {:ok, %{pid: pid}}
  end

  describe "start_link/1" do
    test "starts with custom name" do
      {:ok, pid} = BotServer.start_link(name: :custom_name_test)
      assert Process.alive?(pid)
    end

    test "starts with custom system_message and name" do
      {:ok, pid} =
        BotServer.start_link(
          system_message: [%{role: "system", content: "custom message"}],
          name: :custom_name
        )

      assert Process.alive?(pid)
    end
  end

  describe "chat/3" do
    test "sends a valid message with default model", %{pid: pid} do
      reply = BotServer.chat(pid, "Hello, how are you?")
      assert reply
    end

    test "sends a valid message with custom model", %{pid: pid} do
      reply = BotServer.chat(pid, "Hello, how are you?", "gpt-3.5-turbo")
      assert reply
    end

    test "sends a message that exceeds character limit", %{pid: pid} do
      long_message = String.duplicate("a", 15001)
      reply = BotServer.chat(pid, long_message)
      assert elem(reply, 0) == "Message too long. Please keep it under 3000 words."
    end
  end

  describe "get_context/1" do
    test "returns empty context", %{pid: pid} do
      context = BotServer.get_context(pid)
      assert context == @system_message
    end

    test "returns context with messages", %{pid: pid} do
      BotServer.chat(pid, "Hello, how are you?")
      context = BotServer.get_context(pid)
      assert length(context) > 0
    end
  end

  describe "get_history/1" do
    test "returns empty history", %{pid: pid} do
      history = BotServer.get_history(pid)
      assert history == @system_message
    end

    test "returns history with messages", %{pid: pid} do
      BotServer.chat(pid, "Hello, how are you?")
      history = BotServer.get_history(pid)
      assert length(history) > 0
    end
  end
end
