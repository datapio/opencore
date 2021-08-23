defmodule DatapioTest.Controller.TestController do
  use Datapio.Controller,
    api_version: "v1",
    kind: :example,
    reconcile_delay: 500

  @impl true
  def add(_resource, options) do
    options[:pid] |> send(:added)
    :ok
  end

  @impl true
  def modify(_resource, options) do
    options[:pid] |> send(:modified)
    :ok
  end

  @impl true
  def delete(_resource, options) do
    options[:pid] |> send(:deleted)
    :ok
  end

  @impl true
  def reconcile(_resource, options) do
    options[:pid] |> send(:reconcile)
    :ok
  end
end

defmodule DatapioTest.Controller do
  use ExUnit.Case

  setup do
    controller_name = DatapioTest.Controller.TestController
    table = :ets.new(controller_name, [:set, :public, :named_table])
    ctrl = start_supervised!({controller_name, [[pid: self()]]})
    [controller: ctrl, table: table]
  end

  describe "datapio controller" do
    test "callbacks" do
      assert_receive :added, 1000, "add/1 callback not called"
      assert_receive :modified, 1000, "modify/1 callback not called"
      assert_receive :deleted, 1000, "delete/1 callback not called"
      assert_receive :reconcile, 1000, "reconcile/1 callback not called"
    end
  end
end
