defmodule ProjectOperator.Resources.TriggerBinding do
  @moduledoc false

  def from_project(project) do
    %{"namespace" => namespace, "name" => name, "uid" => uid} = project["metadata"]

    %{
      "apiVersion" => "triggers.tekton.dev/v1alpha1",
      "kind" => "TriggerBinding",
      "metadata" => %{
        "name" => "datapio-pipeline-#{name}-github",
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
        "params" => [
          %{
            "name" => "revision",
            "value" => "$(body.head_commit.id)"
          },
          %{
            "name" => "url",
            "value" => "$(body.repository.url)"
          }
        ]
      }
    }
  end
end
