defmodule PipelineRunServer.Scheduler.Server.Queue do
  @moduledoc false

  @spec ensure_started(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def ensure_started(server) do
    case Datapio.MQ.start_queue(queue_name_from_server(server)) do
      {:ok, _} -> :ok
      :ignore -> :ok
      err -> err
    end
  end

  @spec ensure_stopped(Datapio.K8s.Resource.t()) :: :ok
  def ensure_stopped(server) do
    Datapio.MQ.Queue.shutdown(queue_name_from_server(server))
  end

  @spec publish(Datapio.K8s.Resource.t()) :: :ok
  def publish(request) do
    Datapio.MQ.Queue.publish(queue_name_from_request(request), request)
  end

  @spec queue_name_from_server(Datapio.K8s.Resource.t()) :: String.t()
  def queue_name_from_server(server) do
    %{
      "metadata" => %{
        "namespace" => server_namespace,
        "name" => server_name
      }
    } = server
    queue_name(server_namespace, server_name)
  end

  @spec queue_name_from_request(Datapio.K8s.Resource.t()) :: String.t()
  def queue_name_from_request(request) do
    %{
      "metadata" => %{"namespace" => server_namespace},
      "spec" => %{"server" => server_name}
    } = request
    queue_name(server_namespace, server_name)
  end

  defp queue_name(server_namespace, server_name) do
    "pipelinerun-server-#{server_namespace}-#{server_name}"
  end
end
