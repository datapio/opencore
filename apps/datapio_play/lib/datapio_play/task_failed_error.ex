defmodule Datapio.Play.TaskFailedError do
  @moduledoc """
  Error raised when a task execution failed.
  """

  defexception name: "task", with: nil
end
