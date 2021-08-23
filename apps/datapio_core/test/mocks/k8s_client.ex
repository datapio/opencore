defmodule DatapioMock.K8s.Client do
  @moduledoc false

  def list(api_version, kind, opts) do
    {:operation, :list, {api_version, kind, opts}}
  end

  def watch(_conn, _operation, stream_to: pid) do
    added = %{"type" => "ADDED", "object" => get_mock_resource()}
    modified = %{"type" => "MODIFIED", "object" => get_mock_resource(2)}
    deleted = %{"type" => "DELETED", "object" => get_mock_resource()}

    pid |> send(%HTTPoison.AsyncStatus{code: 200})
    pid |> send(%HTTPoison.AsyncHeaders{})
    pid |> send(%HTTPoison.AsyncChunk{chunk: Jason.encode!(added)})
    pid |> send(%HTTPoison.AsyncChunk{chunk: Jason.encode!(modified)})
    pid |> send(%HTTPoison.AsyncChunk{chunk: Jason.encode!(modified)})
    pid |> send(%HTTPoison.AsyncChunk{chunk: Jason.encode!(deleted)})
    pid |> send(%HTTPoison.AsyncEnd{})
    {:ok, nil}
  end

  def run(_conn, {:operation, :list, {_api_version, _kind, _opts}}) do
    {:ok, %{
      "items" => [get_mock_resource()]
    }}
  end

  def run(_conn, {:operation, :test, payload}) do
    {:ok, payload}
  end

  def async(_conn, operations) do
    {:ok, operations |> Enum.map(fn {:operation, :test, payload} -> payload end)}
  end

  defp get_mock_resource(resource_version \\ 1), do: %{
    "apiVersion" => "example.com/v1",
    "kind" => "Example",
    "metadata" => %{
      "name" => "example",
      "namespace" => "default",
      "uid" => "SOME_ID",
      "resourceVersion" => resource_version
    }
  }
end
