defmodule DatapioProjectOperator.Resources.EventListeners do
  @moduledoc false

  def from_project(project) do
    %{"metadata" => project_meta, "spec" => project_spec} = project
    %{"namespace" => namespace, "name" => name, "uid" => uid} = project_meta
    %{"webhooks" => webhooks} = project_spec

    webhooks |> Enum.map(fn webhook ->
      %{
        "apiVersion" => "triggers.tekton.dev/v1alpha1",
        "kind" => "EventListener",
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
          "serviceAccountName" => webhook["serviceAccount"],
          "triggers" => [
            %{
              "name" => "on-commit",
              "interceptors" => [
                %{
                  "github" => %{
                    "secretRef" => webhook["githubSecret"]["name"],
                    "secretKey" => webhook["githubSecret"]["key"]
                  },
                  "eventTypes" => [
                    "push",
                    "pull_request"
                  ]
                }
              ],
              "bindings" => [
                %{"ref" => "datapio-pipeline-#{name}-github"}
              ],
              "templates" => [
                %{"ref" => "datapio-pipeline-#{name}-#{webhook["name"]}"}
              ]
            }
          ]
        }
      }
    end)
  end
end
