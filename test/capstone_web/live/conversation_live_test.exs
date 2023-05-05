defmodule CapstoneWeb.ConversationLiveTest do
  use CapstoneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Capstone.ConversationsFixtures

  @create_attrs %{is_published: true, topic: "some topic"}
  @update_attrs %{is_published: false, topic: "some updated topic"}
  @invalid_attrs %{is_published: false, topic: nil}

  defp create_conversation(_) do
    conversation = conversation_fixture()
    %{conversation: conversation}
  end

  describe "Index" do
    setup [:create_conversation]

    test "lists all conversations", %{conn: conn, conversation: conversation} do
      {:ok, _index_live, html} = live(conn, ~p"/conversations")

      assert html =~ "Listing Conversations"
      assert html =~ conversation.topic
    end

    test "saves new conversation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/conversations")

      assert index_live |> element("a", "New Conversation") |> render_click() =~
               "New Conversation"

      assert_patch(index_live, ~p"/conversations/new")

      assert index_live
             |> form("#conversation-form", conversation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#conversation-form", conversation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/conversations")

      html = render(index_live)
      assert html =~ "Conversation created successfully"
      assert html =~ "some topic"
    end

    test "updates conversation in listing", %{conn: conn, conversation: conversation} do
      {:ok, index_live, _html} = live(conn, ~p"/conversations")

      assert index_live
             |> element("a#edit-conversation-link-#{conversation.id}")
             |> render_click() =~ "Edit Conversation"

      assert_patch(index_live, ~p"/conversations/#{conversation}/edit")

      assert index_live
             |> form("#conversation-form", conversation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#conversation-form", conversation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/conversations")

      html = render(index_live)
      assert html =~ "Conversation updated successfully"
      assert html =~ "some updated topic"
    end

    test "deletes conversation in listing", %{conn: conn, conversation: conversation} do
      {:ok, index_live, _html} = live(conn, ~p"/conversations")

      assert index_live
             |> element("a#delete-conversation-link-#{conversation.id}")
             |> render_click()

      refute has_element?(index_live, "[data-conversation-id='#{conversation.id}']")
    end
  end

  describe "Show" do
    setup [:create_conversation]

    test "displays conversation", %{conn: conn, conversation: conversation} do
      {:ok, _show_live, html} = live(conn, ~p"/conversations/#{conversation}")

      assert html =~ "Show Conversation"
      assert html =~ conversation.topic
    end

    test "updates conversation within modal", %{conn: conn, conversation: conversation} do
      {:ok, show_live, _html} = live(conn, ~p"/conversations/#{conversation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Conversation"

      assert_patch(show_live, ~p"/conversations/#{conversation}/show/edit")

      assert show_live
             |> form("#conversation-form", conversation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#conversation-form", conversation: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/conversations/#{conversation}")

      html = render(show_live)

      assert html =~ "Conversation updated successfully"
      assert html =~ "some updated topic"
    end
  end
end
