defmodule Datapio.SchemaLoader do
  @moduledoc false

  @behaviour Xema.Loader

  @spec fetch(URI.t()) :: {:ok, any} | {:error, any}
  def fetch(uri) do
    uri |> File.read!() |> Jason.decode()
  end
end
