import Config

config :datapio_core, mocks: [
  k8s_client: DatapioMock.K8s.Client
]
