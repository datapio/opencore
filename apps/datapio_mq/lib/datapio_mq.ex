defmodule Datapio.MQ do
  @moduledoc """
  Message Queue application interface.
  """

  @type queue_name :: Datapio.MQ.Queue.queue_name()
  @type consumer_options  :: Datapio.MQ.Consumer.consumer_options()

  @doc "Start a new queue"
  @spec start_queue(queue_name()) :: DynamicSupervisor.on_start_child()
  def start_queue(queue_name) do
    child = {Datapio.MQ.Queue, queue_name}
    Horde.DynamicSupervisor.start_child(Datapio.MQ.Pool, child)
  end

  @doc "Start a consumer"
  @spec start_consumer(consumer_options()) :: DynamicSupervisor.on_start_child()
  def start_consumer(options) do
    module = options |> Keyword.fetch!(:module)
    child = {module, options}
    Horde.DynamicSupervisor.start_child(Datapio.MQ.Pool, child)
  end
end
