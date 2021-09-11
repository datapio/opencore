defmodule ProjectOperator.Resources.Ingress do
  @moduledoc false

  @spec from_project(Datapio.K8s.Resource.t()) :: [Datapio.K8s.Resource.t()]
  def from_project(%{"spec" => %{"ingress" => %{"enabled" => true}}} = project) do
    %{"metadata" => project_meta, "spec" => project_spec} = project
    %{"namespace" => namespace, "name" => name, "uid" => uid} = project_meta
    %{"ingress" => ingress_config, "webhooks" => webhooks} = project_spec

    [
      %{
        "apiVersion" => "networking.k8s.io/v1",
        "kind" => "Ingress",
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
          ],
          "labels" => ingress_config |> Map.get("labels", %{}),
          "annotations" => ingress_config |> Map.get("annotations", %{})
        },
        "spec" => %{
          "rules" => [
            %{
              "host" => ingress_config["host"],
              "http" => %{
                "paths" => webhooks |> Enum.map(fn webhook ->
                  %{
                    "path" => "/#{webhook["name"]}/",
                    "pathType" => "Prefix",
                    "backend" => %{
                      "service" => %{
                        "name" => "el-datapio-pipeline-#{name}-#{webhook["name"]}",
                        "port" => %{
                          "number" => 8080
                        }
                      }
                    }
                  }
                end)
              }
            }
          ]
        } |> Map.merge(case ingress_config["tls"] do
          nil ->
            %{}

          false ->
            %{}

          secret_name ->
            %{
              "tls" => [
                %{
                  "hosts" => [ingress_config["host"]],
                  "secretName" => secret_name
                }
              ]
            }
        end)
      }
    ]
  end

  def from_project(_project), do: []
end
