defmodule Datapio.Play.Manifest do
  @moduledoc """
  Defines the macro to build the play manifest.
  """

  alias Datapio.Play.BookNotFound

  @doc """
  Defines what books to run and what task to perform in case of book failure.
  """
  defmacro play(do: books, rescue: on_failure) do
    quote do
      :ets.new(:datapio_play_books, [:set, :public, :named_table])

      Datapio.Play.Utilities.discover_books()

      try do
        unquote(books)  # First pass, tag books
        unquote(books)  # Second pass, run books
      rescue
        e in BookNotFound ->
          IO.puts("!! BookNotFound: #{e.name}")

        e ->
          IO.puts("!! ERROR: #{Exception.message(e)}")

          unquote(on_failure)
      end
    end
  end

  @doc """
  Run a book.

  NB: This function will be executed twice:
   - first to detect if the book exists
   - second to effectively run the book
  """
  defmacro run(book) do
    quote do
      case :ets.lookup(:datapio_play_books, unquote(book)) do
        [] ->
          raise BookNotFound, name: unquote(book)

        [{book, false}] ->  # First pass
          :ets.insert(:datapio_play_books, {book, true})

        [{book, true}] ->  # Second pass
          apply(book, :run_book, [])
      end
    end
  end
end
