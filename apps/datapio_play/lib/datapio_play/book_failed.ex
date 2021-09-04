defmodule Datapio.Play.BookFailed do
  @moduledoc """
  Error raised when a book execution failed.
  """

  defexception name: "book", with: nil

  def message(e) do
    "Book '#{e.name}' failed with error: #{Exception.message(e.with)}"
  end
end
