defmodule CapstoneWeb.SystemMessageLiveTest do
  use CapstoneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Capstone.SystemMessagesFixtures

  @create_attrs %{content: "some content", timestamp: "2023-04-13T16:12:00", version: 42}
  @update_attrs %{content: "some updated content", timestamp: "2023-04-14T16:12:00", version: 43}
  @invalid_attrs %{content: nil, timestamp: nil, version: nil}

  defp create_system_message(_) do
    system_message = system_message_fixture()
    %{system_message: system_message}
  end

  describe "Index" do
    setup [:create_system_message]

    test "lists all system_messages", %{conn: conn, system_message: system_message} do
      {:ok, _index_live, html} = live(conn, ~p"/system_messages")

      assert html =~ "Listing System messages"
      assert html =~ system_message.content
    end

    test "saves new system_message", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/system_messages")

      assert index_live |> element("a", "New System message") |> render_click() =~
               "New System message"

      assert_patch(index_live, ~p"/system_messages/new")

      assert index_live
             |> form("#system_message-form", system_message: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#system_message-form", system_message: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/system_messages")

      html = render(index_live)
      assert html =~ "System message created successfully"
      assert html =~ "some content"
    end

    test "updates system_message in listing", %{conn: conn, system_message: system_message} do
      {:ok, index_live, _html} = live(conn, ~p"/system_messages")

      assert index_live
             |> element("#system_messages-#{system_message.id} a", "Edit")
             |> render_click() =~
               "Edit System message"

      assert_patch(index_live, ~p"/system_messages/#{system_message}/edit")

      assert index_live
             |> form("#system_message-form", system_message: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#system_message-form", system_message: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/system_messages")

      html = render(index_live)
      assert html =~ "System message updated successfully"
      assert html =~ "some updated content"
    end

    test "deletes system_message in listing", %{conn: conn, system_message: system_message} do
      {:ok, index_live, _html} = live(conn, ~p"/system_messages")

      assert index_live
             |> element("#system_messages-#{system_message.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#system_messages-#{system_message.id}")
    end
  end

  describe "Show" do
    setup [:create_system_message]

    test "displays system_message", %{conn: conn, system_message: system_message} do
      {:ok, _show_live, html} = live(conn, ~p"/system_messages/#{system_message}")

      assert html =~ "Show System message"
      assert html =~ system_message.content
    end

    test "updates system_message within modal", %{conn: conn, system_message: system_message} do
      {:ok, show_live, _html} = live(conn, ~p"/system_messages/#{system_message}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit System message"

      assert_patch(show_live, ~p"/system_messages/#{system_message}/show/edit")

      assert show_live
             |> form("#system_message-form", system_message: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#system_message-form", system_message: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/system_messages/#{system_message}")

      html = render(show_live)
      assert html =~ "System message updated successfully"
      assert html =~ "some updated content"
    end
  end
end
