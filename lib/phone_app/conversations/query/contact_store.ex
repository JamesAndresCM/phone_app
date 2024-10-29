defmodule PhoneApp.Conversations.Query.ContactStore do
  alias PhoneApp.Conversations.Schema.Contact
  alias PhoneApp.Repo

  def get_contact!(id) do
    Repo.get!(Contact, id)
  end

  def upsert_contact(%{from: from, to: to, direction: direction}) do
    contact_number =
      case direction do
        :incoming -> from
        :outgoing -> to
      end

    cs = Contact.changeset(%{phone_number: contact_number})

    Repo.insert(
      cs,
      returning: true,
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:phone_number]
    )
  end
end
