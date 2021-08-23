defmodule DatapioTest.Controller.Failed.TestController do
  use Datapio.Controller,
    api_version: "v1",
    kind: :example,
    reconcile_delay: 500

  @impl true
  def add(_resource, options) do
    options[:pid] |> send(:added)
    {:error, :test}
  end

  @impl true
  def modify(_resource, options) do
    options[:pid] |> send(:modified)
    {:error, :test}
  end

  @impl true
  def delete(_resource, options) do
    options[:pid] |> send(:deleted)
    {:error, :test}
  end

  @impl true
  def reconcile(_resource, options) do
    options[:pid] |> send(:reconcile)
    {:error, :test}
  end
end

defmodule DatapioTest.Controller.Failed do
  use ExUnit.Case

  setup do
    controller_name = DatapioTest.Controller.Failed.TestController
    table = :ets.new(controller_name, [:set, :public, :named_table])
    ctrl = start_supervised!({controller_name, [[pid: self()]]})
    [controller: ctrl, table: table]
  end

  describe "datapio controller failed" do
    @tag capture_log: true
    test "callbacks" do
      assert_receive :added, 1000, "add/1 callback not called"
      assert_receive :modified, 1000, "modify/1 callback not called"
      assert_receive :deleted, 1000, "delete/1 callback not called"
      assert_receive :reconcile, 1000, "reconcile/1 callback not called"
    end

    @tag capture_log: true
    test "watch status error" do
      state = %Datapio.Controller{}
      assert {:stop, :normal, state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncStatus{code: 404},
        state
      )
    end

    @tag capture_log: true
    test "watch timeout" do
      state = %Datapio.Controller{}
      reply = Datapio.Controller.handle_info(
        %HTTPoison.Error{reason: {:closed, :timeout}},
        state
      )

      case reply do
        {:noreply, _state} -> :ok
        wrong -> assert wrong == :noreply
      end

      assert_receive :watch, 1000, "watch message not received"
    end
  end
end
