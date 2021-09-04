defmodule Datapio.Play.TaskFailed do
  @moduledoc """
  Error raised when a task execution failed.
  """

  defexception name: "task", with: nil

  def message(e) do
    "Task '#{e.name}' failed with error: #{Exception.message(e.with)}"
  end
end
