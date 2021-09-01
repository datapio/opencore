defmodule DatapioPipelineRunServer.Resources.PipelineRun do
  @moduledoc """
  Utility functions related to PipelineRun resources
  """

  def completed?(pipelinerun) do
    completionTime = pipelinerun
      |> Map.get("status", %{})
      |> Map.get("completionTime", nil)

    case completionTime do
      nil -> false
      _ -> true
    end
  end
end
