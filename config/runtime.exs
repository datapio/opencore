import Config


config :datapio_project_operator,
  klifter_image: System.get_env("DATAPIO_KLIFTER_IMAGE", "ghcr.io/datapio/klifter:latest")

config :datapio_pipelinerun_server,
  rabbitmq_url: System.get_env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
