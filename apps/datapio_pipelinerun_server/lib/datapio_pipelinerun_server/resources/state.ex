defmodule DatapioPipelineRunServer.Resources.State do
  @moduledoc """
  Handle convergence of Kubernetes observed state towards desired state
  """

  alias Datapio.Dependencies, as: Deps

  def apply(resources) do
    client = Deps.get(:k8s_client)
    {:ok, conn} = Datapio.K8sConn.lookup()

    results = observe(resources, [])
      |> then(&(client.async(conn, &1)))

    resources
      |> Stream.zip(results)
      |> Enum.map(&reconcile_resource/1)
      |> then(&(client.async(conn, &1)))
      |> Enum.all?(fn
        {:ok, _} -> true
        {:error, _} -> false
      end)
  end

  defp observe([], operations), do: operations
  defp observe([resource | resources], operations) do
    %{
      "apiVersion" => api_version,
      "kind" => kind,
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      }
    } = resource

    selector = [namespace: namespace, name: name]
    op = Deps.get(:k8s_client).get(api_version, kind, selector)

    observe(resources, [op | operations])
  end

  defp reconcile_resource({resource, {:ok, _}}) do
    Deps.get(:k8s_client).patch(resource)
  end
  defp reconcile_resource({resource, {:error, _}}) do
    Deps.get(:l8s_client).create(resource)
  end
end
