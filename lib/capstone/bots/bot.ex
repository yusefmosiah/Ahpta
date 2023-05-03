defmodule Capstone.Bots.Bot do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bots" do
    field(:is_available_for_rent, :boolean, default: false)
    field(:name, :string)
    field(:system_message, :string, default: "")
    belongs_to(:owner, Capstone.Accounts.User)

    has_many(:conversation_participants, Capstone.Conversations.ConversationParticipant,
      foreign_key: :bot_id
    )

    timestamps()
  end

  @doc false
  def changeset(bot, attrs) do
    bot
    |> cast(attrs, [:name, :is_available_for_rent, :system_message])
    |> validate_required([:name, :is_available_for_rent])
    |> unique_constraint(:name)
  end
end
