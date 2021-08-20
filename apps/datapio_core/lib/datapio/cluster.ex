defmodule Datapio.ClusterSupervisor do
  @moduledoc false

  defp service_name do
    var = Application.get_env(:datapio_core, :service_name, [
      env: "DATAPIO_SERVICE_NAME",
      default: nil
    )
    System.get_env(var[:env], var[:default])
  end

  defp app_name do
    var = Application.get_env(:datapio_core, :app_name, [
      env: "DATAPIO_APP_NAME",
      default: "datapio-opencore"
    ])
    System.get_env(var[:env], var[:default])
  end

  defp cluster_opts, do: Application(:datapio_core, :cluster_opts, [])

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_link() do
    topologies = case service_name() do
      nil -> []
      svc -> [
        default: [
          strategy: Cluster.Strategy.Kubernetes.DNS,
          config: [
            service: svc,
            application_name: app_name()
          ]
        ] |> Keyword.merge(cluster_opts())
      ]
    end

    Cluster.Supervisor.start_link([topologies, [name: __MODULE__]])
  end
end
