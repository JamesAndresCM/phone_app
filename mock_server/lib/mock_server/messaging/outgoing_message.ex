#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServer.Messaging.OutgoingMessage do
  @moduledoc """
  Emulates (partially) Twilio's webhook format to send messages from mock server -> app server
  """

  def deliver_webhook(message = %MockServer.Messaging.Message{}) do
    params = %{
      "MessageSid" => message.sid,
      "AccountSid" => message.account_sid,
      "Body" => message.body,
      "From" => message.from,
      "To" => message.to,
      "SmsStatus" => message.status
    }

    case Req.post!(app_url(), json: params) do
      %{status: 200} -> :ok
      response -> {:error, response}
    end
  end

  defp app_url do
    Application.get_env(:mock_server, :outgoing_url) || "http://localhost:#{app_port()}/webhook/sms"
  end

  defp app_port do
    Application.fetch_env!(:mock_server, :outgoing_message_port)
  end
end
