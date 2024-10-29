defmodule PhoneApp.ConversationsTest do
  use PhoneApp.DataCase, async: true
  use Oban.Testing, repo: Repo

  alias PhoneApp.Conversations
  alias PhoneApp.Conversations.Schema.NewMessage
  alias PhoneApp.Conversations.Worker.StatusWorker

  describe "send_sms_message/1" do
    test "successful request creates an SMS message" do
      bypass = Bypass.open()
      Process.put(:twilio_base_url, "http://localhost:#{bypass.port}")

      resp = Jason.decode!(File.read!("test/support/fixtures/success.json"))

      Bypass.expect_once(
        bypass,
        "POST",
        "/Accounts/mock-account/Messages.json",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Content-Type", "application/json")
          |> Plug.Conn.resp(201, Jason.encode!(resp))
        end
      )

      assert {:ok, message} = Conversations.send_sms_message(%NewMessage{})
      assert message.from == resp["from"]
      assert message.to == resp["to"]
      assert message.body == resp["body"]
      assert message.message_sid == resp["sid"]
      assert message.account_sid == resp["account_sid"]
      assert message.status == resp["status"]
      assert message.direction == :outgoing
    end

    test "a failed request returns an error" do
      bypass = Bypass.open()
      Process.put(:twilio_base_url, "http://localhost:#{bypass.port}")

      Bypass.expect_once(
        bypass,
        "POST",
        "/Accounts/mock-account/Messages.json",
        fn conn ->
          Plug.Conn.resp(conn, 500, "")
        end
      )

      assert Conversations.send_sms_message(%NewMessage{}) ==
               {:error, "Failed to send message"}
    end
  end

  describe "create_sms_message/1" do
    test "a valid SMS message is created" do
      params = Test.Factory.SmsMessageFactory.params()
      assert {:ok, msg} = Conversations.create_sms_message(params)
      assert_enqueued(worker: StatusWorker, args: %{"id" => msg.id})
    end

    test "incoming SMS message doesn't enqueue a worker" do
      params = Test.Factory.SmsMessageFactory.params(%{direction: :incoming})
      assert {:ok, _msg} = Conversations.create_sms_message(params)
      refute_enqueued(worker: StatusWorker)
    end

    test "an invalid message returns an error" do
      params = Test.Factory.SmsMessageFactory.params(%{message_sid: ""})
      assert {:error, _} = Conversations.create_sms_message(params)
      refute_enqueued(worker: StatusWorker)
    end
  end
end
