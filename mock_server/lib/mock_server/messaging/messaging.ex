#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServer.Messaging do
  defdelegate queue_message(direction, params), to: MockServer.Messaging.Server
  defdelegate queue_message(direction, params, in_reply_to), to: MockServer.Messaging.Server
  defdelegate get_message(id), to: MockServer.Messaging.Server
  defdelegate paged_messages(opts), to: MockServer.Messaging.Server
end
