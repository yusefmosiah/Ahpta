defmodule Capstone.Bots do
  @moduledoc """
  The Bots context.
  """

  import Ecto.Query, warn: false
  alias Capstone.Repo

  alias Capstone.Bots.Bot
  alias Capstone.Conversations.Conversation
  alias Capstone.Conversations.ConversationParticipant

  @doc """
  Returns the list of bots.

  ## Examples

      iex> list_bots()
      [%Bot{}, ...]

  """
  def list_bots do
    Repo.all(Bot)
  end

  def get_bots_by_availability_and_ownership(user_id) do
    all_bots = Repo.all(Bot)

    unavailables = Enum.filter(all_bots, fn bot -> bot.is_available_for_rent == false end)

    availables = Enum.filter(all_bots, fn bot -> bot.is_available_for_rent == true end)

    availables_not_owned_by_user = Enum.filter(availables, fn bot -> bot.owner_id != user_id end)

    availables_owned_by_user = Enum.filter(availables, fn bot -> bot.owner_id == user_id end)

    %{
      unavailables: unavailables,
      availables_not_owned_by_user: availables_not_owned_by_user,
      availables_owned_by_user: availables_owned_by_user
    }
  end

  @doc """
  Gets a single bot.

  Raises `Ecto.NoResultsError` if the Bot does not exist.

  ## Examples

      iex> get_bot!(123)
      %Bot{}

      iex> get_bot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bot!(id), do: Repo.get!(Bot, id)

  def get_bot(id), do: Repo.get(Bot, id)

  @doc """
  Creates a bot.

  ## Examples

      iex> create_bot(%{field: value})
      {:ok, %Bot{}}

      iex> create_bot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bot(attrs \\ %{}) do
    %Bot{}
    |> Bot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bot.

  ## Examples

      iex> update_bot(bot, %{field: new_value})
      {:ok, %Bot{}}

      iex> update_bot(bot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bot(%Bot{} = bot, attrs) do
    bot
    |> Bot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bot.

  ## Examples

      iex> delete_bot(bot)
      {:ok, %Bot{}}

      iex> delete_bot(bot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bot(%Bot{} = bot) do
    Repo.delete(bot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bot changes.

  ## Examples

      iex> change_bot(bot)
      %Ecto.Changeset{data: %Bot{}}

  """
  def change_bot(%Bot{} = bot, attrs \\ %{}) do
    Bot.changeset(bot, attrs)
  end

  ## by gpt-4
  def subscribe_to_conversation(%Bot{} = bot, %Conversation{} = conversation) do
    query =
      from(cp in ConversationParticipant,
        where: cp.bot_id == ^bot.id and cp.conversation_id == ^conversation.id
      )

    case Repo.one(query) do
      nil ->
        %ConversationParticipant{}
        |> ConversationParticipant.changeset(%{
          bot_id: bot.id,
          conversation_id: conversation.id,
          participant_type: "bot"
        })
        |> Repo.insert()

      _ ->
        {:error, :already_subscribed}
    end
  end

  def unsubscribe_from_conversation(%Bot{} = bot, %Conversation{} = conversation) do
    query =
      from(cp in ConversationParticipant,
        where: cp.bot_id == ^bot.id and cp.conversation_id == ^conversation.id
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_subscribed}

      cp ->
        Repo.delete(cp)
    end
  end

  def list_subscribed_conversations(bot_id) do
    from(cp in ConversationParticipant,
      where: cp.bot_id == ^bot_id,
      preload: :conversation
    )
    |> Repo.all()
    |> Enum.map(& &1.conversation.id)
  end

  def list_subscribed_bots_for_conversation(%Conversation{} = conversation) do
    query =
      from(cp in ConversationParticipant,
        where: cp.conversation_id == ^conversation.id,
        where: cp.participant_type == "bot",
        preload: :bot
      )

    participants = Repo.all(query)
    Enum.map(participants, & &1.bot)
  end
end
