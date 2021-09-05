defmodule Datapio.Play.BookFailedError do
  @moduledoc """
  Error raised when a book execution failed.
  """

  defexception name: "book", with: nil

  alias Datapio.Play.TaskFailedError

  def message(e) do
    case e.with do
      %TaskFailedError{} = err ->
        """
        Book(#{e.name}) > #{Exception.message(err)}
        """

      err ->
        """
        Book(#{e.name}):
        #{Exception.message(err)}
        """

    end
  end
end
