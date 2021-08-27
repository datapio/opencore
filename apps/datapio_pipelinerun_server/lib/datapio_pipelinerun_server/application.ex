defmodule DatapioPipelineRunServer.Application do
  @moduledoc false

  use Application

  alias Datapio.Dependencies, as: Deps

  @impl true
  def start(_type, _args) do
    with :ok <- setup(),
         :ok <- DatapioPipelineRunServer.Mnesia.create_tables(),
         {:ok, pid} <- DatapioPipelineRunServer.Supervisor.start_link()
    do
      {:ok, pid}
    else
      err -> err
    end
  end

  defp setup() do
    modules = Application.get_env(:datapio_pipelinerun_server, :mocks, [])

    Deps.register(:amqp_conn, modules |> Keyword.get(:amqp_conn, AMQP.Connection))
    Deps.register(:amqp_channel, modules |> Keyword.get(:amqp_channel, AMQP.Channel))
    Deps.register(:amqp_basic, modules |> Keyword.get(:amqp_basic, AMQP.Basic))
    Deps.register(:amqp_exchange, modules |> Keyword.get(:amqp_exchange, AMQP.Exchange))
    Deps.register(:amqp_queue, modules |> Keyword.get(:amqp_queue, AMQP.Queue))
    :ok
  end
end
