import Config

config :logger, :console,
  level: :none

config :datapio_core, mocks: [
  k8s_client: DatapioMock.K8s.Client,
  k8s_conn: DatapioMock.K8s.Conn
]
