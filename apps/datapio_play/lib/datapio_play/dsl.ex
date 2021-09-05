defmodule Datapio.Play.DSL do
  @moduledoc """
  Defines the macros to create books.
  """

  alias Datapio.Play.BookFailedError
  alias Datapio.Play.TaskFailedError

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
        IO.puts(IO.ANSI.format([:green, :birght, "===[ #{unquote(name)} ]==="]))

        try do
          unquote(block)

        rescue
          e ->
            reraise BookFailedError, [name: unquote(name), with: e], __STACKTRACE__

        end
      end
    end
  end

  @doc """
  Defines a new task within a book.
  """
  defmacro task(name, do: block) do
    quote do
      IO.puts(IO.ANSI.format([:blue, :bright, ":: #{unquote(name)}"]))

      try do
        unquote(block)

      rescue
        e ->
          reraise TaskFailedError, [name: unquote(name), with: e], __STACKTRACE__

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
