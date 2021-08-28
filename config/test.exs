import Config

config :logger, :console,
  level: :none

config :lager,
  error_logger_redirect: false,
  handlers: [level: :none]

config :datapio_core, mocks: [
  k8s_client: DatapioMock.K8s.Client,
  k8s_conn: DatapioMock.K8s.Conn
]

config :datapio_pipelinerun_server, mocks: [
  amqp_conn: DatapioMock.AMQP.Conn,
  amqp_channel: DatapioMock.AMQP.Channel,
  amqp_exchange: DatapioMock.AMQP.Exchange
]
