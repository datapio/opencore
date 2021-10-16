defmodule PipelineRunServer.Scheduler.Server.Cache do
  @moduledoc false

  alias PipelineRunServer.Scheduler.Cache
  alias :mnesia, as: Mnesia

  @spec get(Datapio.K8s.Resource.t()) ::
    :miss
    | {:hit, Datapio.K8s.Resource.t()}
    | {:error, term()}

  def get(server) do
    Cache.get(:servers, server)
  end

  @spec put(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def put(server) do
    Cache.put(:servers, server)
  end

  @spec clear(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def clear(server) do
    Cache.clear(:servers, server)
  end
end
