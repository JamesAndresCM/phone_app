defmodule PhoneApp.Conversations.Schema.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    has_many :sms_messages, PhoneApp.Conversations.Schema.SmsMessage
    field :name, :string
    field :phone_number, :string

    timestamps()
  end

  @required_fields ~w(phone_number)a
  @doc false
  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(@required_fields)
  end
end
