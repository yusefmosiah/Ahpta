defmodule CapstoneWeb.ConversationParticipantLiveTest do
  use CapstoneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Capstone.ConversationsFixtures

  @create_attrs %{owner_permission: true, participant_type: "some participant_type"}
  @update_attrs %{owner_permission: false, participant_type: "some updated participant_type"}
  @invalid_attrs %{owner_permission: false, participant_type: nil}

  defp create_conversation_participant(_) do
    conversation_participant = conversation_participant_fixture()
    %{conversation_participant: conversation_participant}
  end

  describe "Index" do
    setup [:create_conversation_participant]

    test "lists all conversation_participants", %{
      conn: conn,
      conversation_participant: conversation_participant
    } do
      {:ok, _index_live, html} = live(conn, ~p"/conversation_participants")

      assert html =~ "Listing Conversation participants"
      assert html =~ conversation_participant.participant_type
    end

    test "saves new conversation_participant", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/conversation_participants")

      assert index_live |> element("a", "New Conversation participant") |> render_click() =~
               "New Conversation participant"

      assert_patch(index_live, ~p"/conversation_participants/new")

      assert index_live
             |> form("#conversation_participant-form", conversation_participant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#conversation_participant-form", conversation_participant: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/conversation_participants")

      html = render(index_live)
      assert html =~ "Conversation participant created successfully"
      assert html =~ "some participant_type"
    end

    test "updates conversation_participant in listing", %{
      conn: conn,
      conversation_participant: conversation_participant
    } do
      {:ok, index_live, _html} = live(conn, ~p"/conversation_participants")

      assert index_live
             |> element("#conversation_participants-#{conversation_participant.id} a", "Edit")
             |> render_click() =~
               "Edit Conversation participant"

      assert_patch(index_live, ~p"/conversation_participants/#{conversation_participant}/edit")

      assert index_live
             |> form("#conversation_participant-form", conversation_participant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#conversation_participant-form", conversation_participant: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/conversation_participants")

      html = render(index_live)
      assert html =~ "Conversation participant updated successfully"
      assert html =~ "some updated participant_type"
    end

    test "deletes conversation_participant in listing", %{
      conn: conn,
      conversation_participant: conversation_participant
    } do
      {:ok, index_live, _html} = live(conn, ~p"/conversation_participants")

      assert index_live
             |> element("#conversation_participants-#{conversation_participant.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#conversation_participants-#{conversation_participant.id}")
    end
  end

  describe "Show" do
    setup [:create_conversation_participant]

    test "displays conversation_participant", %{
      conn: conn,
      conversation_participant: conversation_participant
    } do
      {:ok, _show_live, html} =
        live(conn, ~p"/conversation_participants/#{conversation_participant}")

      assert html =~ "Show Conversation participant"
      assert html =~ conversation_participant.participant_type
    end

    test "updates conversation_participant within modal", %{
      conn: conn,
      conversation_participant: conversation_participant
    } do
      {:ok, show_live, _html} =
        live(conn, ~p"/conversation_participants/#{conversation_participant}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Conversation participant"

      assert_patch(
        show_live,
        ~p"/conversation_participants/#{conversation_participant}/show/edit"
      )

      assert show_live
             |> form("#conversation_participant-form", conversation_participant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#conversation_participant-form", conversation_participant: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/conversation_participants/#{conversation_participant}")

      html = render(show_live)
      assert html =~ "Conversation participant updated successfully"
      assert html =~ "some updated participant_type"
    end
  end
end
