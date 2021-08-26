defmodule DatapioPipelineRunServer.Scheduler.Worker.Handler do
  @moduledoc """
  Consume
  """

  use GenServer, restart: :transient

  defstruct [:name, :queue, :workers]

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
    GenServer.call(via_tuple(server_name), :shutdown)
  end

  defp via_tuple(server_name) do
    name = "server-#{server_name}"
    {:via, Horde.Registry, {DatapioPipelineRunServer.Server.Registry, name}}
  end

  @impl true
  def init(server_name) do
    case DatapioPipelineRunServer.Exchange.Manager.setup_server(server_name) do
      {:ok, queue} ->
        {:ok, %__MODULE__{
          name: server_name,
          queue: queue,
          workers: 1
        }}

      err ->
        err
    end
  end

  @impl true
  def terminate(_reason, %__MODULE__{} = state) do
    worker_count = state.workers

    Enum.to_list(1..worker_count)
      |> Enum.each(&shutdown_worker(state.name, &1))

    DatapioPipelineRunServer.Exchange.Manager.shutdown_server(state.queue)

    :ok
  end

  @impl true
  def handle_call({:configure, options}, _from, %__MODULE__{} = state) do
    old_worker_count = state.workers
    new_worker_count = options[:workers]

    resps = cond do
      old_worker_count < new_worker_count ->
        Enum.to_list(old_worker_count..new_worker_count)
          |> Stream.map(&schedule_worker([
            server_name: state.name,
            queue_name: state.queue,
            history: options[:history],
            id: &1
          ]))

      new_worker_count > old_worker_count ->
        Enum.to_list(new_worker_count..old_worker_count)
          |> Stream.map(&shutdown_worker(state.name, &1))

      old_worker_count == new_worker_count ->
        []
    end

    new_state = %__MODULE__{state | workers: new_worker_count}
    errors = resps
      |> Stream.filter(fn
        :ok -> false,
        _ -> true
      end)
      |> Enum.map(fn {:error, reason} -> reason end)

    case errors do
      [] -> {:reply, :ok, new_state}
      reasons -> {:reply, {:error, reasons}, new_state}
    end
  end

  @impl true
  def handle_call(:shutdown, _from, %__MODULE__{} = state) do
    {:stop, :normal, state}
  end

  defp schedule_worker(options) do
    DatapioPipelineRunServer.Worker.Pool.start_worker([
      server_name: options[:server_name],
      worker_id: options[:id],
      history: options[:history]
    ])
  end

  defp shutdown_worker(server_name, worker_id) do
    DatapioPipelineRunServer.Worker.Pool.shutdown_worker(server_name, worker_id)
  end
end
