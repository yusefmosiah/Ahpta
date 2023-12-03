defmodule AhptaWeb.ChatGPTController do
  use AhptaWeb, :controller

  def create(conn, %{"message" => message}) do
    # Save the message in Qdrant
    case Ahpta.Qdrant.create_embedding_and_save(message) do
      {:ok, results} ->
        # Return top results
        json(conn, %{results: results})

      {:error, error} ->
        json(conn, %{error: error})
    end
  end
end
