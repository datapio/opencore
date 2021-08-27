defmodule Datapio.MQ.Consumer do
  @callback handle_message(term(), term()) :: :ack | :nack
  @callback handle_shutdown(term()) :: :ok

  defstruct [:queue, :data]

  defmacro __using__(_opts) do
    quote do
      use GenServer, restart: :transient

      @behaviour Datapio.MQ.Consumer

      def start_link(options) do
        GenServer.start_link(__MODULE__, options, name: __MODULE__)
      end

      @impl true
      def init(options) do
        state = %Datapio.MQ.Consumer{
          queue: options |> Keyword.fetch!(:queue),
          data: options |> Keyword.get(:data, nil)
        }

        send(self(), :drain)
        {:ok, state}
      end

      @impl true
      def handle_info(:drain, %Datapio.MQ.Consumer{} = state) do
        :ok = Datapio.MQ.Queue.drain(state.queue)
        {:noreply, state}
      end

      @impl true
      def handle_info({:datapio_mq_consume, message}, %Datapio.MQ.Consumer{} = state) do
        :ok = case apply(__MODULE__, :handle_message, [message, state.data]) do
          :ack ->
            :ok

          :nack ->
            Datapio.MQ.Queue.publish(state.queue, message)
        end

        send(self(), :drain)
        {:noreply, state}
      end

      @impl true
      def handle_info(:datapio_mq_shutdown, %Datapio.MQ.Consumer{} = state) do
        :ok = apply(__MODULE__, :handle_shutdown, [state.data])
        {:stop, :normal, state}
      end
    end
  end
end
