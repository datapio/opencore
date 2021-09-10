defmodule Datapio.Test.Cluster.Application do
  use ExUnit.Case
  import Mock

  alias :mnesia, as: Mnesia

  @table_success {:valid, [:attr1, :attr2]}
  @table_exist {:exist, [:attr1, :attr2]}
  @table_failed {:failed, [:attr1, :attr2]}

  def application_mock(cache_tables) do
    {Application, [:passthrough], [
      get_env: fn
        :datapio_cluster, :service_name, default -> default
        :datapio_cluster, :cache_tables, _ -> cache_tables
      end
    ]}
  end

  def system_mock do
    {System, [:passthrough], [
      get_env: fn "DATAPIO_SERVICE_NAME", default -> default end
    ]}
  end

  def mnesia_mock do
    {Mnesia, [:passthrough], [
      create_table: fn
        :valid, _ -> {:atomic, :ok}
        :exist, _ -> {:aborted, {:already_exists, :exist}}
        :failed, _ -> {:aborted, :failed}
      end
    ]}
  end

  def libcluster_mock(result) do
    {Cluster.Supervisor, [:passthrough], [
      start_link: fn _ -> result end
    ]}
  end

  describe "start/2" do
    test "success" do
      with_mocks([
        application_mock([@table_success, @table_exist]),
        system_mock(),
        mnesia_mock(),
        libcluster_mock({:ok, :pid})
      ]) do
        assert {:ok, :pid} == Datapio.Cluster.Application.start(:test, [])
      end
    end

    test "mnesia failed" do
      with_mocks([
        application_mock([@table_success, @table_failed, @table_exist]),
        system_mock(),
        mnesia_mock(),
        libcluster_mock({:ok, :pid})
      ]) do
        assert {:error, :failed} == Datapio.Cluster.Application.start(:test, [])
      end
    end

    test "libcluster failed" do
      with_mocks([
        application_mock([@table_success, @table_exist]),
        system_mock(),
        mnesia_mock(),
        libcluster_mock({:error, :libcluster})
      ]) do
        assert {:error, :libcluster} == Datapio.Cluster.Application.start(:test, [])
      end
    end
  end
end
