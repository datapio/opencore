defmodule ProjectOperator.Resources.Pipeline do
  @moduledoc false

  defp klifter_image do
    System.get_env("DATAPIO_KLIFTER_IMAGE", "ghcr.io/datapio/klifter:latest")
  end

  @spec from_project(Datapio.K8s.Resource.t()) :: [Datapio.K8s.Resource.t()]
  def from_project(project) do
    %{"namespace" => namespace, "name" => name, "uid" => uid} = project["metadata"]

    [
      %{
        "apiVersion" => "tekton.dev/v1alpha1",
        "kind" => "Pipeline",
        "metadata" => %{
          "name" => "datapio-pipeline-#{name}",
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
          "resources" => [
            %{
              "name" => "workspace",
              "type" => "git"
            }
          ],
          "tasks" => [get_klifter_task()]
        }
      }
    ]
  end

  defp get_klifter_task do
    %{
      "name" => "klifter",
      "resources" => %{
        "inputs" => [
          %{
            "name" => "workspace",
            "resource" => "workspace"
          }
        ]
      },
      "taskSpec" => %{
        "resources" => %{
          "inputs" => [
            %{
              "name" => "workspace",
              "type" => "git"
            }
          ]
        },
        "steps" => [
          %{
            "name" => "run-klifter",
            "image" => klifter_image(),
            "env" => [
              %{
                "name" => "K8S_STATE_SOURCE_KIND",
                "value" => "local"
              },
              %{
                "name" => "K8S_STATE_SOURCE_LOCAL_DIR",
                "value" => "$(resources.inputs.workspace.path)/.datapio"
              }
            ]
          }
        ]
      }
    }
  end
end
