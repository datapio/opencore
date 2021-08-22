defmodule Datapio.Application do
  @moduledoc false

  use Application
  alias Datapio.Dependencies, as: Deps

  @impl true
  def start(_type, _args) do
    :ok = init()
    supervise()
  end

  defp init do
    modules = Application.get_env(:datapio_core, :mocks, [])

    Deps.setup()
    Deps.register(:k8s_conn, modules |> Keyword.get(:k8s_conn, K8s.Conn))
    Deps.register(:k8s_client, modules |> Keyword.get(:k8s_client, K8s.Client))
    :ok
  end

  defp supervise do
    children = [
      Datapio.ClusterSupervisor
    ]

    opts = [strategy: :one_for_one, name: Datapio.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
