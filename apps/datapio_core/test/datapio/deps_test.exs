defmodule DatapioTest.Dependencies do
  use ExUnit.Case

  alias Datapio.Dependencies, as: Deps

  setup do
    [ets_table: Deps.setup()]
  end

  describe "dependency injection" do
    test "register/2" do
      Deps.register(Foo, Bar)
      assert Bar == Deps.get(Foo)
    end
  end
end
