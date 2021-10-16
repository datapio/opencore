defmodule PipelineRunServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PipelineRunServer.Controllers.Supervisor,
      {Highlander, PipelineRunServer.Archiver}
    ]

    opts = [strategy: :one_for_one, name: PipelineRunServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
