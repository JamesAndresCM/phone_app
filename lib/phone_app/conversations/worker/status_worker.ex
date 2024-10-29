defmodule PhoneApp.Conversations.Worker.StatusWorker do
  use Oban.Worker

  alias PhoneApp.Conversations.Query.SmsMessageStore
  alias PhoneApp.Conversations.Schema.SmsMessage

  def enqueue(%SmsMessage{} = message) do
    %{"id" => message.id}
    |> new()
    |> Oban.insert()
  end

  def perform(%Oban.Job{args: %{"id" => message_id}}) do
    message = SmsMessageStore.get_sms_message!(message_id)
    %{body: resp} = PhoneApp.Twilio.get_sms_message!(message)

    case resp["status"] do
      "queued" ->
        {:snooze, 30} # seconds to retry
        #{:error, "Message not ready"}

      status ->
        IO.inspect("******ENTRY IN WORKER SUCCESSFULLY******")
        PhoneApp.Conversations.update_sms_message(
          message.message_sid,
          %{status: status}
        )
    end
  end
end
