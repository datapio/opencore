defmodule DatapioMock.K8s.Client do
  @moduledoc false

  def list(api_version, kind, opts) do
    {:operation, :list, {api_version, kind, opts}}
  end

  def run({:operation, :list, {api_version, kind, opts}}, _conn) do
    {:ok, %{
      "items" => []
    }}
  end
end
