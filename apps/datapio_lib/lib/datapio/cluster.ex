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
    config = [
      service_name: System.get_env("DATAPIO_SERVICE_NAME", nil),
      app_name: System.get_env("DATAPIO_APP_NAME", "datapio-opencore")
    ]

    topologies = case config[:service_name] do
      nil -> []
      svc -> [
        default: [
          strategy: Cluster.Strategy.Kubernetes.DNS,
          config: [
            service: svc,
            application_name: config[:app_name]
          ]
        ]
      ]
    end

    Cluster.Supervisor.start_link([topologies, [name: __MODULE__]])
  end
end
