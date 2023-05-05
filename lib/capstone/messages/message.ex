defmodule Capstone.Messages.Message do
  @moduledoc """
  The Schema and changeset for "message".
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:content, :string)
    field(:message_type, :string)

    belongs_to(:sender, Capstone.Accounts.User)
    belongs_to(:conversation, Capstone.Conversations.Conversation)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :message_type, :sender_id, :conversation_id])
    |> validate_required([:content, :message_type, :sender_id, :conversation_id])
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:conversation_id)
  end
end
