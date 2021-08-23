defmodule DatapioTest.Dependencies do
  use ExUnit.Case

  alias Datapio.Dependencies, as: Deps

  describe "dependency injection" do
    test "register/2" do
      Deps.register(Foo, Bar)
      assert Bar == Deps.get(Foo)
    end

    test "mocks" do
      assert DatapioMock.K8s.Client == Deps.get(:k8s_client)
      assert DatapioMock.K8s.Conn == Deps.get(:k8s_conn)
    end
  end
end
