defmodule PipelineRunServer.Scheduler.Request do
  @moduledoc false

  alias PipelineRunServer.Scheduler.Request
  alias PipelineRunServer.Scheduler.Server
  alias PipelineRunServer.Resources

  @spec schedule(Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def schedule(request) do
    case Request.Cache.get(request) do
      {:hit, _} ->
        :ok

      :miss ->
        Server.schedule(request)

      err ->
        err
    end
  end
end
