defmodule PipelineRunServer.Request.Controller do
  @moduledoc """
  Observe PipelineRunRequest resources.
  """

  import PipelineRunServer.Request.Utilities
  require Logger

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: "PipelineRunRequest",
    schema: %{}

  @impl true
  def add(%{} = request, _options) do
    case with_resource(request, &schedule_request/1) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def modify(%{} = request, _options) do
    case with_resource(request, &archive_request/1) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def delete(%{} = request, _options) do
    case with_resource(request, &cancel_request/1) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def reconcile(%{} = request, _options) do
    case with_resource(request, &reschedule_request/1) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
