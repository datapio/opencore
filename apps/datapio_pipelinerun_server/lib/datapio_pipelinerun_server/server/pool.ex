defmodule DatapioPipelineRunServer.Server.Pool do
  @moduledoc """
  Balance worker execution across Elixir nodes
  """

  alias DatapioPipelineRunServer.Server, as: Server
  use Horde.DynamicSupervisor

  def start_link(args \\ []) do
    Horde.DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Horde.DynamicSupervisor.init([strategy: :one_for_one, members: :auto])
  end

  def configure_server(server_name, options) do
    child = {Server.Manager, [server_name]}

    case Horde.DynamicSupervisor.start_child(__MODULE__, child) do
      {:ok, _pid} ->
        Server.Manager.configure(server_name, options)

      :ignored ->
        Server.Manager.configure(server_name, options)
    end
  end

  def shutdown_server(server_name) do
    Server.Manager.shutdown(server_name)
  end
end
