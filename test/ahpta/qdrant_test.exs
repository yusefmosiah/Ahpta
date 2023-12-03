defmodule Ahpta.QdrantTest do
  use ExUnit.Case
  alias Ahpta.Qdrant
  alias ExOpenAI.Embeddings

  # commented out bc these tests require api keys
  # describe "create_embedding_and_save/1" do
  #   test "returns :ok when embedding is created and saved successfully" do
  #     content = "test content"
  #     assert {:ok, _} = Qdrant.create_embedding_and_save(content)
  #   end

  #   test "returns :error when embedding creation fails" do
  #     content = %{a: "invalid content"}
  #     assert {:error, _} = Qdrant.create_embedding_and_save(content)
  #   end
  # end

  # describe "save_to_qdrant/2" do
  #   test "returns :ok when point is upserted successfully" do
  #     {:ok, %{data: [%{embedding: embedding}]}} =
  #       Embeddings.create_embedding("test content", "text-embedding-ada-002")

  #     content = "test content"
  #     assert {:ok, _} = Qdrant.save_to_qdrant({:ok, embedding}, content)
  #   end
  # end

  # describe "search_qdrant/1" do
  #   test "returns :ok when points are found" do
  #     {:ok, %{data: [%{embedding: embedding}]}} =
  #       Embeddings.create_embedding("test content", "text-embedding-ada-002")

  #     assert {:ok, _} = Qdrant.search_qdrant({:ok, embedding})
  #   end
  # end
end
