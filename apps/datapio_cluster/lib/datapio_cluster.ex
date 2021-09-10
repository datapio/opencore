defmodule Datapio.Cluster do
  @moduledoc """
  Access to `Datapio.Cluster` configuration.
  """

  alias :mnesia, as: Mnesia
  alias :net_kernel, as: NetKernel

  @doc "Get name of Kubernetes Headless Service via an environment variable."
  @spec service_name() :: String.t() | nil
  def service_name do
    var = Application.get_env(:datapio_cluster, :service_name, [
      env: "DATAPIO_SERVICE_NAME",
      default: nil
    ])
    System.get_env(var[:env], var[:default])
  end

  @doc """
  Get application name (used as `<basename>` in Erlang node
  name: `<basename>@<pod-ip>`.
  """
  @spec app_name() :: String.t()
  def app_name do
    var = Application.get_env(:datapio_cluster, :app_name, [
      env: "DATAPIO_APP_NAME",
      default: "datapio-opencore"
    ])
    System.get_env(var[:env], var[:default])
  end

  @doc "Get custom options for **libcluster**."
  @spec options() :: keyword()
  def options do
    Application.get_env(:datapio_cluster, :cluster_opts, [])
  end

  @doc "Get **libcluster** topologies configuration"
  @spec topologies(atom()) :: keyword(keyword())
  def topologies(name \\ :default) do
    case service_name() do
      nil -> []
      svc -> [
        {name, [
          strategy: Cluster.Strategy.Kubernetes.DNS,
          config: [
            service: svc,
            application_name: app_name()
          ],
          connect: {Datapio.Cluster, :connect_node, []}
        ] |> Keyword.merge(options())}
      ]
    end
  end

  @doc "Connect to Erlang node"
  @spec connect_node(node()) :: boolean()
  def connect_node(node) do
    with true <- NetKernel.connect_node(node),
         {:ok, _} <- Mnesia.change_config(:extra_db_nodes, [node])
    do
      true
    else
      _ -> false
    end
  end
end
