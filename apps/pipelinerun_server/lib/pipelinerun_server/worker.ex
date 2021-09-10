defmodule PipelineRunServer.Worker do
  @moduledoc """
  Consume PipelineRunRequest from queues.
  """

  alias PipelineRunServer.Resources.PipelineRun
  alias PipelineRunServer.Resources.Request
  alias PipelineRunServer.Resources.State

  use Datapio.MQ.Consumer
  require Logger

  @impl true
  def handle_message(request, options) do
    handle_request(Request.get_status(request), request, options)
  end

  @impl true
  def handle_shutdown(_options) do
    :ok
  end

  defp handle_request(:completed, _request, _options), do: :ack
  defp handle_request(:pending, _request, _options), do: :ack
  defp handle_request(:unscheduled, request, options) do
    %{
      "metadata" => %{"name" => name, "namespace" => namespace},
      "spec" => %{"pipeline" => pipeline, "runSpecTemplate" => template}
    } = request

    extra_resources = request["spec"] |> Map.get("extraResources", [])

    pipelinerun = PipelineRun.from_template(template, [
      owner: request,
      name: name,
      namespace: namespace,
      pipeline: pipeline
    ])

    with true <- State.apply(extra_resources),
         :ok <- run_pipeline(pipelinerun),
         :ok <- archive_request(request, options[:history])
    do
      :ack
    else
      false ->
        Logger.error([
          event: "request",
          scope: "worker",
          reason: "Failed to apply extra resources"
        ])
        :nack

      {:error, {:runner, reason}} ->
        Logger.error([
          event: "request",
          scope: "worker",
          reason: {:runner, reason}
        ])
        :nack

      {:error, {:archiver, reason}} ->
        Logger.error([
          event: "request",
          scope: "worker",
          reason: {:archiver, reason}
        ])
        :ack
    end
  end

  defp run_pipeline(pipelinerun) do
    case State.apply([pipelinerun]) do
      false -> {:error, {:runner, "Failed to apply PipelineRun"}}
      true -> wait_for_pipeline(pipelinerun)
    end
  end

  defp wait_for_pipeline(pipelinerun) do
    {:ok, conn} = Datapio.K8s.Conn.lookup()

    %{
      "apiVersion" => api_version,
      "kind" => kind,
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      }
    } = pipelinerun

    selector = [namespace: namespace, name: name]
    operation = K8s.Client.get(api_version, kind, selector)
    wait_opts = [
      find: ["status", "completionTime"],
      eval: fn
        nil -> false
        _ -> true
      end,
      timeout: 60
    ]

    case client.wait(conn, operation, wait_opts) do
      {:ok, _} ->
        :ok

      {:error, :timeout} ->
        wait_for_pipeline(pipelinerun)

      {:error, reason} ->
        {:error, {:runner, reason}}
    end
  end

  defp archive_request(_request, _history) do
    {:error, {:archiver, "Not implemented"}}
  end
end
