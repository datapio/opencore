defmodule PipelineRunServer.Server.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children = [
      {Highlander, PipelineRunServer.Server.Controller},
      PipelineRunServer.Server.Registry,
      PipelineRunServer.Server.Pool
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
