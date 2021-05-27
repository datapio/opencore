import Config


config :datapio_project_operator,
  klifter_image: System.get_env("DATAPIO_KLIFTER_IMAGE", "ghcr.io/datapio/klifter:latest")

config :datapio_pipelinerun_server,
  rabbitmq_url: System.get_env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")


case config_env() do
  :prod ->
    default_k8s_conn = case System.get_env("KUBECONFIG") do
      nil -> %{}
      path -> %{ conn: path }
    end

    default_k8s_topology = case System.get_env("DATAPIO_SERVICE_NAME", nil) do
      nil -> []
      svc -> [
        default: [
          strategy: Cluster.Strategy.Kubernetes.DNS,
          config: [
            service: svc,
            application_name: System.get_env("DATAPIO_APP_NAME", "datapio-opencore")
          ]
        ]
      ]
    end

    config :k8s,
      clusters: %{ default: default_k8s_conn }

    config :datapio_core,
      topology: default_k8s_topology

  _ ->
    config :k8s,
      clusters: %{ default: %{ conn: System.get_env("KUBECONFIG", "~/.kube/config") } }

    config :datapio_core,
      topology: []
end
