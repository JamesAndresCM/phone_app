defmodule PhoneApp.Conversations do
  alias PhoneApp.Conversations.Query
  alias PhoneApp.Conversations.Schema
  alias PhoneApp.Conversations.Worker.StatusWorker

  defdelegate get_contact!(id), to: Query.ContactStore
  defdelegate update_sms_message(sid, params), to: Query.SmsMessageStore
  defdelegate new_message_changeset(params), to: Schema.NewMessage, as: :changeset

  def load_conversation_list do
    messages = Query.SmsMessageStore.load_message_list()
    Enum.map(messages, fn message ->
      %Schema.Conversation{
        contact: message.contact,
        messages: [message]
      }
    end)
  end

  def load_conversation_with(contact) do
    messages = Query.SmsMessageStore.load_messages_with(contact)
    %Schema.Conversation{contact: contact, messages: messages}
  end

  def send_sms_message(params = %Schema.NewMessage{}) do
    msg = %{
      from: your_number(),
      to: params.to,
      body: params.body
    }

    case PhoneApp.Twilio.send_sms_message!(msg) do
      %{body: resp = %{}} ->
        params = %{
          message_sid: resp["sid"],
          account_sid: resp["account_sid"],
          body: resp["body"],
          from: resp["from"],
          to: resp["to"],
          status: resp["status"],
          direction: :outgoing
        }
        create_sms_message(params)

        %{body: %{"code" => _, "message" => err }} ->
          {:error, err}
        _err ->
          {:error, "Failed to send message"}
    end
  end

  def your_number do
    twilio_config = Application.get_env(:phone_app, :twilio, [])
    Keyword.fetch!(twilio_config, :number)
  end

  def create_sms_message(params) do
    PhoneApp.Repo.transaction(fn ->
      with {:ok, message} <- Query.SmsMessageStore.create_sms_message(params),
           {:ok, _} <- maybe_enqueue_status_worker(message) do
            message
      else
        {:error, cs} -> PhoneApp.Repo.rollback(cs)
      end
    end)
  end

  def maybe_enqueue_status_worker(message) do
    case message do
      %{direction: :outgoing, status: "queued"} ->
        StatusWorker.enqueue(message)
      _ ->
        {:ok, :skipped}
    end
  end
end
