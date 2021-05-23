defmodule DatapioProjectOperator.Controller do
  @moduledoc false

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: :project

  @impl true
  def add(resource) do
    IO.puts("ADDED #{resource["metadata"]["name"]}")
    :ok
  end

  @impl true
  def modify(resource) do
    IO.puts("MODIFIED #{resource["metadata"]["name"]}")
    :ok
  end

  @impl true
  def delete(resource) do
    IO.puts("DELETED #{resource["metadata"]["name"]}")
    :ok
  end
end
