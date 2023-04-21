defmodule Capstone.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "conversations" do
    field :is_published, :boolean, default: false
    field :topic, :string

    has_many :conversation_participants, Capstone.Conversations.ConversationParticipant,
      foreign_key: :conversation_id

    has_many :messages, Capstone.Messages.Message, foreign_key: :conversation_id

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:topic, :is_published])
    |> validate_required([:topic, :is_published])
  end
end