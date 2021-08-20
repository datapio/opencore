defmodule DatapioPipelinerunServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Highlander, DatapioPipelinerunServer.Controller.Server},
      {Highlander, DatapioPipelinerunServer.Controller.Request},
      {Highlander, DatapioPipelinerunServer.Scheduler},
      DatapioPipelinerunServer.WorkerPool
    ]

    opts = [strategy: :one_for_one, name: DatapioPipelinerunServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
