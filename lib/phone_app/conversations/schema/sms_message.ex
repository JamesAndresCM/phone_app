defmodule PhoneApp.Conversations.Schema.SmsMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sms_messages" do
    belongs_to :contact, PhoneApp.Conversations.Schema.Contact
    field :status, :string
    field :body, :string
    field :to, :string
    field :from, :string
    field :message_sid, :string
    field :account_sid, :string

    field :direction , Ecto.Enum, values: [:incoming, :outgoing]
    timestamps()
  end

  @doc false
  @update_fields ~w(status)a
  @required_fields ~w(contact_id message_sid account_sid body from to status direction)a

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:message_sid])
  end

  def update_changeset(attrs, struct = %__MODULE__{}) do
    struct
    |> cast(attrs, @update_fields)
    |> validate_required(@update_fields)
  end
end
