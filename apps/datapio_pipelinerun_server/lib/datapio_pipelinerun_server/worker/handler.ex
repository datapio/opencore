defmodule DatapioPipelineRunServer.Worker.Handler do
  @moduledoc """
  Consume
  """

  use GenServer, restart: :transient

  defstruct [:tag, :history]

  def start_link(options) do
    name = via_tuple(options)

    case GenServer.start_link(__MODULE__, [options], name: name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  def shutdown(server_name, worker_id) do
    name = via_tuple([server_name: server_name, worker_id: worker_id])
    GenServer.cast(name, :shutdown)
  end

  defp via_tuple(options) do
    server_name = options[:server_name]
    worker_id = options[:worker_id]

    name = "worker-#{server_name}-#{worker_id}"
    {:via, Horde.Registry, {DatapioPipelineRunServer.Worker.Registry, name}}
  end

  @impl true
  def init(options) do
    queue = options[:queue]
    history = options[:history]

    case DatapioPipelineRunServer.Exchange.Manager.setup_worker(queue, self()) do
      :ok -> {:ok, %__MODULE__{tag: nil, history: history}}
      err -> err
    end
  end

  @impl true
  def handle_cast(:shutdown, %__MODULE__{} = state) do
    case state.tag do
      nil -> {:noreply, state}
      tag ->
        DatapioPipelineRunServer.Exchange.Manager.shutdown_worker(tag)
        {:noreply, %__MODULE__{state | tag: nil}}
    end
  end

  @impl true
  def handle_info({:basic_consume_ok, %{consumer_tag: tag}}, %__MODULE__{} = state) do
    {:noreply, %__MODULE__{state | tag: tag}}
  end

  @impl true
  def handle_info({:basic_cancel, _}, %__MODULE__{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:basic_cancel_ok, _}, %__MODULE__{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:basic_deliver, payload, _meta}, %__MODULE__{} = state) do
    case Jason.decode(payload) do
      {:ok, request} ->
        handle_request(request)
        archive_requests(state.history)

      err -> :ok
    end

    {:noreply, state}
  end
end
