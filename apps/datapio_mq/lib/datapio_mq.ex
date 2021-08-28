defmodule Datapio.MQ do
  @moduledoc """
  Documentation for `DatapioMq`.
  """

  def start_queue(queue_name) do
    child = {Datapio.MQ.Queue, [queue_name]}
    Horde.DynamicSupervisor.start_child(Datapio.MQ.Pool, child)
  end

  def start_consumer(options) do
    module = options |> Keyword.fetch!(:module)
    child = {module, options}
    Horde.DynamicSupervisor.start_child(Datapio.MQ.Pool, child)
  end
end
