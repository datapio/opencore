defmodule Datapio.Play.BookNotFoundError do
  @moduledoc """
  Error raised when trying to run a non-existant book.
  """

  defexception name: "book"

  def message(e) do
    "Book '#{e.name}' was not found"
  end
end
