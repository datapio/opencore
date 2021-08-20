import Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:user_id]

config :datapio_core, mocks: []

import_config "#{config_env()}.exs"
