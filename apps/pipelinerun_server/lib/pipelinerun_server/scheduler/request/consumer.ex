defmodule PipelineRunServer.Scheduler.Request.Consumer do
  @moduledoc false

  use Datapio.MQ.Consumer
  require Logger

  alias PipelineRunServer.Resources
  alias PipelineRunServer.Archiver

  @impl true
  def handle_message(request, server) do
    {:ok, conn} = Datapio.K8s.Conn.lookup()

    pipelinerun = Resources.PipelineRun.from_request(request)

    extra_resources = request["spec"]
      |> Map.get("extraResources", [])
      |> Enum.map(&Datapio.K8s.Resource.has_owner(&1, request))

    with :ok <- create_resources(conn, extra_resources),
         {:ok, final_pipelinerun} <- run_pipeline(conn, pipelinerun),
         :ok <- Archiver.process(server, final_pipelinerun)
    do
      :ack

    else
      {:error, reason} ->
        Logger.error([
          message: "Failed to run pipeline",
          namespace: server["metadata"]["namespace"],
          server: server["metadata"]["name"],
          request: request["metadata"]["name"],
          reason: reason
        ])

        :nack
    end
  end

  @impl true
  def handle_shutdown(_server) do
    :ok
  end

  defp create_resources(conn, resources) do
    resources
      |> Enum.map(&K8s.Client.create/1)
      |> then(&K8s.Client.async(conn, &1))
      |> Enum.filter(fn {status, _} -> status == :error end)
      |> Enum.map(fn {:error, reason} -> reason end)
      |> then(fn
        [] -> :ok
        reasons -> {:error, reasons}
      end)
  end

  defp run_pipeline(conn, pipelinerun) do
    case create_resources(conn, [pipelinerun]) do
      :ok ->
        wait_for_pipeline(conn, pipelinerun)
      err ->
        err
    end
  end

  defp wait_for_pipeline(conn, pipelinerun) do
    %{
      "apiVersion" => api_version,
      "kind" => kind,
      "metadata" => %{
        "namespace" => namespace,
        "name" => name
      }
    } = pipelinerun

    op = K8s.Client.get(api_version, kind, namespace: namespace, name: name)
    wait_opts = [
      find: ["status", "completionTime"],
      eval: fn
        nil -> false
        _ -> true
      end
    ]

    case K8s.Client.wait_until(conn, op, wait_opts) do
      {:ok, final_pipelinerun} ->
        {:ok, final_pipelinerun}

      {:error, :timeout} ->
        wait_for_pipeline(conn, pipelinerun)

      err ->
        err
    end
  end
end
