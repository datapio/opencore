defmodule Datapio.K8sConn do
  def lookup() do
    case System.get_env("KUBECONFIG") do
      nil -> Deps.get(:k8s_conn).from_service_account()
      path -> Deps.get(:k8s_conn).from_file(path)
    end
  end
end