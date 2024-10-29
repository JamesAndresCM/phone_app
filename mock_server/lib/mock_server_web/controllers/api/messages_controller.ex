#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServerWeb.Api.MessagesController do
  use MockServerWeb, :controller

  def create(conn, params) do
    case MockServer.Messaging.queue_message(:outbound, params) do
      {:ok, message} ->
        conn
        |> put_status(201)
        |> json(message)

      {:error, cs} ->
        cs_messages = MockServerWeb.ErrorHelpers.translate_errors(cs)

        conn
        |> put_status(422)
        |> json(%{code: 422, message: "Error creating message: #{cs_messages}"})
    end
  end

  def show(conn, %{"id" => id}) do
    # Must manually remove this because Twilio has a dynamic path format that doesn't work with Phoenix routing
    id = String.replace(id, ".json", "")

    case MockServer.Messaging.get_message(id) do
      {:ok, msg} -> json(conn, msg)
      {:error, :not_found} -> conn |> put_status(404) |> json(%{code: 404, message: "Message #{id} not found"})
    end
  end
end
