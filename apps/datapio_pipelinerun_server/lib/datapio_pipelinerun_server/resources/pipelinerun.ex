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

  def from_template(template, options) do
    owner = options |> Keyword.fetch!(:owner)
    name = options |> Keyword.fetch!(:name)
    namespace = options |> Keyword.fetch!(:namespace)
    pipeline = options |> Keyword.fetch!(:pipeline)

    %{
      "apiVersion" => "tekton.dev/v1alpha1",
      "kind" => "PipelineRun",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace,
        "ownerReferences" => [
          %{
            "apiVersion" => owner["apiVersion"],
            "kind" => owner["kind"],
            "name" => name,
            "uid" => owner["metadata"]["uid"]
          }
        ]
      },
      "spec" => template |> Map.merge(%{"pipelineRef" => %{"name" => pipeline}})
    }
  end
end
