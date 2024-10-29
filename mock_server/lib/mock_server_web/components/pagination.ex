#---
# Excerpted from "From Ruby to Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/sbelixir for more book information.
#---
defmodule MockServerWeb.Pagination do
  @moduledoc """
  Pagination component that operates off of a Scrivener struct.

  * pager: (required) Clove.Ecto.CommonOpts struct that holds pagination information
           The pager may be a GraphQL pagination struct (stringified CommonOpts.paginate_struct) as well.
  * total_entries: (required) Integer of how many records there are in total
  """

  use MockServerWeb, :html

  def render(assigns) do
    ~H"""
    <div class="flex flex-col sm:flex-row items-center gap-2">
      <div class="space-x-2 flex">
        <.link href={"?page=#{@pager.page - 1}"} {paging_click(@pager, :prev, @total_entries)}>
          <svg
            class="h-5 w-5 -ml-2"
            x-description="Heroicon name: solid/chevron-left"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
              clip-rule="evenodd"
            >
            </path>
          </svg>
          <span>Previous</span>
        </.link>

        <.link href={"?page=#{@pager.page + 1}"} {paging_click(@pager, :next, @total_entries)}>
          <span>Next</span>
          <svg
            class="h-5 w-5 -mr-2"
            x-description="Heroicon name: solid/chevron-right"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
              clip-rule="evenodd"
            >
            </path>
          </svg>
        </.link>
      </div>
    </div>
    """
  end

  defp paging_click(%{page: page, page_size: page_size}, type, total_count) do
    total_pages = ceil(total_count / page_size)
    common_class = "btn flex items-center"

    cond do
      type == :prev and page <= 1 ->
        %{"disabled" => true, "class" => "cursor-not-allowed #{common_class} text-gray-500"}

      type == :next and page >= total_pages ->
        %{"disabled" => true, "class" => "cursor-not-allowed #{common_class} text-gray-500"}

      true ->
        %{"class" => "#{common_class} btn-muted"}
    end
  end

  defp paging_click(%{"current_page" => page, "page_size" => page_size}, type, total_count) do
    paging_click(%{page: page, page_size: page_size}, type, total_count)
  end
end
