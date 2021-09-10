defmodule PipelineRunServer.Resources.State do
  @moduledoc """
  Handle convergence of Kubernetes observed state towards desired state
  """

  def apply(resources) do
    {:ok, conn} = Datapio.K8s.Conn.lookup()

    results = observe(resources, [])
      |> then(&(K8s.Client.async(conn, &1)))

    resources
      |> Stream.zip(results)
      |> Enum.map(&reconcile_resource/1)
      |> then(&(K8s.Client.async(conn, &1)))
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
    op = K8s.Client.get(api_version, kind, selector)

    observe(resources, [op | operations])
  end

  defp reconcile_resource({resource, {:ok, _}}) do
    K8s.Client.patch(resource)
  end
  defp reconcile_resource({resource, {:error, _}}) do
    K8s.Client.create(resource)
  end
end
