defmodule PipelineRunServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    PipelineRunServer.Supervisor.start_link()
  end
end
