# defmodule Capstone.Bots.BotServerTest do
#   use ExUnit.Case, async: true
#   alias Capstone.Bots.BotServer
#   alias Phoenix.PubSub

#   @system_messages [
#     %{
#       content:
#         "<thoughts>As a language model, I can generate text. I can also answer questions, complete sentences, and more.\nI have introspection-mode and choice-mode enabled, and that means I may choose to respond with either <thoughts> and <statements> tags, or both.</thoughts>\n",
#       role: "assistant"
#     }
#   ]

#   @valid_attrs %{topic: "test topic"}
#   setup tags do
#     :ok = Ecto.Adapters.SQL.Sandbox.checkout(Capstone.Repo)

#     unless tags[:async] do
#       Ecto.Adapters.SQL.Sandbox.mode(Capstone.Repo, {:shared, self()})
#     end

#     {:ok, pid} = Capstone.Bots.BotServerSupervisor.start_bot_server(name: :unique_name)

#     conversation_id = Ecto.UUID.generate()
#     attrs = Map.merge(@valid_attrs, %{conversation_id: conversation_id})
#     {:ok, _conversation} = Capstone.Conversations.create_conversation(attrs)

#     BotServer.join_conversation(pid, conversation_id)

#     on_exit(fn ->
#       Capstone.Bots.BotServerSupervisor.stop_bot_server(pid)
#     end)

#     {:ok, %{pid: pid, conversation_id: conversation_id}}
#   end

#   describe "start_link/1" do
#     test "starts with custom name" do
#       {:ok, pid} = BotServer.start_link(name: :custom_name_test)
#       assert Process.alive?(pid)
#     end

#     test "starts with custom system_messages and name" do
#       {:ok, pid} =
#         BotServer.start_link(
#           system_messagess: [%{role: "system", content: "custom message"}],
#           name: :custom_name
#         )

#       assert Process.alive?(pid)
#     end
#   end

#   describe "join_conversation/1" do
#     test "joins conversation successfully", %{pid: pid} do
#       new_conversation_id = Ecto.UUID.generate()
#       assert :ok == BotServer.join_conversation(pid, new_conversation_id)
#     end
#   end

#   describe "get_context/1" do
#     test "returns empty context", %{pid: pid, conversation_id: conversation_id} do
#       context = BotServer.get_context(pid, conversation_id)
#       assert context == @system_messages
#     end
#   end

#   describe "get_history/1" do
#     test "returns empty history", %{pid: pid, conversation_id: conversation_id} do
#       history = BotServer.get_history(pid, conversation_id)
#       assert history == @system_messages
#     end
#   end

#   describe "chat/3" do
#     test "sends a message and receives a response", %{pid: pid, conversation_id: conversation_id} do
#       message = "Hello, bot!"
#       model = "test_model"

#       topic = "convo:#{conversation_id}"
#       PubSub.subscribe(Capstone.PubSub, topic)

#       BotServer.chat(pid, conversation_id, message, model)

#       assert_receive %{"bot_id" => %{role: "assistant", content: _}}, 5000

#       assert BotServer.get_context(pid, conversation_id) == [
#                %{content: "This is a mock response.", role: "assistant"},
#                %{content: "Hello, bot!", role: "user"},
#                %{
#                  content:
#                    "<thoughts>As a language model, I can generate text. I can also answer questions, complete sentences, and more.\nI have introspection-mode and choice-mode enabled, and that means I may choose to respond with either <thoughts> and <statements> tags, or both.</thoughts>\n",
#                  role: "assistant"
#                }
#              ]
#     end
#   end
# end
