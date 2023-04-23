defmodule Capstone.Bots do
  @moduledoc """
  The Bots context.
  """

  import Ecto.Query, warn: false
  alias Capstone.Repo

  alias Capstone.Bots.Bot
  alias Capstone.Bots.BotServerSupervisor

  @doc """
  Returns the list of bots.

  ## Examples

      iex> list_bots()
      [%Bot{}, ...]

  """
  def list_bots do
    Repo.all(Bot)
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

  @doc """
  Creates a bot.

  ## Examples

      iex> create_bot(%{field: value})
      {:ok, %Bot{}}

      iex> create_bot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bot(attrs \\ %{}) do
    name = attrs[:name]

    {:ok, pid} =
      if name && String.trim(name) != "" do
        BotServerSupervisor.start_bot_server(name: String.to_atom(name))
      else
        BotServerSupervisor.start_bot_server([])
      end

    attrs_with_pid = Map.put(attrs, :bot_server_pid, pid |> :erlang.term_to_binary())

    %Bot{}
    |> Bot.changeset(attrs_with_pid)
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
end
