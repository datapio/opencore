defmodule Datapio.Test.Cluster do
  use ExUnit.Case
  import Mock

  alias :mnesia, as: Mnesia
  alias :net_kernel, as: NetKernel

  describe "service_name/0" do
    test "default config with no env" do
      with_mock(System, [:passthrough],
        get_env: fn "DATAPIO_SERVICE_NAME", _ -> nil end
      ) do
        assert Datapio.Cluster.service_name() == nil
      end
    end

    test "default config with env" do
      with_mock(System, [:passthrough],
        get_env: fn "DATAPIO_SERVICE_NAME", _ -> "svc" end
      ) do
        assert Datapio.Cluster.service_name() == "svc"
      end
    end

    test "custom config with no env" do
      with_mocks([
        {Application, [:passthrough], [
          get_env: fn :datapio_cluster, :service_name, _ -> [
            env: "CUSTOM_SERVICE_NAME",
            default: "default-svc"
          ] end
        ]},
        {System, [:passthrough], [
          get_env: fn "CUSTOM_SERVICE_NAME", default -> default end
        ]}
      ]) do
        assert Datapio.Cluster.service_name() == "default-svc"
      end
    end

    test "custom config with env" do
      with_mocks([
        {Application, [:passthrough], [
          get_env: fn :datapio_cluster, :service_name, _ -> [
            env: "CUSTOM_SERVICE_NAME",
            default: "default-svc"
          ] end
        ]},
        {System, [:passthrough], [
          get_env: fn "CUSTOM_SERVICE_NAME", _ -> "svc" end
        ]}
      ]) do
        assert Datapio.Cluster.service_name() == "svc"
      end
    end
  end

  describe "app_name/0" do
    test "default config with no env" do
      with_mock(System, [:passthrough],
        get_env: fn "DATAPIO_APP_NAME", _ -> "default-app" end
      ) do
        assert Datapio.Cluster.app_name() == "default-app"
      end
    end

    test "default config with env" do
      with_mock(System, [:passthrough],
        get_env: fn "DATAPIO_APP_NAME", _ -> "app" end
      ) do
        assert Datapio.Cluster.app_name() == "app"
      end
    end

    test "custom config with no env" do
      with_mocks([
        {Application, [:passthrough], [
          get_env: fn :datapio_cluster, :app_name, _ -> [
            env: "CUSTOM_APP_NAME",
            default: "default-app"
          ] end
        ]},
        {System, [:passthrough], [
          get_env: fn "CUSTOM_APP_NAME", default -> default end
        ]}
      ]) do
        assert Datapio.Cluster.app_name() == "default-app"
      end
    end

    test "custom config with env" do
      with_mocks([
        {Application, [:passthrough], [
          get_env: fn :datapio_cluster, :app_name, _ -> [
            env: "CUSTOM_APP_NAME",
            default: "default-app"
          ] end
        ]},
        {System, [:passthrough], [
          get_env: fn "CUSTOM_APP_NAME", _ -> "app" end
        ]}
      ]) do
        assert Datapio.Cluster.app_name() == "app"
      end
    end
  end

  describe "options/0" do
    test "default config" do
      with_mock(Application, [:passthrough],
        get_env: fn :datapio_cluster, :cluster_opts, [] -> [] end
      ) do
        assert Datapio.Cluster.options() == []
      end
    end

    test "custom config" do
      with_mock(Application, [:passthrough],
        get_env: fn :datapio_cluster, :cluster_opts, [] -> [foo: :bar] end
      ) do
        assert Datapio.Cluster.options() == [foo: :bar]
      end
    end
  end

  describe "topologies/1" do
    test "with no service" do
      with_mock(System, [:passthrough],
        get_env: fn "DATAPIO_SERVICE_NAME", _ -> nil end
      ) do
        assert Datapio.Cluster.topologies() == []
      end
    end

    test "with service" do
      with_mock(System, [:passthrough],
        get_env: fn
          "DATAPIO_SERVICE_NAME", _ -> "svc"
          "DATAPIO_APP_NAME", _ -> "app"
        end
      ) do
        assert Datapio.Cluster.topologies() == [default: [
          strategy: Cluster.Strategy.Kubernetes.DNS,
          config: [
            service: "svc",
            application_name: "app"
          ],
          connect: {Datapio.Cluster, :connect_node, []}
        ]]
      end
    end
  end

  describe "connect_node/1" do
    test "successful" do
      with_mocks([
        {NetKernel, [:passthrough, :unstick], [
          connect_node: fn _ -> true end
        ]},
        {Mnesia, [:passthrough], [
          change_config: fn _, _ -> {:ok, :config} end
        ]}
      ]) do
        assert Datapio.Cluster.connect_node(:node) == true
      end
    end

    test "netkernel failed" do
      with_mocks([
        {NetKernel, [:passthrough, :unstick], [
          connect_node: fn _ -> false end
        ]},
        {Mnesia, [:passthrough], [
          change_config: fn _, _ -> {:ok, :config} end
        ]}
      ]) do
        assert Datapio.Cluster.connect_node(:node) == false
      end
    end

    test "mnesia failed" do
      with_mocks([
        {NetKernel, [:passthrough, :unstick], [
          connect_node: fn _ -> false end
        ]},
        {Mnesia, [:passthrough], [
          change_config: fn _, _ -> {:error, :reason} end
        ]}
      ]) do
        assert Datapio.Cluster.connect_node(:node) == false
      end
    end
  end
end
