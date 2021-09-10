defmodule ProjectOperator.Resources.TriggerTemplates do
  @moduledoc false

  def from_project(project) do
    %{"metadata" => project_meta, "spec" => project_spec} = project
    %{"namespace" => namespace, "name" => name, "uid" => uid} = project_meta
    %{"webhooks" => webhooks} = project_spec

    webhooks |> Enum.map(fn webhook ->
      %{
        "apiVersion" => "triggers.tekton.dev/v1alpha1",
        "kind" => "TriggerTemplate",
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
          "params" => [
            %{"name" => "revision"},
            %{"name" => "url"}
          ],
          "resourcetemplates" => [
            get_pipelinerun_request_template(name, webhook)
          ]
        }
      }
    end)
  end


  defp get_pipelinerun_request_template(name, webhook) do
    %{
      "apiVersion" => "datapio.co/v1",
      "kind" => "PipelineRunRequest",
      "spec" => %{
        "pipeline" => "datapio-pipeline-#{name}",
        "server" => "datapio-pipeline-#{name}-#{webhook["name"]}",
        "resources" => [
          %{
            "name" => "workspace",
            "resourceSpec" => %{
              "type" => "git",
              "params" => [
                %{
                  "name" => "revision",
                  "value" => "$(tt.params.revision)"
                },
                %{
                  "name" => "url",
                  "value" => "$(tt.params.url)"
                }
              ]
            }
          }
        ]
      }
    }
  end
end
