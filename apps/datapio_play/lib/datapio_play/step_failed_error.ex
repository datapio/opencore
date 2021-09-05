defmodule Datapio.Play.StepFailedError do
  @moduledoc """
  Error raised when a step execution failed.
  """

  defexception name: "step", info: []

  def message(e) do
    """
    Step(#{e.name}):
    #{inspect(e.info)}
    """
  end
end
