defmodule PipelineRunServer.Scheduler.Request.Cache do
  @moduledoc false

  alias PipelineRunServer.Scheduler.Cache
  alias :mnesia, as: Mnesia

  @spec get(Datapio.K8s.Resource.t()) ::
    :miss
    | {:hit, Datapio.K8s.Resource.t()}
    | {:error, term()}

  def get(request) do
    Cache.get(:requests, request)
  end

  @spec put(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def put(request) do
    Cache.put(:requests, request)
  end

  @spec clear(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def clear(request) do
    Cache.clear(:requests, request)
  end
end
