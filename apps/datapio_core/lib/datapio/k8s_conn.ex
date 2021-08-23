defmodule Datapio.K8sConn do
  @moduledoc """
  Generate K8s.Conn object.
  """

  alias Datapio.Dependencies, as: Deps

  def lookup(default_path \\ nil) do
    case System.get_env("KUBECONFIG", default_path) do
      nil -> Deps.get(:k8s_conn).from_service_account()
      path -> Deps.get(:k8s_conn).from_file(path)
    end
  end
end