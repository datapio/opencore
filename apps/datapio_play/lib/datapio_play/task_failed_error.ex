defmodule Datapio.Play.TaskFailedError do
  @moduledoc """
  Error raised when a task execution failed.
  """

  defexception name: "task", with: nil

  alias Datapio.Play.StepFailedError

  def message(e) do
    case e.with do
      %StepFailedError{} = err ->
        "Task(#{e.name}) > #{Exception.message(err)}"

      err ->
        """
        Task(#{e.name}):
        #{Exception.message(err)}
        """

    end
  end
end
