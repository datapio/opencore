defmodule Datapio.MQ.Queue do
  @moduledoc """
  Distributed in-memory queue with multiple consumers.
  """

  use GenServer
  require Logger

  @typedoc "Queue name"
  @type queue_name :: atom() | String.t()

  defstruct [:name, :queue, :sinks]

  defp via_tuple(queue_name) do
    name = "queue-#{queue_name}"
    {:via, Horde.Registry, {Datapio.MQ.Registry, name}}
  end

  @doc "Return a specification to run the queue under a supervisor"
  @spec child_spec(queue_name()) :: Supervisor.child_spec()
  def child_spec(queue_name \\ __MODULE__) do
    %{
      id: "#{__MODULE__}_#{queue_name}",
      start: {__MODULE__, :start_link, [queue_name]},
      restart: :transient
    }
  end

  @doc "Start a queue linked to the current process"
  @spec start_link(queue_name()) :: GenServer.on_start()
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

  @doc "Consume a message from the queue and stream it to the current process"
  @spec drain(queue_name()) :: :ok
  def drain(queue_name) do
    drain(queue_name, self())
  end

  @doc "Consume a message from the queue and stream it to the specified process"
  @spec drain(queue_name(), pid()) :: :ok
  def drain(queue_name, pid) do
    proc_name = via_tuple(queue_name)
    GenServer.call(proc_name, {:drain, pid})
  end

  @doc "Publish a message to the queue"
  @spec publish(queue_name(), any()) :: :ok
  def publish(queue_name, message) do
    proc_name = via_tuple(queue_name)
    GenServer.call(proc_name, {:publish, message})
  end

  @doc "Shutdown the queue"
  @spec shutdown(queue_name()) :: :ok
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
