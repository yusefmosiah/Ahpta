defmodule CapstoneWeb.PageControllerTest do
  use CapstoneWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Convos"
  end
end
