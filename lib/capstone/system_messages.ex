defmodule Capstone.SystemMessages do
  @moduledoc """
  The SystemMessages context.
  """

  import Ecto.Query, warn: false
  alias Capstone.Repo

  alias Capstone.SystemMessages.SystemMessage

  @doc """
  Returns the list of system_messages.

  ## Examples

      iex> list_system_messages()
      [%SystemMessage{}, ...]

  """
  def list_system_messages do
    Repo.all(SystemMessage)
  end

  @doc """
  Gets a single system_message.

  Raises `Ecto.NoResultsError` if the System message does not exist.

  ## Examples

      iex> get_system_message!(123)
      %SystemMessage{}

      iex> get_system_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_system_message!(id), do: Repo.get!(SystemMessage, id)

  @doc """
  Creates a system_message.

  ## Examples

      iex> create_system_message(%{field: value})
      {:ok, %SystemMessage{}}

      iex> create_system_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_system_message(attrs \\ %{}) do
    %SystemMessage{}
    |> SystemMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a system_message.

  ## Examples

      iex> update_system_message(system_message, %{field: new_value})
      {:ok, %SystemMessage{}}

      iex> update_system_message(system_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_system_message(%SystemMessage{} = system_message, attrs) do
    system_message
    |> SystemMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a system_message.

  ## Examples

      iex> delete_system_message(system_message)
      {:ok, %SystemMessage{}}

      iex> delete_system_message(system_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_system_message(%SystemMessage{} = system_message) do
    Repo.delete(system_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking system_message changes.

  ## Examples

      iex> change_system_message(system_message)
      %Ecto.Changeset{data: %SystemMessage{}}

  """
  def change_system_message(%SystemMessage{} = system_message, attrs \\ %{}) do
    SystemMessage.changeset(system_message, attrs)
  end
end
