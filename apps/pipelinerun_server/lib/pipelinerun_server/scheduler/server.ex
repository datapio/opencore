defmodule PipelineRunServer.Scheduler.Server do
  @moduledoc false

  alias PipelineRunServer.Scheduler.Server
  alias PipelineRunServer.Scheduler.Request

  @spec configure(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def configure(server) do
    with :ok <- Server.Queue.ensure_started(server),
         :ok <- ensure_consumer_count(server)
    do
      :ok

    else
      err ->
        err
    end
  end

  @spec shutdown(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def shutdown(server) do
    :ok = Server.Queue.ensure_stopped(server)
    Server.Cache.clear(server)
  end

  @spec schedule(Datapio.K8s.Resource.t()) :: :ok
  def schedule(request) do
    Server.Queue.publish(request)
  end

  defp ensure_consumer_count(server) do
    %{"spec" => %{"max_concurrent_jobs" => new_count}} = server

    old_count_result = case Server.Cache.get(server) do
      :miss -> {:ok, 0}

      {:hit, old_server} ->
        %{"spec" => %{"max_concurrent_jobs" => count}} = old_server
        {:ok, count}

      err -> err
    end

    with :ok <- Server.Cache.put(server),
         {:ok, old_count} <- old_count_result,
         :ok <- ensure_consumer_count(server, new_count, old_count)
    do
      :ok

    else
      err -> err
    end
  end

  defp ensure_consumer_count(server, new_count, old_count) do
    cond do
      new_count > old_count ->
        start_consumers(server. old_count..new_count |> Enum.to_list())

      new_count < old_count ->
        stop_consumers(server, new_count..old_count |> Enum.to_list())

      new_count == old_count ->
        :ok
    end
  end

  defp start_consumers(_server, []), do: :ok
  defp start_consumers(server, [consumer_id | consumer_ids]) do
    consumer_opts = [
      module: Request.Consumer,
      id: consumer_name(server, consumer_id),
      queue: Server.Queue.queue_name_from_server(server),
      data: server
    ]

    case Datapio.MQ.start_consumer(consumer_opts) do
      {:ok, _} -> start_consumers(server, consumer_ids)
      :ignore -> start_consumers(server, consumer_ids)
      err -> err
    end
  end

  defp stop_consumers(_server, []), do: :ok
  defp stop_consumers(server, [consumer_id | consumer_ids]) do
    :ok = Request.Consumer.shutdown(consumer_name(server, consumer_id))
    stop_consumers(server, consumer_ids)
  end

  defp consumer_name(server, consumer_id) do
    %{
      "metadata" => %{
        "namespace" => server_namespace,
        "name" => server_name
      }
    } = server
    "pipelinerun-server-#{server_namespace}-#{server_name}-#{consumer_id}"
  end
end
