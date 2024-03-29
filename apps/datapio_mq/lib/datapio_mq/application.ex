defmodule Datapio.MQ.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Horde.Registry, [name: Datapio.MQ.Registry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor, [name: Datapio.MQ.Pool, strategy: :one_for_one, members: :auto]}
    ]

    opts = [strategy: :one_for_one, name: Datapio.MQ.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
