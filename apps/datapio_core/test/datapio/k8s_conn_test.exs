defmodule DatapioTest.K8sConn do
  use ExUnit.Case

  setup do
    case System.get_env("KUBECONFIG") do
      nil -> :ok
      old_val ->
        System.delete_env("KUBECONFIG")
        on_exit(fn -> System.put_env("KUBECONFIG", old_val) end)
    end
  end

  describe "kubernetes connection lookup" do
    test "from service account" do
      result = Datapio.K8sConn.lookup()
      assert result == {:ok, [kind: :service_account]}
    end

    test "from path" do
      result = Datapio.K8sConn.lookup(".kube/config")
      assert result == {:ok, [kind: :file, path: ".kube/config"]}
    end
  end
end
