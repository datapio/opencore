defmodule Datapio.Cluster.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    case Datapio.Cluster.Mnesia.init_from_config() do
      :ok ->
        topologies = Datapio.Cluster.topologies()
        Cluster.Supervisor.start_link([topologies, [name: Datapio.Cluster]])

      err ->
        err
    end
  end
end
