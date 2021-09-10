defmodule ProjectOperator.Resources.PipelineRunServers do
  @moduledoc false

  def from_project(project) do
    %{"metadata" => project_meta, "spec" => project_spec} = project
    %{"namespace" => namespace, "name" => name, "uid" => uid} = project_meta
    %{"webhooks" => webhooks} = project_spec

    webhooks |> Enum.map(fn webhook ->
      %{
        "apiVersion" => "datapio.co/v1",
        "kind" => "PipelineRunServer",
        "metadata" => %{
          "name" => "datapio-pipeline-#{name}-#{webhook["name"]}",
          "namespace" => namespace,
          "ownerReferences" => [
            %{
              "apiVersion" => "datapio.co/v1",
              "kind" => "Project",
              "name" => name,
              "uid" => uid
            }
          ]
        },
        "spec" => %{
          "maxConcurrentJobs" => webhook["maxConcurrentJobs"],
          "history" => webhook["history"]
        }
      }
    end)
  end
end
