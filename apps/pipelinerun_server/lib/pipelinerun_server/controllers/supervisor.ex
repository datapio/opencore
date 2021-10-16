defmodule PipelineRunServer.Controllers.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children = [
      {Highlander, PipelineRunServer.Controllers.Server},
      {Highlander, PipelineRunServer.Controllers.Request}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
