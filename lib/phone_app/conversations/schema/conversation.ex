defmodule PhoneApp.Conversations.Schema.Conversation do
  @enforce_keys [:contact, :messages]
  defstruct @enforce_keys
end
