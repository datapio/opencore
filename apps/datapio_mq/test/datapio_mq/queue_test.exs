defmodule DatapioTest.MQ.Queue do
  use ExUnit.Case

  @queue DatapioTest.MQ.Queue.Example

  @tag capture_log: true
  setup do
    :ok = Application.stop(:datapio_mq)
    :ok = Application.start(:datapio_mq)
  end

  test "internal state" do
    state = %Datapio.MQ.Queue{
      name: @queue,
      queue: [:hello],
      sinks: [:world]
    }

    assert state.name == @queue
    assert state.queue |> Enum.count() == 1
    assert state.sinks |> Enum.count() == 1
  end

  @tag capture_log: true
  test "publish message with no consumer" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)

    assert :ok == @queue |> Datapio.MQ.Queue.publish(:hello)
    assert :ok == @queue |> Datapio.MQ.Queue.shutdown()
  end

  @tag capture_log: true
  test "consume message with empty queue" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)

    assert :ok == @queue |> Datapio.MQ.Queue.drain()
    assert :ok == @queue |> Datapio.MQ.Queue.publish(Hello.World)

    assert_receive {:datapio_mq_consume, Hello.World}
  end

  @tag capture_log: true
  test "consume message with non-empty queue" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)

    assert :ok == @queue |> Datapio.MQ.Queue.publish(Hello.World)
    assert :ok == @queue |> Datapio.MQ.Queue.drain()

    assert_receive {:datapio_mq_consume, Hello.World}
  end

  @tag capture_log: true
  test "shutdown queue with consumers" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)

    assert :ok == @queue |> Datapio.MQ.Queue.drain()
    assert :ok == @queue |> Datapio.MQ.Queue.shutdown()

    assert_receive :datapio_mq_shutdown
  end

  @tag capture_log: true
  test "start already started queue" do
    {:ok, _} = Datapio.MQ.start_queue(@queue)
    assert :ignore == Datapio.MQ.start_queue(@queue)
  end
end
