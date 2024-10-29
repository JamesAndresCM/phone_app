#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServerWeb.ErrorHelpers do
  def translate_errors(cs = %Ecto.Changeset{}) do
    nested_error_map =
      Ecto.Changeset.traverse_errors(cs, fn {err, _opts} ->
        err
      end)

    # Error map might look like: %{a: ["an error"], b: %{c: ["nested errors"]}}
    # Unroll it to a flat list
    traverse_error_map(nested_error_map, [], [])
    |> Enum.join(", ")
  end

  defp traverse_error_map(map = %{}, acc, keys) do
    Enum.reduce(map, acc, fn
      {k, errs}, acc when is_list(errs) ->
        field_name =
          [k | keys]
          |> Enum.reverse()
          |> Enum.join(" ")
          |> Phoenix.Naming.humanize()

        Enum.reduce(errs, acc, fn err, acc ->
          ["#{field_name} #{err}" | acc]
        end)

      {k, nested = %{}}, acc ->
        traverse_error_map(nested, acc, [k | keys])
    end)
  end
end
