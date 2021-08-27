defmodule DatapioTest.MQ.Queue do
  use ExUnit.Case

  @queue DatapioTest.MQ.Queue.Example

  def with_queue(fun) do
    {:ok, pid} = Datapio.MQ.start_queue(@queue)
    ref = Process.monitor(pid)

    fun.()

    Datapio.MQ.Queue.shutdown(@queue)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end
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
    with_queue(fn ->
      assert :ok == @queue |> Datapio.MQ.Queue.publish(:hello)
    end)
  end

  @tag capture_log: true
  test "consume message with empty queue" do
    with_queue(fn ->
      assert :ok == @queue |> Datapio.MQ.Queue.drain()
      assert :ok == @queue |> Datapio.MQ.Queue.publish(Hello.World)

      assert_receive {:datapio_mq_consume, Hello.World}
    end)
  end

  @tag capture_log: true
  test "consume message with non-empty queue" do
    with_queue(fn ->
      assert :ok == @queue |> Datapio.MQ.Queue.publish(Hello.World)
      assert :ok == @queue |> Datapio.MQ.Queue.drain()

      assert_receive {:datapio_mq_consume, Hello.World}
    end)
  end

  @tag capture_log: true
  test "shutdown queue with consumers" do
    with_queue(fn ->
      assert :ok == @queue |> Datapio.MQ.Queue.drain()
    end)

    assert_receive :datapio_mq_shutdown
  end

  @tag capture_log: true
  test "start already started queue" do
    with_queue(fn ->
      assert :ignore == Datapio.MQ.start_queue(@queue)
    end)
  end
end
