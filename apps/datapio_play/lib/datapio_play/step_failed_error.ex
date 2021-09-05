defmodule Datapio.Play.StepFailedError do
  @moduledoc """
  Error raised when a step execution failed.
  """

  defexception name: "step", info: []
end
