defmodule PipelineRunServer.Controllers.Request do
  @moduledoc false

  alias PipelineRunServer.Scheduler.Request, as: Scheduler

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: "PipelineRunRequest",
    schema: %{}

  use Brex.Result

  @impl true
  def add(%{} = request, _options) do
    with_resource(request, &Scheduler.schedule/1) |> extract!()
  end

  @impl true
  def modify(_request, _options) do
    {:error, {:forbidden, "Request updates are forbidden and will be ignored"}}
  end

  @impl true
  def delete(%{} = request, _options) do
    with_resource(request, &Scheduler.Cache.clear/1) |> extract!()
  end

  @impl true
  def reconcile(%{} = request, _options) do
    with_resource(request, &Scheduler.schedule/1) |> extract!()
  end
end
