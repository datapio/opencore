defmodule Datapio.Play.BookFailedError do
  @moduledoc """
  Error raised when a book execution failed.
  """

  defexception name: "book", with: nil

  def message(e) do
    case e.with do
      task_error in TaskFailedError ->
        case task_error.with do
          step_error in StepFailedError ->
            """
            Book(#{e.name}) > Task(#{task_error.name}) > Step(#{step_error.name}):
            #{inspect(step_error.info)}
            """

          err ->
            """
            Book(#{e.name}) > Task(#{task_error.name}):
            #{Exception.message(err)}
            """

        end

      err ->
        """
        Book(#{e.name}):
        #{Exception.message(err)}
        """

    end
  end
end
