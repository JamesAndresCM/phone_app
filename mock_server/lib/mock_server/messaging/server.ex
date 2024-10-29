#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServer.Messaging.Server do
  @moduledoc """
  GenServer implementation that acts like a fake SMS delivery service.

  Messages are stored in memory and progressed through a state update within a short time frame.

  This GenServer is a "single global process", which means it acts as a bottleneck for the application. In a
  high-throughput use case, you'd likely shard the state by some ID, or you would use ETS to allow for
  cross-process reads.

  This server does not persist messages across reloads. (It's not particularly useful or relevant for the book.) Options
  such as a database, file system, or DETS could be used for persistence.
  """

  use GenServer

  require Logger

  alias MockServer.Messaging.Message

  @doc """
  Start this server (1 running per application)
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Retrieve a single message
  """
  def get_message(sid) do
    GenServer.call(__MODULE__, {:get, sid})
  end

  @doc """
  Retrieve a page of messages, as well as information needed to show pagination UI
  """
  def paged_messages(page: page) when page > 0 do
    GenServer.call(__MODULE__, {:paged, page, 10})
  end

  @doc """
  Trigger a message to be "sent". It has a high likelihood of success, but it can "fail" with a 10% chance.
  """
  def queue_message(:outbound, params) do
    now = DateTime.utc_now()

    %{
      account_sid: params["account_sid"],
      api_version: "2010-04-01",
      body: params["Body"],
      date_created: now,
      date_sent: nil,
      date_updated: now,
      direction: "outbound-api",
      from: params["From"],
      sid: "MOCK-" <> Ecto.UUID.generate(),
      status: "queued",
      to: params["To"]
    }
    |> Message.changeset()
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, msg} -> GenServer.call(__MODULE__, {:put, msg})
      ret -> ret
    end
  end

  def queue_message(:reply, params, in_reply_to = %Message{}) do
    now = DateTime.utc_now()

    %{
      account_sid: in_reply_to.account_sid,
      api_version: in_reply_to.account_sid,
      body: params[:body],
      date_created: now,
      date_sent: now,
      date_updated: now,
      direction: "inbound",
      from: in_reply_to.to,
      sid: "MOCK-" <> Ecto.UUID.generate(),
      status: "receiving",
      to: in_reply_to.from
    }
    |> Message.changeset()
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, msg} -> GenServer.call(__MODULE__, {:put_reply, msg})
      ret -> ret
    end
  end

  def init(_opts) do
    {:ok, %{messages: %{}, ordered: []}}
  end

  def handle_call({:get, sid}, _from, state = %{messages: messages}) do
    resp =
      case Map.get(messages, sid) do
        nil -> {:error, :not_found}
        msg -> {:ok, msg}
      end

    {:reply, resp, state}
  end

  def handle_call({:put, msg}, _from, state = %{messages: messages, ordered: ordered}) do
    new_messages = Map.put(messages, msg.sid, msg)
    new_ordered = [msg.sid | ordered]
    Process.send_after(self(), {:progress, msg.sid}, Enum.random(1_000..15_000))
    {:reply, {:ok, msg}, %{state | messages: new_messages, ordered: new_ordered}, {:continue, {:new, msg.sid}}}
  end

  def handle_call({:put_reply, msg}, _from, state = %{messages: messages, ordered: ordered}) do
    new_messages = Map.put(messages, msg.sid, msg)
    new_ordered = [msg.sid | ordered]
    send(self(), {:deliver_reply, msg.sid})
    {:reply, {:ok, msg}, %{state | messages: new_messages, ordered: new_ordered}, {:continue, {:new, msg.sid}}}
  end

  def handle_call({:paged, page, page_size}, _from, state = %{messages: messages, ordered: ordered}) do
    size = map_size(messages)
    start_index = (page - 1) * page_size
    end_index = start_index + page_size - 1

    ids = Enum.slice(ordered, start_index..end_index)
    messages = Enum.map(ids, &Map.fetch!(messages, &1))

    {:reply, %{messages: messages, count: size, num_pages: ceil(size / page_size)}, state}
  end

  def handle_info({:progress, sid}, state = %{messages: messages}) do
    next_state =
      case Map.get(messages, sid) do
        nil ->
          Logger.error("#{__MODULE__} progress missing message sid=#{sid}")
          state

        message ->
          status = random_final_status()
          date_sent = if status == "delivered", do: DateTime.utc_now()

          new_message = %{message | status: status, date_sent: date_sent, date_updated: DateTime.utc_now()}
          new_messages = Map.put(messages, sid, new_message)
          Logger.info("#{__MODULE__} progress sid=#{sid} status=#{status}")

          %{state | messages: new_messages}
      end

    {:noreply, next_state, {:continue, {:update, sid}}}
  end

  def handle_info({:deliver_reply, sid}, state = %{messages: messages}) do
    next_state =
      case Map.get(messages, sid) do
        message = %{status: "receiving"} ->
          new_message =
            case MockServer.Messaging.OutgoingMessage.deliver_webhook(message) do
              :ok ->
                %{message | status: "received", date_updated: DateTime.utc_now()}

              _ ->
                %{message | status: "failed"}
            end

          new_messages = Map.put(messages, sid, new_message)
          %{state | messages: new_messages}

        message ->
          Logger.error("#{__MODULE__} deliver_reply sid=#{sid} message=#{inspect(message)}")
          state
      end

    {:noreply, next_state, {:continue, {:update, sid}}}
  end

  # handle_continue/2 callback is useful for doing work after a message is processed
  # A continuation is always invoked immediately, so it will always be after the message finishes processing
  def handle_continue({type, sid}, state) do
    case Map.get(state.messages, sid) do
      nil -> nil
      message -> Phoenix.PubSub.broadcast!(MockServer.PubSub, "messages", {type, message})
    end

    {:noreply, state}
  end

  defp random_final_status do
    case :rand.uniform(100) do
      i when i <= 90 -> "delivered"
      _ -> "failed"
    end
  end
end
