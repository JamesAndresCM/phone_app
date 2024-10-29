#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServerWeb.MessageListLive do
  use MockServerWeb, :live_view

  def render(assigns) do
    ~H"""
    <main class="max-w-6xl mx-auto my-20">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Mock SMS Messages</h1>

            <div class="mt-4 space-y-2 text-sm text-gray-700 max-w-3xl">
              <p>
                Unfortunately, SMS regulation (10DLC) makes it harder for hobbyists to send SMS messages. So, this mock
                server stores SMS messages in a GenServer and provides a compatible API that's useful for our purposes.
              </p>

              <p>
                You can reply to a received message below. It will be sent to your app server running
                at <a class="underline" href="http://localhost:4004/messages">http://localhost:4004</a>, which is the default port and URL.
              </p>
            </div>
          </div>
        </div>

        <div class="my-4 flex items-center justify-end">
          <MockServerWeb.Pagination.render pager={%{page: @page, page_size: 10}} total_entries={@count} />
        </div>

        <div class="flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-lg">
                <table class="min-w-full divide-y divide-gray-300">
                  <thead class="bg-gray-50">
                    <tr>
                      <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">From</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">To</th>
                      <th scope="col" class="w-1/2 px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Message</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Status</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-200 bg-white">
                    <tr :for={message <- @messages}>
                      <td class="py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6"><%= message.from %></td>
                      <td class="px-3 py-4 text-sm text-gray-500"><%= message.to %></td>
                      <td class="px-3 py-4 text-sm text-gray-500 break-all">
                        <div class="whitespace-pre-line"><%= message.body %></div>

                        <%!--
                          This is a simple form, so a changeset or phx-update is not used.

                          Usually, you want to have a changeset + phx-update defined so your form will recover on
                          server disconnects.
                        --%>
                        <form :if={message.direction == "outbound-api"} class="mt-2" phx-submit="reply">
                          <input type="hidden" name="in_reply_to" value={message.sid} />

                          <div class="flex items-center gap-2">
                            <input class="form-input" type="text" name="body" required placeholder="Type a reply" />
                            <button type="submit" class="btn">Reply</button>
                          </div>
                        </form>
                      </td>
                      <td class="px-3 py-4 text-sm text-gray-500"><%= Phoenix.Naming.humanize(message.status) %></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    # LiveViews process twice (once static, once "live"). We only want to subscribe to messages when connected to the live version
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MockServer.PubSub, "messages")
    end

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer() |> max(1)
    paged_messages = MockServer.Messaging.paged_messages(page: page)
    clamped_min = min(page, paged_messages.num_pages)
    clamped = max(clamped_min, 1)

    socket =
      socket
      |> assign(paged_messages)
      |> assign(page: clamped)

    {:noreply, socket}
  end

  def handle_event("reply", %{"body" => body, "in_reply_to" => sid}, socket) do
    socket =
      with message when message != nil <- Enum.find(socket.assigns.messages, &(&1.sid == sid)),
           {:ok, _sent} <- MockServer.Messaging.queue_message(:reply, %{body: body}, message) do
        put_flash(socket, "info", "Mock message sending to your local app")
      else
        nil -> put_flash(socket, "error", "Replied message not found")
        {:error, _cs} -> put_flash(socket, "error", "Invalid message")
      end

    {:noreply, socket}
  end

  # Real-time: if a message is created while we're on page 1, then we can reload that page to refresh the UI
  def handle_info({:new, %MockServer.Messaging.Message{}}, socket) do
    socket =
      if socket.assigns.page == 1 do
        paged_messages = MockServer.Messaging.paged_messages(page: 1)
        assign(socket, paged_messages)
      else
        socket
      end

    {:noreply, socket}
  end

  # Real-time: update the message in-memory if we have it
  def handle_info({:update, updated = %MockServer.Messaging.Message{}}, socket) do
    new_messages =
      Enum.map(socket.assigns.messages, fn message ->
        if message.sid == updated.sid do
          updated
        else
          message
        end
      end)

    {:noreply, assign(socket, messages: new_messages)}
  end
end
