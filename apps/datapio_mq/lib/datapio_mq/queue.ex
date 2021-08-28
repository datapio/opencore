defmodule Datapio.MQ.Queue do
  @moduledoc """
  Distributed in-memory queue with multiple consumers.
  """

  use GenServer
  require Logger

  defstruct [:name, :queue, :sinks]

  defp via_tuple(queue_name) do
    name = "queue-#{queue_name}"
    {:via, Horde.Registry, {Datapio.MQ.Registry, name}}
  end

  def child_spec(opts) do
    queue_name = case opts do
      [] -> __MODULE__
      [name] -> name
    end

    %{
      id: "#{__MODULE__}_#{queue_name}",
      start: {__MODULE__, :start_link, [queue_name]},
      restart: :transient
    }
  end

  def start_link(queue_name) do
    proc_name = via_tuple(queue_name)

    case GenServer.start_link(__MODULE__, queue_name, name: proc_name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("Queue #{queue_name} already started at #{inspect(pid)}")
        :ignore
    end
  end

  def drain(queue_name) do
    drain(queue_name, self())
  end

  def drain(queue_name, pid) do
    proc_name = via_tuple(queue_name)
    GenServer.call(proc_name, {:drain, pid})
  end

  def publish(queue_name, message) do
    proc_name = via_tuple(queue_name)
    GenServer.call(proc_name, {:publish, message})
  end

  def shutdown(queue_name) do
    proc_name = via_tuple(queue_name)
    GenServer.cast(proc_name, :shutdown)
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
        sink = Task.async(fn -> sink_handler(pid) end)

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

        case Task.await(sink) do
          :ok ->
            # If the sink successfully consumed the message, remove the sink
            {:reply, :ok, %__MODULE__{state | sinks: sinks}}

          _ ->
            # If the sink was not alive, enqueue the message and remove the sink
            new_queue = state.queue ++ [message]
            {:reply, :ok, %__MODULE__{state | queue: new_queue, sinks: sinks}}
        end
    end
  end

  @impl true
  def handle_cast(:shutdown, %__MODULE__{} = state) do
    state.sinks |> Enum.each(fn sink ->
      send(sink.pid, :shutdown)
      :stopped = Task.await(sink)
    end)

    {:stop, :normal, %__MODULE__{state | sinks: []}}
  end

  defp sink_handler(pid) do
    receive do
      {:ok, message} ->
        if Process.alive?(pid) do
          send(pid, {:datapio_mq_consume, message})
          :ok
        else
          :dead
        end

      :shutdown ->
        if Process.alive?(pid) do
          send(pid, :datapio_mq_shutdown)
        end

        :stopped
    end
  end
end
