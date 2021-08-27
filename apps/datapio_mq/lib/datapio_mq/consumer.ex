defmodule Datapio.MQ.Consumer do
  @callback handle_message(term()) :: :ack | :nack
  @callback handle_shutdown() :: :ok

  defmacro __using__(opts) do
    queue_name = opts |> Keyword.fetch!(:queue)

    quote do
      use GenServer, restart: :transient

      @behavior Datapio.MQ.Consumer

      def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
      end

      @impl true
      def init(_args) do
        send(self(), :drain)
        {:ok, unquote(queue_name)}
      end

      @impl true
      def handle_info(:drain, queue_name) do
        :ok = Datapio.MQ.drain(queue_name)
        {:noreply, queue_name}
      end

      @impl true
      def handle_info({:datapio_mq_consume, message}, queue_name) do
        case apply(__MODULE__, :handle_message, [message]) do
          :ack ->
            :ok

          :nack ->
            Datapio.MQ.publish(queue_name, message)
        end
        send(self(), :drain)
        {:noreply, queue_name}
      end

      @impl true
      def handle_info(:datapio_mq_shutdown, queue_name) do
        :ok = apply(__MODULE__, :handle_shutdown, [])
        {:stop, :normal, queue_name}
      end
    end
  end
end
