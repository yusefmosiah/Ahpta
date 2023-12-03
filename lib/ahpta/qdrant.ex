defmodule Ahpta.Qdrant do
  alias ExOpenAI.Embeddings
  alias Qdrant.Api.Http.Points

  def create_embedding_and_save(content) do
    case Embeddings.create_embedding(content, "text-embedding-ada-002") do
      {:ok, %{data: [%{embedding: embedding}]}} ->
        save_to_qdrant({:ok, embedding}, content)

      {:error, error} ->
        {:error, error}
    end
  end

  def save_to_qdrant({:ok, embedding}, content) when is_list(embedding) do
    id = :crypto.strong_rand_bytes(16) |> Base.encode16()

    case Points.upsert_points("ahpta", %{
           points: [
             %{
               id: id,
               vector: embedding,
               payload: %{content: content}
             }
           ]
         }) do
      {:ok, _response} -> search_qdrant({:ok, embedding})
      {:error, error} -> {:error, error}
    end
  end

  def search_qdrant({:ok, embedding}) when is_list(embedding) do
    case Points.search_points("ahpta", %{vector: embedding, limit: 10, with_payload: true}) do
      {:ok, %{body: %{"result" => search_results}}} -> {:ok, search_results}
      {:ok, %{status: 400}} -> %{error: "Search failed with status 400"}
      {:error, error} -> %{error: error}
    end
  end
end
