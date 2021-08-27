defmodule DatapioPipelineRunServer.Cluster do
  @moduledoc """
  Elixir Node clustering
  """

  alias :mnesia, as: Mnesia
  alias :net_kernel, as: NetKernel

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
