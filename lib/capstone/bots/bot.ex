defmodule Capstone.Bots.Bot do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bots" do
    field(:is_available_for_rent, :boolean, default: false)
    field(:name, :string)
    field(:bot_server_pid, :binary)

    belongs_to(:owner, Capstone.Accounts.User)

    has_many(:system_messages, Capstone.SystemMessages.SystemMessage, foreign_key: :bot_id)

    has_many(:conversation_participants, Capstone.Conversations.ConversationParticipant,
      foreign_key: :bot_id
    )

    timestamps()
  end

  @doc false
  def changeset(bot, attrs) do
    atomized_attrs =
      Enum.map(attrs, fn
        {k, v} when is_binary(k) -> {String.to_atom(k), v}
        {k, v} -> {k, v}
      end)
      |> Enum.into(%{})

    bot
    |> cast(atomized_attrs, [:name, :is_available_for_rent, :bot_server_pid])
    |> validate_required([:name, :is_available_for_rent, :bot_server_pid])
  end
end
