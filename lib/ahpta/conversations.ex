defmodule Ahpta.Conversations do
  @moduledoc """
  The Conversations context.
  """

  import Ecto.Query, warn: false
  alias Ahpta.Repo

  alias Ahpta.Conversations.Conversation
  alias Ahpta.Messages

  @doc """
  Returns the list of conversations.

  ## Examples

      iex> list_conversations()
      [%Conversation{}, ...]

  """
  def list_conversations do
    Repo.all(Conversation)
  end

  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.

  ## Examples

      iex> get_conversation!(123)
      %Conversation{}

      iex> get_conversation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation!(id) do
    Repo.get!(Conversation, id)
    |> Repo.preload(:messages)
  end

  def get_conversation(id) do
    case Repo.get(Conversation, id) do
      nil ->
        {:error, :not_found}

      conversation ->
        {:ok, conversation |> Repo.preload(:messages)}
    end
  end

  @doc """
  Creates a conversation.

  ## Examples

  iex> create_conversation(%{field: value})
  {:ok, %Conversation{}}

  iex> create_conversation(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation.

  ## Examples

  iex> update_conversation(conversation, %{field: new_value})
  {:ok, %Conversation{}}

  iex> update_conversation(conversation, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a conversation.

  ## Examples

  iex> delete_conversation(conversation)
  {:ok, %Conversation{}}

  iex> delete_conversation(conversation)
  {:error, %Ecto.Changeset{}}

  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

  iex> change_conversation(conversation)
  %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end

  alias Ahpta.Conversations.ConversationParticipant

  @doc """
  Gets all bots in single conversation.
  """
  def get_bots_in_conversation(conversation_id) do
    from(cp in ConversationParticipant,
      where:
        cp.conversation_id == ^conversation_id and
          cp.participant_type == "bot"
    )
    |> Repo.all()
    |> Enum.map(fn cp -> cp.bot_id end)
  end

  @doc """
  Returns the list of conversation_participants.

  ## Examples

  iex> list_conversation_participants()
  [%ConversationParticipant{}, ...]

  """
  def list_conversation_participants do
    Repo.all(ConversationParticipant)
  end

  @doc """
  Gets a single conversation_participant.

  Raises `Ecto.NoResultsError` if the Conversation participant does not exist.

  ## Examples

      iex> get_conversation_participant!(123)
      %ConversationParticipant{}

      iex> get_conversation_participant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation_participant!(id), do: Repo.get!(ConversationParticipant, id)

  @doc """
  Creates a conversation_participant.

  ## Examples

      iex> create_conversation_participant(%{field: value})
      {:ok, %ConversationParticipant{}}

      iex> create_conversation_participant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation_participant(attrs \\ %{}) do
    %ConversationParticipant{}
    |> ConversationParticipant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation_participant.

  ## Examples

      iex> update_conversation_participant(conversation_participant, %{field: new_value})
      {:ok, %ConversationParticipant{}}

      iex> update_conversation_participant(conversation_participant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation_participant(
        %ConversationParticipant{} = conversation_participant,
        attrs
      ) do
    conversation_participant
    |> ConversationParticipant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a conversation_participant.

  ## Examples

      iex> delete_conversation_participant(conversation_participant)
      {:ok, %ConversationParticipant{}}

      iex> delete_conversation_participant(conversation_participant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation_participant(%ConversationParticipant{} = conversation_participant) do
    Repo.delete(conversation_participant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation_participant changes.

  ## Examples

      iex> change_conversation_participant(conversation_participant)
      %Ecto.Changeset{data: %ConversationParticipant{}}

  """
  def change_conversation_participant(
        %ConversationParticipant{} = conversation_participant,
        attrs \\ %{}
      ) do
    ConversationParticipant.changeset(conversation_participant, attrs)
  end

  @doc """
  Adds a bot to a conversation
  """
  def add_bot_to_conversation(conversation_id, bot_id) do
    conversation = Repo.get!(Conversation, conversation_id)
    bot = Repo.get!(Bot, bot_id)

    %ConversationParticipant{}
    |> ConversationParticipant.changeset(%{
      conversation_id: conversation.id,
      participant_id: bot.id,
      participant_type: "bot",
      owner_permission: false
    })
    |> Repo.insert()
  end

  @doc """
  gets convo and messages
  """
  def get_conversation_and_messages(conversation_id) do
    with {:ok, conversation} <- get_conversation(conversation_id),
         {:ok, messages} <- Messages.list_messages(conversation_id) do
      {conversation, messages}
    end
  end
end
