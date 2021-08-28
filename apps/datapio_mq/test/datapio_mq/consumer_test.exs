defmodule DatapioTest.MQ.Consumer do
  use ExUnit.Case

  @queue DatapioTest.MQ.Consumer.ExampleQueue

  defmodule ExampleConsumer do
    use Datapio.MQ.Consumer

    @impl true
    def handle_message(msg, data) do
      case data[:ets] do
        nil ->
          send(data[:pid], {:received_message, msg})
          :ack

        table ->
          case :ets.lookup(table, :msg) do
            [] ->
              send(data[:pid], {:nack_message, msg})
              :ets.insert(table, {:msg, msg})
              :nack

            [{:msg, msg}] ->
              send(data[:pid], {:ack_message, msg})
              :ack
          end
      end
    end

    @impl true
    def handle_shutdown(%{pid: pid}) do
      send(pid, :received_shutdown)
    end
  end

  @tag capture_log: true
  setup do
    :ok = Application.stop(:datapio_mq)
    :ok = Application.start(:datapio_mq)
  end

  test "internal state" do
    state = %Datapio.MQ.Consumer{
      module: __MODULE__,
      queue: @queue,
      data: nil
    }

    assert state.module == __MODULE__
    assert state.queue == @queue
    assert state.data == nil
  end

  test "consumer draining" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)
    {:ok, _} = Datapio.MQ.start_consumer([
      module: __MODULE__.ExampleConsumer,
      id: 0,
      queue: @queue,
      data: %{pid: self(), ets: nil}
    ])

    assert :ok == @queue |> Datapio.MQ.Queue.publish(:hello)
    assert_receive {:received_message, :hello}

    assert :ok == @queue |> Datapio.MQ.Queue.shutdown()
    assert_receive :received_shutdown
  end

  test "consumer shutdown before receiving messages" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)
    {:ok, _} = Datapio.MQ.start_consumer([
      module: __MODULE__.ExampleConsumer,
      id: 0,
      queue: @queue,
      data: %{pid: self(), ets: nil}
    ])

    assert :ok = __MODULE__.ExampleConsumer.shutdown(0)
    assert_receive :received_shutdown

    assert :ok == @queue |> Datapio.MQ.Queue.publish(:hello)
    refute_receive {:received_message, :hello}
  end

  test "consumer did not acknowledge message" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)
    table = :ets.new(:nack_message, [:set, :public])

    {:ok, _} = Datapio.MQ.start_consumer([
      module: __MODULE__.ExampleConsumer,
      id: 0,
      queue: @queue,
      data: %{pid: self(), ets: table}
    ])

    assert :ok == @queue |> Datapio.MQ.Queue.publish(:nack)
    assert_receive {:nack_message, :nack}
    assert_receive {:ack_message, :nack}

    assert :ok == @queue |> Datapio.MQ.Queue.shutdown()
    assert_receive :received_shutdown

    :ets.delete(table)
  end

  test "consumer already started" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)

    opts = [
      module: __MODULE__.ExampleConsumer,
      id: 0,
      queue: @queue,
      data: %{pid: self(), ets: nil}
    ]

    {:ok, _} = Datapio.MQ.start_consumer(opts)
    assert :ignore == Datapio.MQ.start_consumer(opts)
  end
end
