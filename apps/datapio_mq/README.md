# Datapio Message Queue

This project implements a simple message queue application in pure Elixir.

## ✨ Features

 - distributed message queues with [Horde](https://hexdocs.pm/horde/readme.html)
 - multiple load-balanced consumers

## ⚗️ Example

```elixir
defmodule Example.Consumer do
  use Datapio.MQ.Consumer

  def handle_message(msg, data) do
    IO.inspect({:received, msg, data})
    :timer.sleep(1000)
    :ack
  end

  def handle_shutdown(data) do
    IO.inspect(:shutdown)
  end
end

{:ok, _} = Datapio.MQ.start_queue(Example.Queue)
{:ok, _} = Example.Consumer.start_link([
  queue: Example.Queue,
  data: :foo
])
{:ok, _} = Example.Consumer.start_link([
  queue: Example.Queue,
  data: :bar
])

:ok = Datapio.MQ.Queue.publish(Example.Queue, :hello)
:ok = Datapio.MQ.Queue.publish(Example.Queue, :world)
```
