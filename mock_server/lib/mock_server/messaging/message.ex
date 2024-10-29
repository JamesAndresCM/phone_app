#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServer.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :account_sid, :string
    field :api_version, :string
    field :body, :string
    field :date_created, :utc_datetime_usec
    field :date_sent, :utc_datetime_usec
    field :date_updated, :utc_datetime_usec
    field :direction, :string
    field :from, :string
    field :sid, :string
    field :status, :string
    field :to, :string
  end

  defimpl Jason.Encoder do
    def encode(value, opts) do
      map =
        value
        |> Map.from_struct()
        |> Map.new(fn {k, v} ->
          value =
            case v do
              %DateTime{} = dt -> format_date(dt)
              v -> v
            end

          {k, value}
        end)

      Jason.Encode.map(map, opts)
    end

    defp format_date(date), do: Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S %z")
  end

  def changeset(attrs) do
    fields = [
      :account_sid,
      :api_version,
      :body,
      :date_created,
      :date_sent,
      :date_updated,
      :direction,
      :from,
      :sid,
      :status,
      :to
    ]

    %__MODULE__{}
    |> cast(attrs, fields)
    |> validate_required(fields -- [:date_sent])
    |> validate_inclusion(:direction, ["outbound-api", "inbound"])
    |> validate_inclusion(:status, ["queued", "delivered", "failed", "receiving", "received"])
  end
end
