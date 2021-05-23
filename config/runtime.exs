import Config


config :datapio,
  rabbitmq_url: System.get_env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
  klifter_image: System.get_env("DATAPIO_KLIFTER_IMAGE", "ghcr.io/datapio/klifter:latest")

config :k8s,
  clusters: %{
    default: case System.get_env("KUBECONFIG") do
      nil -> %{}
      path -> %{ conn: path }
    end
  }
