defmodule DatapioPipelineRunServer.Exchange.Manager do
  @moduledoc """
  Handle interactions with the worker pool and RabbitMQ.
  """

  import DatapioPipelineRunServer.Exchange.Utilities
  alias Datapio.Dependencies, as: Deps

  use GenServer

  defstruct [
    :conn,
    :chan
  ]

  def start_link(options) do
    GenServer.start_link(__MODULE__, [options], name: __MODULE__)
  end

  def setup_server(server_name) do
    GenServer.call(__MODULE__, {:setup_server, server_name})
  end

  def shutdown_server(queue_name) do
    GenServer.call(__MODULE__, {:shutdown_server, queue_name})
  end

  def setup_worker(queue_name, worker_pid) do
    GenServer.call(__MODULE__, {:setup_worker, queue_name, worker_pid})
  end

  def shutdown_worker(consumer_tag) do
    GenServer.cast(__MODULE__, {:shutdown_worker, consumer_tag})
  end

  def send_request(request) do
    GenServer.call(__MODULE__, {:send_request, request})
  end

  @impl true
  def init(_args) do
    {:ok, connection} = Deps.get(:amqp_conn).open(get_rabbitmq_url())
    {:ok, channel} = Deps.get(:amqp_channel).open(connection)
    :ok = Deps.get(:amqp_exchange).declare(get_exchange_name(), :direct)

    {:ok, %__MODULE__{
      conn: connection,
      chan: channel
    }}
  end

  @impl true
  def terminate(_reason, %__MODULE__{} = state) do
    :ok = state.chan |> Deps.get(:amqp_channel).close()
    :ok = state.conn |> Deps.get(:amqp_conn).close()
  end

  @impl true
  def handle_call({:setup_server, server_name}, _from, %__MODULE__{} = state) do
    with {:ok, queue_name} <- declare_queue(state.chan),
         :ok <- bind_queue(state.chan, queue_name, server_name)
    do
      {:reply, {:ok, queue_name}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:shutdown_server, queue_name}, _from, %__MODULE__{} = state) do
    {:reply, delete_queue(state.chan, queue_name), state}
  end

  @impl true
  def handle_call({:setup_worker, queue, worker_pid}, _from, %__MODULE__{} = state) do
    {:reply, start_consumer(state.chan, queue, worker_pid), state}
  end

  @impl true
  def handle_cast({:shutdown_worker, consumer_tag}, %__MODULE__{} = state) do
    stop_consumer(state.chan, consumer_tag)
    {:noreply, state}
  end

  @impl true
  def handle_call({:send_request, request}, _from, %__MODULE__{} = state) do
    server_name = "#{request["metadata"]["namespace"]}.#{request["spec"]["server"]}"

    with {:ok, payload} <- request_to_json(request),
         :ok <- publish_request(state.chan, server_name, payload)
    do
      {:reply, :ok, state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
end
