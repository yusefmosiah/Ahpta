defmodule Capstone.Conversations.ConversationParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "conversation_participants" do
    field :owner_permission, :boolean, default: false
    field :participant_type, :string

    belongs_to :conversation, Capstone.Conversations.Conversation
    belongs_to :participant, Capstone.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(conversation_participant, attrs) do
    conversation_participant
    |> cast(attrs, [:participant_type, :owner_permission])
    |> validate_required([:participant_type, :owner_permission])
  end
end
