defmodule DatapioPipelineRunServer.Application do
  @moduledoc false

  use Application

  alias Datapio.Dependencies, as: Deps

  @impl true
  def start(_type, _args) do
    with :ok <- DatapioPipelineRunServer.Mnesia.create_tables(),
         {:ok, pid} <- DatapioPipelineRunServer.Supervisor.start_link()
    do
      {:ok, pid}
    else
      err -> err
    end
  end
end
