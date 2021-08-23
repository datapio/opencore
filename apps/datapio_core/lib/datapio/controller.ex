defmodule Datapio.Controller do
  @moduledoc """
  Provides behavior to observe Kubernetes resources.
  """

  require Logger
  use GenServer
  alias Datapio.Dependencies, as: Deps

  defstruct [
    :module,
    :api_version,
    :kind,
    :namespace,
    :conn,
    :watcher,
    :reconcile_delay,
    :cache
  ]

  @callback add(map()) :: :ok | :error
  @callback modify(map()) :: :ok | :error
  @callback delete(map()) :: :ok | :error
  @callback reconcile(map()) :: :ok | :error

  defmacro __using__(opts) do
    supervisor_opts = opts |> Keyword.get(:supervisor, [])

    quote do
      @behaviour Datapio.Controller

      def child_spec(_args) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []}
        } |> Supervisor.child_spec(unquote(supervisor_opts))
      end

      def start_link() do
        Datapio.Controller.start_link(__MODULE__, unquote(opts))
      end

      defp resource_schema do
        unquote(opts)
          |> Keyword.get(:schema, %{})
          |> JsonXema.new(loader: Datapio.SchemaLoader)
      end

      def validate_resource(%{} = resource) do
        JsonXema.validate(resource_schema(), resource)
      end

      def with_resource(%{} = resource, func) do
        try do
          validate_resource(resource)
            |> (fn {:ok, rsrc} -> rsrc end).()
            |> func.()
            |> (fn result -> {:ok, result} end).()
        rescue
          err -> {:error, err}
        end
      end

      def run_operation(operation) do
        GenServer.call(__MODULE__, {:run, operation})
      end

      def run_operations(operations) do
        GenServer.call(__MODULE__, {:async, operations})
      end
    end
  end

  def start_link(module, opts) do
    options = [
      module: module,
      api_version: opts |> Keyword.fetch!(:api_version),
      kind: opts |> Keyword.fetch!(:kind),
      namespace: opts |> Keyword.get(:namespace, :all),
      reconcile_delay: opts |> Keyword.get(:reconcile_delay, 30_000)
    ]
    GenServer.start_link(__MODULE__, options, name: module)
  end

  @impl true
  def init(opts) do
    {:ok, conn} = Datapio.K8sConn.lookup()

    self() |> send(:watch)
    self() |> Process.send_after(:reconcile, opts[:reconcile_delay])

    {:ok, %Datapio.Controller{
      module: opts[:module],
      api_version: opts[:api_version],
      kind: opts[:kind],
      namespace: opts[:namespace],
      conn: conn,
      watcher: nil,
      reconcile_delay: opts[:reconcile_delay],
      cache: %{}
    }}
  end

  @impl true
  def handle_call({:run, operation}, _from, %Datapio.Controller{} = state) do
    {:reply, Deps.get(:k8s_client).run(state.conn, operation), state}
  end

  @impl true
  def handle_call({:async, operations}, _from, %Datapio.Controller{} = state) do
    {:reply, Deps.get(:k8s_client).async(state.conn, operations), state}
  end

  @impl true
  def handle_info(:watch, %Datapio.Controller{} = state) do
    operation = Deps.get(:k8s_client).list(state.api_version, state.kind, namespace: state.namespace)
    {:ok, watcher} = Deps.get(:k8s_client).watch(state.conn, operation, stream_to: self())
    {:noreply, %Datapio.Controller{state | watcher: watcher}}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{code: 200}, %Datapio.Controller{} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{code: code}, %Datapio.Controller{} = state) do
    Logger.error([
      event: "watch",
      scope: "controller",
      module: state.module,
      api_version: state.api_version,
      kind: state.kind,
      reason: code
    ])
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncHeaders{}, %Datapio.Controller{} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, %Datapio.Controller{} = state) do
    event = Jason.decode!(chunk)

    case event["type"] do
      "ADDED" ->
        self() |> send({:added, event["object"]})

      "MODIFIED" ->
        self() |> send({:modified, event["object"]})

      "DELETED" ->
        self() |> send({:deleted, event["object"]})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncEnd{}, %Datapio.Controller{} = state) do
    self() |> send(:watch)
    {:noreply, %Datapio.Controller{state | watcher: nil}}
  end

  @impl true
  def handle_info(%HTTPoison.Error{reason: {:closed, :timeout}}, %Datapio.Controller{} = state) do
    self() |> send(:watch)
    {:noreply, %Datapio.Controller{state | watcher: nil}}
  end

  @impl true
  def handle_info(:reconcile, %Datapio.Controller{} = state) do
    Deps.get(:k8s_client).list(state.api_version, state.kind, namespace: state.namespace)
      # Execute Query
      |> (&(Deps.get(:k8s_client).run(state.conn, &1))).()
      # Parse API Server Response
      |> (fn {:ok, %{"items" => items}} -> items end).()
      |> Enum.each(fn resource ->
        :ok = apply(state.module, :reconcile, [resource])
      end)

    self() |> Process.send_after(:reconcile, state.reconcile_delay)

    {:noreply, state}
  end

  @impl true
  def handle_info({:added, resource}, %Datapio.Controller{} = state) do
    %{"metadata" => %{"uid" => uid}} = resource
    :ok = apply(state.module, :add, [resource])

    cache = state.cache |> Map.put(uid, resource)

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end

  @impl true
  def handle_info({:modified, resource}, %Datapio.Controller{} = state) do
    %{"metadata" => %{"uid" => uid, "resourceVersion" => new_ver}} = resource
    %{"metadata" => %{"resourceVersion" => old_ver}} = state.cache[uid]

    cache = if old_ver != new_ver do
      :ok = apply(state.module, :modify, [resource])
      state.cache |> Map.put(uid, resource)
    else
      state.cache
    end

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end

  @impl true
  def handle_info({:deleted, resource}, state) do
    %{"metadata" => %{"uid" => uid}} = resource
    :ok = apply(state.module, :delete, [resource])
    cache = state.cache |> Map.delete(uid)

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end
end
