defmodule DatapioTest.Controller.TestController do
  use Datapio.Controller,
    api_version: "v1",
    kind: :example

  @impl true
  def add(resource) do
    :ok
  end

  @impl true
  def modify(resource) do
    :ok
  end

  @impl true
  def delete(resource) do
    :ok
  end

  @impl true
  def reconcile(resource) do
    :ok
  end
end

defmodule DatapioTest.Controller do
  use ExUnit.Case
end
