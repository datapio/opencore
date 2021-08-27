defmodule Datapio.MQ.Queue do
  @moduledoc """
  Distributed in-memory queue with multiple consumers.
  """

  use GenServer, restart: :transient
  require Logger

  defstruct [:name, :queue, :sinks]

  defp via_tuple(exchange_name, queue_name) do
    registry_name = Module.concat(exchange_name, Registry)
    {:via, Horde.Registry, {registry_name, queue_name}}
  end

  def start_link(exchange_name, queue_name) do
    proc_name = via_tuple(exchange_name, queue_name)

    case GenServer.start_link(__MODULE__, queue_name, name: proc_name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("Queue #{queue_name} already started at #{inspect(pid)}")
        :ignore
    end
  end

  def drain(exchange_name, queue_name, nil) do
    drain(exchange_name, queue_name, self())
  end

  def drain(exchange_name, queue_name, pid) do
    proc_name = via_tuple(exchange_name, queue_name)
    GenServer.call(proc_name, queue_name, {:drain, pid})
  end

  def publish(exchange_name, queue_name, message) do
    proc_name = via_tuple(exchange_name, queue_name)
    GenServer.call(proc_name, {:publish, message})
  end

  def shutdown(exchange_name, queue_name) do
    proc_name = via_tuple(exchange_name, queue_name)
    GenServer.call(proc_name, :shutdown)
  end

  @impl true
  def init(queue_name) do
    {:ok, %__MODULE__{
      name: queue_name,
      queue: [],
      sinks: []
    }}
  end

  @impl true
  def terminate(reason, %__MODULE__{} = state) do
    case state.queue do
      [] -> :ok
      queue ->
        count = queue |> Enum.count()
        Logger.warning("Queue #{state.name} stopped (#{reason}) with #{count} messages remaining.")
        :ok
    end
  end

  @impl true
  def handle_call({:drain, pid}, _from, %__MODULE__{} = state) do
    case state.queue do
      [] ->
        # If no message in queue, wait for a message
        sink = Task.async(fn ->
          receive do
            {:ok, message} ->
              send(pid, {:datapio_mq_consume, message})
              :ok

            :shutdown ->
              send(pid, :datapio_mq_shutdown)
              :stopped
          end
        end)

        {:reply, :ok, %__MODULE__{state | sinks: state.sinks ++ [sink]}}

      [message | queue] ->
        # If messages are available, send it as soon as possible
        send(pid, {:datapio_mq_consume, message})
        {:reply, :ok, %__MODULE__{state | queue: queue}}
    end
  end

  @impl true
  def handle_call({:publish, message}, _from, %__MODULE__{} = state) do
    case state.sinks do
      [] ->
        # If no sink is available, enqueue the message
        {:reply, :ok, %__MODULE__{state | queue: state.queue ++ [message]}}

      [sink | sinks] ->
        # If there is a sink, waiting for a message, forward it as soon as possible
        send(sink.pid, {:ok, message})
        result = Task.await(sink)
        {:reply, result, %__MODULE__{state | sinks: sinks}}
    end
  end

  @impl true
  def handle_call(:shutdown, _from, %__MODULE__{} = state) do
    state.sinks |> Enum.each(fn sink ->
      send(sink.pid, :shutdown)
      :stopped = Task.await(sink)
    end)

    {:stop, :normal, %__MODULE__{state | sinks: []}}
  end
end
