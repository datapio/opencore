defmodule PipelineRunServer.Controllers.Server do
  @moduledoc false

  alias PipelineRunServer.Scheduler.Server, as: Scheduler
  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: "PipelineRunServer",
    schema: %{}

  use Brex.Result

  @impl true
  def add(%{} = server, options) do
    reconcile(server, options)
  end

  @impl true
  def modify(%{} = server, options) do
    reconcile(server, options)
  end

  @impl true
  def delete(%{} = server, _options) do
    with_resource(server, &Scheduler.shutdown/1) |> extract!()
  end

  @impl true
  def reconcile(%{} = server, _options) do
    with_resource(server, &Scheduler.configure/1) |> extract!()
  end
end
