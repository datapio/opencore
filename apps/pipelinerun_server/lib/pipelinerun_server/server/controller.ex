defmodule PipelineRunServer.Server.Controller do
  @moduledoc """
  Observe PipelineRunServer resources.
  """

  alias PipelineRunServer.Server.Pool

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: "PipelineRunServer",
    schema: %{}

  @impl true
  def add(%{} = server, options) do
    reconcile(server, options)
  end

  @impl true
  def modify(%{} = server, options) do
    reconcile(server, options)
  end

  @impl true
  def delete(%{} = server, _options) do
    case with_resource(server, &shutdown_server/1) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def reconcile(%{} = server, _options) do
    case with_resource(server, &configure_server/1) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp get_server_name(server) do
    namespace = server["metadata"]["namespace"]
    name = server["metadata"]["name"]
    "#{namespace}.#{name}"
  end

  defp configure_server(server) do
    worker_count = server["spec"]["max_concurrent_jobs"]
    history = server["spec"]["history"]

    Pool.configure_server(get_server_name(server), [
      workers: worker_count,
      history: history
    ])
  end

  defp shutdown_server(server) do
    Pool.shutdown_server(get_server_name(server))
  end
end
