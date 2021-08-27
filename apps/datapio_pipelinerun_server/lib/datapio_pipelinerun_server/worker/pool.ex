defmodule DatapioPipelineRunServer.Worker.Pool do
  @moduledoc """
  Balance worker execution across Elixir nodes
  """

  use Horde.DynamicSupervisor

  def start_link(args \\ []) do
    Horde.DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Horde.DynamicSupervisor.init([strategy: :one_for_one, members: :auto])
  end

  def start_worker(options) do
    child = {DatapioPipelineRunServer.Worker.Handler, [options]}
    Horde.DynamicSupervisor.start_child(__MODULE__, child)
  end

  def shutdown_worker(server_name, worker_id) do
    DatapioPipelineRunServer.Worker.Handler.shutdown(server_name, worker_id)
  end
end
