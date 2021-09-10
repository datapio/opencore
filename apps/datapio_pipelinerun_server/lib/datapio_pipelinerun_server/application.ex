defmodule DatapioPipelineRunServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    DatapioPipelineRunServer.Supervisor.start_link()
  end
end
