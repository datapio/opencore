defmodule PipelineRunServer.Archiver do
  @moduledoc false

  require Logger
  use GenServer

  @type resource :: Datapio.K8s.Resource.t()

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts], name: __MODULE__)
  end

  @spec process(resource(), resource()) :: :ok | {:error, term()}
  def process(server, pipelinerun) do
    GenServer.cast(__MODULE__, {:process, server, pipelinerun})
  end

  @impl true
  def init(_opts) do
    Datapio.K8s.Conn.lookup()
  end

  @impl true
  def handle_cast({:process, server, pipelinerun}, conn) do
    %{
      "apiVersion" => api_version,
      "kind" => kind,
      "metadata" => %{"namespace" => namespace},
      "status" => %{"completionTime" => completion_time}
    } = pipelinerun
    %{"spec" => %{"history" => history}} = server

    resp = K8s.Client.list(api_version, kind, namespace: namespace)
      |> then(&K8s.Client.run(conn, &1))             # Run LIST operation
      |> then(&extract_pipelineruns(namespace, &1))  # Log errors and always return list
      |> Enum.filter(&filter_by_completion_time/1)   # Filter-out unfinished pipelines
      |> Enum.sort(&sort_by_completion_time/2)       # Sort pipeline runs (newer first)
      |> Enum.slice(history + 1..-1)                 # Get oldest pipelines outside history window
      |> Enum.map(&delete_request/1)                 # Get DELETE operations
      |> then(&run_delete_operations(conn, &1))      # Run DELETE operations
      |> then(&parse_response/1)                     # Parse Kubernetes response to batch operations

    case resp do
      {:error, reason} ->
        Logger.warning([
          message: "Failed to archive request",
          namespace: server["metadata"]["namespace"],
          server: server["metadata"]["name"],
          request: request["metadata"]["name"],
          reason: reason
        ])

      _ ->
        :ok
    end

    {:noreply, conn}
  end

  defp extract_pipelineruns(_namespace, {:ok, items}), do: items
  defp extract_pipelineruns(namespace, {:error, reason}) do
    Logger.error([
      message: "Failed to list PipelineRun resources",
      namespace: namespace,
      reason: reason
    ])

    []
  end

  defp filter_by_completion_time(pipelinerun) do
    %{"status" => %{"completionTime" => completion_time}} = pipelinerun

    case completion_time do
      nil -> false
      _ -> true
    end
  end

  defp sort_by_completion_time(pipelinerun_a, pipelinerun_b) do
    %{"status" => %{"completionTime" => completion_time_a}} = pipelinerun_a
    %{"status" => %{"completionTime" => completion_time_b}} = pipelinerun_b

    dt_a = Date.from_iso8601!(completion_time_a)
    dt_b = Date.from_iso8601!(completion_time_b)

    case Date.compare(dt_a, dt_b) do
      :lt -> true
      :eq -> true
      :gt -> false
    end
  end

  defp delete_request(pipelinerun) do

  end
end
