defmodule Ahpta.Conversations.Conversation do
  @moduledoc """
  The `Conversation` schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "conversations" do
    field :is_published, :boolean, default: false
    field :topic, :string

    has_many :conversation_participants, Ahpta.Conversations.ConversationParticipant,
      foreign_key: :conversation_id,
      on_delete: :delete_all

    has_many :messages, Ahpta.Messages.Message, foreign_key: :conversation_id

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:topic, :is_published])
    |> validate_required([:topic, :is_published])
  end
end
