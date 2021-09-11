defmodule Datapio.K8s.Conn do
  @moduledoc """
  Generate `K8s.Conn` object.
  """

  @doc "Generate a `K8s.Conn` object from a *kubeconfig* or in-cluster config."
  @spec lookup(String.t() | nil) :: {:ok, K8s.Conn.t()} | {:error, term()}
  def lookup(default_path \\ nil) do
    case System.get_env("KUBECONFIG", default_path) do
      nil -> K8s.Conn.from_service_account()
      path -> K8s.Conn.from_file(path)
    end
  end
end
