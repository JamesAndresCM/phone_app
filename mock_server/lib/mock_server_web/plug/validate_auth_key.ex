#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServerWeb.Plug.ValidateAuthKey do
  @moduledoc """
  This Plug checks that the authorization header is passed with the username mock-key-sid and
  the password mock-key.

  In a real app, you would combine these credentials with an account identifier and compare the
  passed values against a database record.
  """

  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> base64_key] -> validate_encoded_key(conn, base64_key)
      _ -> disallow_access(conn)
    end
  end

  defp validate_encoded_key(conn, base64_key) do
    with {:ok, key} <- Base.decode64(base64_key),
         ["mock-key-sid", "mock-key"] <- String.split(key, ":") do
      conn
    else
      _ -> disallow_access(conn)
    end
  end

  defp disallow_access(conn) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{
      "code" => 20003,
      "message" => "Authenticate",
      "more_info" => "https://www.twilio.com/docs/errors/20003",
      "status" => 401
    })
    |> halt()
  end
end
