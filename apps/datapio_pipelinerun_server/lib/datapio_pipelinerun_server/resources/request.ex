defmodule DatapioPipelineRunServer.Resources.Request do
  @moduledoc """
  Utility functions related to PipelineRunRequest resources
  """

  alias Datapio.Dependencies, as: Deps
  alias DatapioPipelineRunServer.Resources.PipelineRun

  def fetch_pipelinerun(request) do
    client = Deps.get(:k8s_client)
    {:ok, conn} = Datapio.K8sConn.lookup()

    %{"metadata" => %{"name" => name, "namespace" => namespace}} = request
    selection = [namespace: namespace, name: name]

    client.get("tekton.dev/v1alpha1", "PipelineRun", selection)
      |> then(&(client.run(conn, &1)))
  end

  def get_status(request) do
    case fetch_pipelinerun(request) do
      {:ok, prun} ->
        case PipelineRun.completed?(prun) do
          true -> :completed
          false -> :pending
        end

      _ ->
        :unscheduled
    end
  end
end
