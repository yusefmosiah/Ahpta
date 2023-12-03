defmodule AhptaWeb.ChatGPTControllerTest do
  use AhptaWeb.ConnCase, async: true

  setup do
    # Insert any setup data here
    :ok
  end

  test "POST /api/chatgpt", %{conn: conn} do
    message = "Test message"
    conn = post(conn, ~p"/api/chatgpt", %{message: message})

    assert json_response(conn, 200)["results"]
  end
end
