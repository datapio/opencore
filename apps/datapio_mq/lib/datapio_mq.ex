defmodule Datapio.MQ do
  @moduledoc """
  Documentation for `DatapioMq`.
  """

  def start_queue(queue_name) do
    child = {Datapio.MQ.Queue, [queue_name]}
    Horde.DynamicSupervisor.start_child(Datapio.MQ.Pool, child)
  end
end
