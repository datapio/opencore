defmodule Datapio.Test.Controller do
  use ExUnit.Case
  import Mock

  defmodule TestController do
    use Datapio.Controller,
      api_version: "example.com/v1",
      kind: "Example",
      reconcile_delay: 10

    @impl true
    def add(resource, _options) do
      send(self(), {:added, resource})

      case resource["metadata"]["uid"] do
        "SUCCESS" -> :ok
        "FAILURE" -> {:error, :test}
      end
    end

    @impl true
    def modify(resource, _options) do
      send(self(), {:modified, resource})

      case resource["metadata"]["uid"] do
        "SUCCESS" -> :ok
        "FAILURE" -> {:error, :test}
      end
    end

    @impl true
    def delete(resource, _options) do
      send(self(), {:deleted, resource})

      case resource["metadata"]["uid"] do
        "SUCCESS" -> :ok
        "FAILURE" -> {:error, :test}
      end
    end

    @impl true
    def reconcile(resource, _options) do
      send(self(), {:reconciled, resource})

      case resource["metadata"]["uid"] do
        "SUCCESS" -> :ok
        "FAILURE" -> {:error, :test}
      end
    end
  end

  @resource_success %{"metadata" => %{"uid" => "SUCCESS", "resourceVersion" => 1}}
  @resource_success_v2 %{"metadata" => %{"uid" => "SUCCESS", "resourceVersion" => 2}}
  @resource_failure %{"metadata" => %{"uid" => "FAILURE", "resourceVersion" => 1}}
  @resource_failure_v2 %{"metadata" => %{"uid" => "FAILURE", "resourceVersion" => 2}}

  @options [
    module: TestController,
    api_version: "example.com/v1",
    kind: "Example",
    namespace: :all,
    reconcile_delay: 10,
    options: [foo: :bar]
  ]

  @state %Datapio.Controller.State{
    module: TestController,
    api_version: "example.com/v1",
    kind: "Example",
    namespace: :all,
    conn: :k8s_conn,
    watcher: nil,
    reconcile_delay: 10,
    cache: %{},
    chunks: %{},
    options: [foo: :bar]
  }

  @state_watching %Datapio.Controller.State{
    module: TestController,
    api_version: "example.com/v1",
    kind: "Example",
    namespace: :all,
    conn: :k8s_conn,
    watcher: :watcher,
    reconcile_delay: 10,
    cache: %{},
    chunks: %{},
    options: [foo: :bar]
  }

  @state_cache %Datapio.Controller.State{
    module: TestController,
    api_version: "example.com/v1",
    kind: "Example",
    namespace: :all,
    conn: :k8s_conn,
    watcher: :watcher,
    reconcile_delay: 10,
    cache: %{
      "SUCCESS" => @resource_success,
      "FAILURE" => @resource_failure
    },
    chunks: %{},
    options: [foo: :bar]
  }

  defp state_with_chunk(state, chunk_id, chunk) do
    chunks = state.chunks |> Map.put(chunk_id, chunk)
    %Datapio.Controller.State{state | chunks: chunks}
  end

  test "start_link/1" do
    with_mock(GenServer, [:passthrough],
      start_link: fn module, options, name: name -> {:ok, {module, options, name}} end
    ) do
      {:ok, {module, options, name}} = TestController.start_link(foo: :bar)

      assert module == Datapio.Controller
      assert options == @options
      assert name == TestController
    end
  end

  test "init/1" do
    with_mocks([
      {System, [:passthrough], [
        get_env: fn "KUBECONFIG", _ -> nil end
      ]},
      {K8s.Conn, [:passthrough], [
        from_service_account: fn -> {:ok, :k8s_conn} end
      ]}
    ]) do
      assert {:ok, @state} == Datapio.Controller.init(@options)
      assert_receive :watch
      assert_receive :reconcile
    end
  end

  describe "handle_call/3" do
    test "run_operation/1" do
      with_mocks([
        {K8s.Client, [:passthrough], [
          run: fn conn, operation -> {:result, conn, operation} end
        ]},
        {GenServer, [:passthrough], [
          call: fn _, msg ->
            {:reply, result, @state} = Datapio.Controller.handle_call(msg, self(), @state)
            result
          end
        ]}
      ]) do
        resp = TestController.run_operation(:op)
        assert resp == {:result, :k8s_conn, :op}
      end
    end

    test "run_operations/1" do
      with_mocks([
        {K8s.Client, [:passthrough], [
          async: fn conn, operations -> {:result, conn, operations} end
        ]},
        {GenServer, [:passthrough], [
          call: fn _, msg ->
            {:reply, result, @state} = Datapio.Controller.handle_call(msg, self(), @state)
            result
          end
        ]}
      ]) do
        resp = TestController.run_operations([:op1, :op2])
        assert resp == {:result, :k8s_conn, [:op1, :op2]}
      end
    end
  end

  describe "handle_info/2" do
    test "watch" do
      with_mock(K8s.Client, [:passthrough],
        list: fn api_version, kind, namespace: ns -> {:op, api_version, kind, ns} end,
        watch: fn conn, operation, stream_to: pid ->
          send(pid, {conn, operation})
          {:ok, :watcher}
        end
      ) do
        {:noreply, @state_watching} = Datapio.Controller.handle_info(:watch, @state)

        assert_receive {:k8s_conn, {:op, "example.com/v1", "Example", :all}}
      end
    end

    test "http async status" do
      assert {:noreply, @state_watching} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncStatus{code: 200},
        @state_watching
      )

      assert {:stop, :normal, @state_watching} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncStatus{code: 500},
        @state_watching
      )
    end

    test "http async headers" do
      assert {:noreply, @state_watching} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncHeaders{},
        @state_watching
      )
    end

    test "http async chunk" do
      chunk_id = "1"
      chunk = "{\"type\": \"ADDED\", \"object\": \"rsrc\"}"
      expected_state = state_with_chunk(@state_watching, chunk_id, chunk)

      assert {:noreply, expected_state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncChunk{id: chunk_id, chunk: chunk},
        @state_watching
      )

      chunk_id = "2"
      chunk = "{\"type\": \"MODIFIED\", \"object\": \"rsrc\"}"
      expected_state = state_with_chunk(@state_watching, chunk_id, chunk)

      assert {:noreply, expected_state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncChunk{id: chunk_id, chunk: chunk},
        @state_watching
      )

      chunk_id = "3"
      chunk = "{\"type\": \"DELETED\", \"object\": \"rsrc\"}"
      expected_state = state_with_chunk(@state_watching, chunk_id, chunk)

      assert {:noreply, expected_state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncChunk{id: chunk_id, chunk: chunk},
        @state_watching
      )
    end

    test "http async end" do
      chunk_id = "1"
      chunk = "{\"type\": \"ADDED\", \"object\": \"rsrc\"}"
      state = state_with_chunk(@state_watching, chunk_id, chunk)

      assert {:noreply, @state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncEnd{id: chunk_id},
        state
      )

      assert_receive {:added, "rsrc"}
      assert_receive :watch

      chunk_id = "2"
      chunk = "{\"type\": \"MODIFIED\", \"object\": \"rsrc\"}"
      state = state_with_chunk(@state_watching, chunk_id, chunk)

      assert {:noreply, @state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncEnd{id: chunk_id},
        state
      )

      assert_receive {:modified, "rsrc"}
      assert_receive :watch

      chunk_id = "3"
      chunk = "{\"type\": \"DELETED\", \"object\": \"rsrc\"}"
      state = state_with_chunk(@state_watching, chunk_id, chunk)

      assert {:noreply, @state} == Datapio.Controller.handle_info(
        %HTTPoison.AsyncEnd{id: chunk_id},
        state
      )

      assert_receive {:deleted, "rsrc"}
      assert_receive :watch
    end

    test "http timeout" do
      assert {:noreply, @state} == Datapio.Controller.handle_info(
        %HTTPoison.Error{reason: {:closed, :timeout}},
        @state_watching
      )

      assert_receive :watch
    end

    test "reconcile" do
      with_mock(K8s.Client, [:passthrough],
        run: fn _, _ -> {:ok, %{"items" => [@resource_success, @resource_failure]}} end
      ) do
        assert {:noreply, @state_cache} == Datapio.Controller.handle_info(
          :reconcile,
          @state_watching
        )

        assert_receive {:reconciled, @resource_success}
        assert_receive {:reconciled, @resource_failure}
        assert_receive :reconcile
      end
    end

    test "added" do
      {:noreply, new_state_success} = Datapio.Controller.handle_info(
        {:added, @resource_success},
        @state_watching
      )

      assert new_state_success.cache["SUCCESS"] == @resource_success
      assert_receive {:added, @resource_success}

      {:noreply, new_state_failed} = Datapio.Controller.handle_info(
        {:added, @resource_failure},
        @state_watching
      )

      assert new_state_failed.cache["FAILURE"] == @resource_failure
      assert_receive {:added, @resource_failure}
    end

    test "modified" do
      {:noreply, new_state} = Datapio.Controller.handle_info(
        {:modified, @resource_success},
        @state_cache
      )

      assert new_state.cache["SUCCESS"] == @resource_success
      refute_receive {:modified, @resource_success}

      {:noreply, new_state_v2} = Datapio.Controller.handle_info(
        {:modified, @resource_success_v2},
        @state_cache
      )

      assert new_state_v2.cache["SUCCESS"] == @resource_success_v2
      assert_receive {:modified, @resource_success_v2}

      {:noreply, new_state_fail} = Datapio.Controller.handle_info(
        {:modified, @resource_failure_v2},
        @state_cache
      )

      assert new_state_fail.cache["FAILURE"] == @resource_failure_v2
      assert_receive {:modified, @resource_failure_v2}
    end

    test "deleted" do
      {:noreply, new_state_success} = Datapio.Controller.handle_info(
        {:deleted, @resource_success},
        @state_cache
      )

      assert new_state_success.cache["SUCCESS"] == nil
      assert_receive {:deleted, @resource_success}

      {:noreply, new_state_failure} = Datapio.Controller.handle_info(
        {:deleted, @resource_failure},
        @state_cache
      )

      assert new_state_failure.cache["FAILURE"] == nil
      assert_receive {:deleted, @resource_failure}
    end
  end
end
