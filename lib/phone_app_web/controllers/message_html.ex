defmodule PhoneAppWeb.MessageHTML do
  use PhoneAppWeb, :html

  embed_templates "message_html/*"

  # Define the attributes that go into the message_form component, located
  # inside of the templates directory.
  alias PhoneApp.Conversations

  attr :changeset, Ecto.Changeset, required: true
  attr :contact, Conversations.Schema.Contact, required: false, default: nil

  def message_form(assigns)

  # <.simple_button text="Deliver" type="submit" />
  attr :type, :string, default: "button", values: ["button", "submit"]
  attr :text, :string, required: true
  attr :style, :string, default: "rounded border bg-white text-gray-700 px-4 py-2"

  def simple_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={@style}
    >
      <%= @text %>
    </button>
    """
  end

  # <.slot_button type="submit">
  #   <strong>Strong Button!</strong>
  # </.slot_button>
  attr :type, :string, default: "button", values: ["button", "submit"]
  slot :inner_block, required: true

  def slot_button(assigns) do
    ~H"""
    <button
      type={@type}
      class="rounded border bg-white text-gray-700 px-4 py-2"
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

