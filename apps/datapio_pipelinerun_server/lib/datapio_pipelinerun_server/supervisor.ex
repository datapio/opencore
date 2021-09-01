defmodule DatapioPipelineRunServer.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, [arg], name: __MODULE__)
  end

  def init(_args) do
    children = [
      DatapioPipelineRunServer.Server.Supervisor,
      DatapioPipelineRunServer.Request.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
