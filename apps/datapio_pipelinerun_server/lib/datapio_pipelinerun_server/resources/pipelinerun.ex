defmodule DatapioPipelineRunServer.Resources.PipelineRun do
  @moduledoc """
  Utility functions related to PipelineRun resources
  """

  def completed?(pipelinerun) do
    completion_time = pipelinerun
      |> Map.get("status", %{})
      |> Map.get("completionTime", nil)

    case completion_time do
      nil -> false
      _ -> true
    end
  end
end
