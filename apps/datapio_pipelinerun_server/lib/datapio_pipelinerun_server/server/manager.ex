defmodule DatapioPipelineRunServer.Server.Manager do
  @moduledoc """
  Consume
  """

  use GenServer, restart: :transient

  defstruct [:name, :workers]

  def start_link(server_name) do
    name = via_tuple(server_name)

    case GenServer.start_link(__MODULE__, [server_name], name: name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  def configure(server_name, options) do
    GenServer.call(via_tuple(server_name), {:configure, options})
  end

  def shutdown(server_name) do
    GenServer.cast(via_tuple(server_name), :shutdown)
  end

  defp via_tuple(server_name) do
    name = "server-#{server_name}"
    {:via, Horde.Registry, {DatapioPipelineRunServer.Server.Registry, name}}
  end

  @impl true
  def init(server_name) do
    Datapio.MQ.start_queue(server_name)

    {:ok, %__MODULE__{
      name: server_name,
      workers: 1
    }}
  end

  @impl true
  def terminate(_reason, %__MODULE__{} = state) do
    Datapio.MQ.Queue.shutdown(state.name)
    :ok
  end

  @impl true
  def handle_call({:configure, options}, _from, %__MODULE__{} = state) do
    old_worker_count = state.workers
    new_worker_count = options[:workers]

    errors = cond do
      old_worker_count < new_worker_count ->
        new_worker_ids = Enum.to_list(old_worker_count..new_worker_count)
        schedule_workers(state.name, options[:history], new_worker_ids)

      new_worker_count > old_worker_count ->
        old_worker_ids = Enum.to_list(new_worker_count..old_worker_count)
        shutdown_workers(state.name, old_worker_ids)

      new_worker_count == old_worker_count ->
        []
    end

    resp = case errors do
      [] -> :ok
      reasons -> {:error, reasons}
    end

    {:reply, resp, %__MODULE__{state | workers: new_worker_count}}
  end

  @impl true
  def handle_cast(:shutdown, %__MODULE__{} = state) do
    {:stop, :normal, state}
  end

  defp schedule_workers(server_name, history, worker_ids) do
    schedule_workers(server_name, history, worker_ids, [])
  end

  defp schedule_workers(server_name, history, [], errors), do: errors
  defp schedule_workers(server_name, history, [worker_id | worker_ids], errors) do
    opts = [
      module: DatapioPipelineRunServer.Worker,
      queue: server_name,
      data: [history: history]
    ]

    errors = case Datapio.MQ.start_consumer(opts) do
      {:ok, _pid} -> errors,
      :ignored -> errors,
      {:error, reason} -> [reason | errors]
    end

    schedule_workers(server_name, history, worker_ids, errors)
  end

  defp shutdown_workers(server_name, worker_ids) do
    shutdown_workers(server_name, worker_ids, [])
  end

  defp shutdown_workers(server_name, [], errors), do: errors
  defp shutdown_workers(server_name, [worker_id | worker_ids], errors) do
    resp = DatapioPipelineRunServer.Worker.shutdown(worker_id)
    errors = case resp do
      :ok -> errors
      {:error, reason} -> [reason | errors]
    end

    shutdown_workers(server_name, worker_ids, errors)
  end
end
