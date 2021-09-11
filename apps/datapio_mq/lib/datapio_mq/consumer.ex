defmodule Datapio.MQ.Consumer do
  @moduledoc """
  Distributed queue consumer.
  """

  require Logger
  use GenServer

  @typedoc "Consumer Identifier"
  @type consumer_id :: atom() | String.t() | pos_integer()

  @typedoc "Available consumer option"
  @type consumer_option ::
    {:module, module()}
    | {:id, consumer_id()}
    | {:queue, String.t()}
    | {:data, any()}

  @typedoc "Consumer options"
  @type consumer_options() :: [consumer_option(), ...]

  @callback handle_message(term(), term()) :: :ack | :nack
  @callback handle_shutdown(term()) :: :ok

  defstruct [:module, :queue, :data]

  defmacro __using__(_opts) do
    quote do
      @behaviour Datapio.MQ.Consumer

      @doc "Return a specification to run the consumer under a supervisor"
      @spec child_spec(Datapio.MQ.Consumer.consumer_options()) :: Supervisor.child_spec()
      def child_spec(opts) do
        options = opts |> Keyword.merge([module: __MODULE__])
        Datapio.MQ.Consumer.child_spec(options)
      end

      @doc "Start a consumer linked to the current process"
      @spec start_link(Datapio.MQ.Consumer.consumer_options()) :: GenServer.on_start()
      def start_link(options) do
        Datapio.MQ.Consumer.start_link(options)
      end

      @doc "Shutdown the consumer"
      @spec shutdown(Datapio.MQ.Consumer.consumer_id()) :: :ok
      def shutdown(id) do
        Datapio.MQ.Consumer.shutdown(__MODULE__, id)
      end
    end
  end

  defp via_tuple(options) do
    module = options |> Keyword.fetch!(:module)
    id = options |> Keyword.fetch!(:id)

    name = "consumer-#{module}-#{id}"
    {:via, Horde.Registry, {Datapio.MQ.Registry, name}}
  end

  @doc "Return a specification to run the consumer under a supervisor"
  @spec child_spec(consumer_options()) :: Supervisor.child_spec()
  def child_spec(options) do
    module = options |> Keyword.fetch!(:module)
    id = options |> Keyword.fetch!(:id)

    %{
      id: "#{module}_#{id}",
      start: {module, :start_link, [options]},
      restart: :transient
    }
  end

  @doc "Start a consumer linked to the current process"
  @spec start_link(consumer_options()) :: GenServer.on_start()
  def start_link(options) do
    module = options |> Keyword.fetch!(:module)
    id = options |> Keyword.fetch!(:id)
    proc_name = via_tuple(options)

    case GenServer.start_link(__MODULE__, options, name: proc_name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("Consumer #{module}-#{id} already started at #{inspect(pid)}")
        :ignore
    end
  end

  @doc "Shutdown the consumer"
  @spec shutdown(module(), consumer_id()) :: :ok
  def shutdown(module, id) do
    proc_name = via_tuple([module: module, id: id])
    GenServer.cast(proc_name, :shutdown)
  end

  @impl true
  def init(options) do
    state = %Datapio.MQ.Consumer{
      module: options |> Keyword.fetch!(:module),
      queue: options |> Keyword.fetch!(:queue),
      data: options |> Keyword.get(:data, nil)
    }

    send(self(), :drain)
    {:ok, state}
  end

  @impl true
  def terminate(_reason, %Datapio.MQ.Consumer{} = state) do
    apply(state.module, :handle_shutdown, [state.data])
  end

  @impl true
  def handle_cast(:shutdown, %Datapio.MQ.Consumer{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:drain, %Datapio.MQ.Consumer{} = state) do
    :ok = Datapio.MQ.Queue.drain(state.queue)
    {:noreply, state}
  end

  @impl true
  def handle_info({:datapio_mq_consume, message}, %Datapio.MQ.Consumer{} = state) do
    :ok = case apply(state.module, :handle_message, [message, state.data]) do
      :nack ->
        # If the message was not acknowledged, re-publish it
        Datapio.MQ.Queue.publish(state.queue, message)

      :ack ->
        :ok
    end

    send(self(), :drain)
    {:noreply, state}
  end

  @impl true
  def handle_info(:datapio_mq_shutdown, %Datapio.MQ.Consumer{} = state) do
    {:stop, :normal, state}
  end
end
