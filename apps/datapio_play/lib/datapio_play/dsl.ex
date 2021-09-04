defmodule Datapio.Play.DSL do
  @moduledoc """
  Defines the macros to create books.
  """

  alias Datapio.Play.BookFailed
  alias Datapio.Play.TaskFailed

  defmacro __using__(_opts) do
    quote do
      require Datapio.Play.DSL
      import Datapio.Play.DSL
    end
  end

  @doc """
  Defines a new book.
  """
  defmacro book(name, do: block) do
    quote do
      def run_book() do
        IO.puts("===[ #{unquote(name)} ]===")

        try do
          unquote(block)

        rescue
          e ->
            raise BookFailed, name: unquote(name), with: e

        end
      end
    end
  end

  @doc """
  Defines a new task within a book.
  """
  defmacro task(name, do: block) do
    quote do
      IO.puts(":: #{unquote(name)}")

      try do
        unquote(block)

      rescue
        e ->
          raise TaskFailed, name: unquote(name), with: e

      end
    end
  end

  @doc """
  Defines a new step within a task.
  """
  defmacro step(name, uses: step_kind, with: opts) do
    quote do
      Datapio.Play.Utilities.run_step(
        unquote(step_kind),
        unquote(name),
        unquote(opts)
      )
    end
  end
end
