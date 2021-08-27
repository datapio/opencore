defmodule DatapioTest.MQ.Consumer do
  use ExUnit.Case

  @queue DatapioTest.MQ.Consumer.ExampleQueue

  defmodule ExampleConsumer do
    use Datapio.MQ.Consumer

    @impl true
    def handle_message(msg, pid) do
      send(pid, {:received_message, msg})
      :ack
    end

    @impl true
    def handle_shutdown(pid) do
      send(pid, :received_shutdown)
    end
  end

  test "consumer behavior" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)
    consumer = {__MODULE__.ExampleConsumer, [
      queue: @queue,
      data: self()
    ]}
    start_supervised!(consumer)

    assert :ok == @queue |> Datapio.MQ.Queue.publish(:hello)
    assert_receive {:received_message, :hello}

    assert :ok == @queue |> Datapio.MQ.Queue.shutdown()
    assert_receive :received_shutdown
  end
end
