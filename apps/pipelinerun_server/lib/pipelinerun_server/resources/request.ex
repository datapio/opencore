defmodule PipelineRunServer.Resources.Request do
  @moduledoc """
  Utility functions related to PipelineRunRequest resources
  """

  alias PipelineRunServer.Resources.PipelineRun

  def fetch_pipelinerun(request) do
    {:ok, conn} = Datapio.K8s.Conn.lookup()

    %{"metadata" => %{"name" => name, "namespace" => namespace}} = request
    selection = [namespace: namespace, name: name]

    K8s.Client.get("tekton.dev/v1alpha1", "PipelineRun", selection)
      |> then(&(K8s.Client.run(conn, &1)))
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
