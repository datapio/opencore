defmodule Datapio.Test.K8s.Conn do
  use ExUnit.Case
  import Mock

  describe "lookup/0" do
    test "kubeconfig with no env" do
      with_mocks([
        {System, [:passthrough], [
          get_env: fn "KUBECONFIG", default -> default end
        ]},
        {K8s.Conn, [:passthrough], [
          from_file: fn path -> {:path, path} end
        ]}
      ]) do
        assert Datapio.K8s.Conn.lookup("default-path") == {:path, "default-path"}
      end
    end

    test "kubeconfig with env" do
      with_mocks([
        {System, [:passthrough], [
          get_env: fn "KUBECONFIG", _ -> "path" end
        ]},
        {K8s.Conn, [:passthrough], [
          from_file: fn path -> {:path, path} end
        ]}
      ]) do
        assert Datapio.K8s.Conn.lookup("default-path") == {:path, "path"}
      end
    end

    test "in cluster" do
      with_mocks([
        {System, [:passthrough], [
          get_env: fn "KUBECONFIG", default -> default end
        ]},
        {K8s.Conn, [:passthrough], [
          from_service_account: fn -> :in_cluster end
        ]}
      ]) do
        assert Datapio.K8s.Conn.lookup() == :in_cluster
      end
    end
  end
end
