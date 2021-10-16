import Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:user_id]

config :datapio_cluster,
  service_name: [env: "DATAPIO_SERVICE_NAME", default: nil],
  app_name: [env: "DATAPIO_APP_NAME", default: "datapio-opencore"],
  cache_tables: [
    requests: [:uid, :resource],
    servers: [:uid, :resource]
  ]

import_config "#{config_env()}.exs"
