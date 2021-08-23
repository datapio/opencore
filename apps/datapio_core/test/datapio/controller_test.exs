defmodule DatapioTest.Controller.TestController do
  use Datapio.Controller,
    api_version: "v1",
    kind: :example

  @impl true
  def add(_resource) do
    :ok
  end

  @impl true
  def modify(_resource) do
    :ok
  end

  @impl true
  def delete(_resource) do
    :ok
  end

  @impl true
  def reconcile(_resource) do
    :ok
  end
end

defmodule DatapioTest.Controller do
  use ExUnit.Case
end
