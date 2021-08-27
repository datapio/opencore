defmodule Datapio.MQ.Exchange do
  @moduledoc """
  Distributed pool of queues.
  """

  use Supervisor

  def start_link(exchange_name) do
    Supervisor.start_link(__MODULE__, exchange_name, name: exchange_name)
  end

  def init(exchange_name) do
    registry_name = Module.concat(exchange_name, Registry)
    pool_name = Module.concat(exchange_name, Pool)

    children = [
      {Horde.Registry, [name: registry_name, keys: :unique]},
      {Horde.DynamicSupervisor, [name: pool_name, strategy: :one_for_one]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_queue(exchange_name, queue_name) do
    pool_name = Module.concat(exchange_name, Pool)
    child = {Datapio.MQ.Queue, [queue_name]}
    Horde.DynamicSupervisor.start_child(pool_name, child)
  end
end
