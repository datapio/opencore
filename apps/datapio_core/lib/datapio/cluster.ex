defmodule Datapio.ClusterSupervisor do
  @moduledoc false

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_link() do
    topologies = Application.fetch_env!(:datapio_core, :topology)

    Cluster.Supervisor.start_link([topologies, [name: __MODULE__]])
  end
end
