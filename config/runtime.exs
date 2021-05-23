import Config


config :datapio,
  cluster: [
    service_name: System.get_env("DATAPIO_SERVICE_NAME", nil),
    app_name: System.get_env("DATAPIO_APP_NAME", "datapio-opencore")
  ],
  rabbitmq_url: System.get_env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
  klifter_image: System.get_env("DATAPIO_KLIFTER_IMAGE", "ghcr.io/datapio/klifter:latest")

