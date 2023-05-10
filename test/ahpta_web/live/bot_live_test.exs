defmodule AhptaWeb.BotLiveTest do
  use AhptaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ahpta.BotsFixtures

  @update_attrs %{is_available_for_rent: false, name: "some updated name"}
  @invalid_attrs %{is_available_for_rent: false, name: nil}

  defp create_bot(_) do
    bot = bot_fixture()

    {:ok, bot: bot}
  end

  describe "Index" do
    setup [:create_bot]

    # fixme test with and without logged in user
    # test "lists all bots", %{conn: conn, bot: bot} do
    #   {:ok, _index_live, html} = live(conn, ~p"/bots")

    #   assert html =~ "Listing Bots"
    #   assert html =~ bot.name
    # end

    # fixme to test editing textarea
    # test "saves new bot", %{conn: conn} do
    #   {:ok, index_live, _html} = live(conn, ~p"/bots")

    #   assert index_live |> element("a", "New Bot") |> render_click() =~
    #            "New Bot"

    #   assert_patch(index_live, ~p"/bots/new")

    #   assert index_live
    #          |> form("#bot-form", bot: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert index_live
    #          |> form("#bot-form", bot: %{is_available_for_rent: true, name: "unique name"})
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/bots")

    #   html = render(index_live)
    #   assert html =~ "Bot created successfully"
    #   assert html =~ "unique name"
    # end

    # fixme to test editing textarea
    # test "updates bot in listing", %{conn: conn, bot: bot} do
    #   {:ok, index_live, _html} = live(conn, ~p"/bots")

    #   assert index_live |> element(".text-blue-600", "Edit") |> render_click() =~ "Edit Bot"

    #   assert_patch(index_live, ~p"/bots/#{bot}/edit")

    #   assert index_live
    #          |> form("#bot-form", bot: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert index_live
    #          |> form("#bot-form", bot: @update_attrs)
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/bots")

    #   html = render(index_live)
    #   assert html =~ "Bot updated successfully"
    #   assert html =~ "some updated name"
    # end

    # test "deletes bot in listing", %{conn: conn, bot: bot} do
    #   {:ok, index_live, _html} = live(conn, ~p"/bots")

    #   assert index_live |> element(".text-red-600", "Delete") |> render_click()
    #   refute has_element?(index_live, "[data-bot-id='#{bot.id}']")
    # end
  end
end
