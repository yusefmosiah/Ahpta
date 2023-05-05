defmodule CapstoneWeb.BotLiveTest do
  use CapstoneWeb.ConnCase

  import Phoenix.LiveViewTest
  import Capstone.BotsFixtures

  @update_attrs %{is_available_for_rent: false, name: "some updated name"}
  @invalid_attrs %{is_available_for_rent: false, name: nil}

  defp create_bot(_) do
    bot = bot_fixture()

    {:ok, bot: bot}
  end

  describe "Index" do
    setup [:create_bot]

    test "lists all bots", %{conn: conn, bot: bot} do
      {:ok, _index_live, html} = live(conn, ~p"/bots")

      assert html =~ "Listing Bots"
      assert html =~ bot.name
    end

    test "saves new bot", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/bots")

      assert index_live |> element("a", "New Bot") |> render_click() =~
               "New Bot"

      assert_patch(index_live, ~p"/bots/new")

      assert index_live
             |> form("#bot-form", bot: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bot-form", bot: %{is_available_for_rent: true, name: "unique name"})
             |> render_submit()

      assert_patch(index_live, ~p"/bots")

      html = render(index_live)
      assert html =~ "Bot created successfully"
      assert html =~ "unique name"
    end
  end

  describe "Show" do
    setup [:create_bot]

    test "displays bot", %{conn: conn, bot: bot} do
      {:ok, _show_live, html} = live(conn, ~p"/bots/#{bot}")

      assert html =~ "Show Bot"
      assert html =~ bot.name
    end

    test "updates bot within modal", %{conn: conn, bot: bot} do
      {:ok, show_live, _html} = live(conn, ~p"/bots/#{bot}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Bot"

      assert_patch(show_live, ~p"/bots/#{bot}/show/edit")

      assert show_live
             |> form("#bot-form", bot: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#bot-form", bot: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/bots/#{bot}")

      html = render(show_live)
      assert html =~ "Bot updated successfully"
      assert html =~ "some updated name"
    end
  end
end
