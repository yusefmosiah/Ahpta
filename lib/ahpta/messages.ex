defmodule Ahpta.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Ahpta.Repo

  alias Ahpta.Messages.Message
  alias ExOpenAI.Embeddings
  alias Qdrant.Api.Http.Points

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  def list_messages(conversation_id) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:sender)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id) |> Repo.preload([:sender, :conversation])

  def get_messages_from_ids(ids) do
    query = from(m in Message, where: m.id in ^ids)
    Repo.all(query)
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def to_openai_format(messages) do
    Enum.map(messages, fn
      %Ahpta.Messages.Message{content: content, message_type: "bot"} ->
        %{content: content, role: "assistant"}

      %Ahpta.Messages.Message{content: content, message_type: "human"} ->
        %{content: content, role: "user"}
    end)
  end

  def get_embeddings(content) do
    case Embeddings.create_embedding(content, "text-embedding-ada-002") do
      {:ok, %{data: [%{embedding: embedding}]}} -> {:ok, embedding}
      {:error, error} -> {:error, error}
    end
  end

  def search_qdrant(embedding) do
    case Points.search_points("ahpta", %{vector: embedding, limit: 10, with_payload: true}) do
      {:ok, %{body: %{"result" => search_results}}} -> {:ok, search_results}
      {:error, error} -> {:error, error}
    end
  end

  def augment_user_msg(user_msg, search_results) do
    # Modify user_msg based on search_results as needed
    {user_msg, search_results}
  end

  def handle_tasks(message) do
    with {:ok, embedding} <- get_embeddings(message.content),
         {:ok, search_results} <- search_qdrant(embedding) do
      {:ok, augment_user_msg(message, search_results)}
    else
      {:error, error} -> {:error, error}
    end
  end

  def upsert_bot_task(embedding, bot_message) do
    Qdrant.upsert_point("ahpta", %{
      points: [
        %{
          id: bot_message.id,
          vector: embedding,
          payload: %{
            message_type: "bot",
            content: bot_message.content,
            sender_id: bot_message.sender_id,
            conversation_id: bot_message.conversation_id
          }
        }
      ]
    })
  end

  def perform_bot_tasks(message_attrs) do
    with {:ok, bot_message} <- create_message(message_attrs),
         {:ok, embedding} <- get_embeddings(bot_message.content),
         {:ok, _upsert_response} <- upsert_bot_task(embedding, bot_message) do
      {:ok, bot_message}
    else
      {:error, error} -> {:error, error}
    end
  end

  def get_context(messages, max_chars \\ 14_000) do
    messages
    |> Enum.reverse()
    |> to_openai_format()
    |> Enum.reduce_while({0, []}, fn message, {sum, result} ->
      content_length = byte_size(message.content)

      if sum + content_length <= max_chars do
        {:cont, {sum + content_length, [message | result]}}
      else
        {:halt, {sum, result}}
      end
    end)
    |> elem(1)
  end
end
