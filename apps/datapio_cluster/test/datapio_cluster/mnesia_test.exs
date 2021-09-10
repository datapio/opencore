defmodule Datapio.Test.Cluster.Mnesia do
  use ExUnit.Case
  import Mock

  alias :mnesia, as: Mnesia

  @table_success {:valid, [:attr1, :attr2]}
  @table_exist {:exist, [:attr1, :attr2]}
  @table_failed {:failed, [:attr1, :attr2]}

  def application_mock(tables) do
    {Application, [:passthrough], [
      get_env: fn :datapio_cluster, :cache_tables, _ -> tables end
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

  describe "init_from_config/0" do
    test "successful" do
      with_mocks([
        application_mock([@table_success, @table_exist]),
        mnesia_mock()
      ]) do
        assert :ok == Datapio.Cluster.Mnesia.init_from_config()
      end
    end

    test "failed" do
      with_mocks([
        application_mock([@table_success, @table_failed, @table_exist]),
        mnesia_mock()
      ]) do
        assert {:error, :failed} == Datapio.Cluster.Mnesia.init_from_config()
      end
    end
  end
end
