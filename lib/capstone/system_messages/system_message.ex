defmodule Capstone.SystemMessages.SystemMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "system_messages" do
    field :content, :string
    field :timestamp, :naive_datetime
    field :version, :integer

    belongs_to :bot, Capstone.Bots.Bot
    timestamps()
  end

  @doc false
  def changeset(system_message, attrs) do
    system_message
    |> cast(attrs, [:content, :version, :timestamp])
    |> validate_required([:content, :version, :timestamp])
  end
end
