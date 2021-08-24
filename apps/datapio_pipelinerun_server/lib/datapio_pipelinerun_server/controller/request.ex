defmodule DatapioPipelinerunServer.Controller.Request do
  @moduledoc """
  Observe PipelineRunRequest resources.
  """

  require Logger

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: "PipelineRunRequest",
    schema: %{
      "$ref" => Application.app_dir(:datapio_pipelinerun_server, "priv")
        |> Path.join("pipelinerun-request.json")
    }

  @impl true
  def add(%{} = request, _options) do
    Logger.debug("ADDED", [
      name: project["metadata"]["name"],
      namespace: project["metadata"]["namespace"]
    ])

  end

  @impl true
  def modify(%{} = request, _options) do
  end

  @impl true
  def delete(%{} = request, _options) do
  end

  @impl true
  def reconcile(%{} = request, _options) do
  end
end
