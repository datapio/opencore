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
    :cache,
    :options
  ]

  @callback add(map(), keyword()) :: :ok | :error
  @callback modify(map(), keyword()) :: :ok | :error
  @callback delete(map(), keyword()) :: :ok | :error
  @callback reconcile(map(), keyword()) :: :ok | :error

  defmacro __using__(opts) do
    supervisor_opts = opts |> Keyword.get(:supervisor, [])

    quote do
      @behaviour Datapio.Controller

      def child_spec(args) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, args}
        } |> Supervisor.child_spec(unquote(supervisor_opts))
      end

      def start_link() do
        start_link([])
      end

      def start_link(extra_opts) do
        args = unquote(opts) |> Keyword.merge([extra_opts: extra_opts])
        Datapio.Controller.start_link(__MODULE__, args)
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
      reconcile_delay: opts |> Keyword.get(:reconcile_delay, 30_000),
      options: opts |> Keyword.get(:extra_opts, [])
    ]
    GenServer.start_link(__MODULE__, options, name: module)
  end

  @impl true
  def init(opts) do
    {:ok, conn} = Datapio.K8sConn.lookup()

    self() |> send(:watch)
    self() |> send(:reconcile)

    {:ok, %Datapio.Controller{
      module: opts[:module],
      api_version: opts[:api_version],
      kind: opts[:kind],
      namespace: opts[:namespace],
      conn: conn,
      watcher: nil,
      reconcile_delay: opts[:reconcile_delay],
      cache: %{},
      options: opts[:options]
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
    operation = Deps.get(:k8s_client).list(state.api_version, state.kind, namespace: state.namespace)
    {:ok, %{"items" => items}} = Deps.get(:k8s_client).run(state.conn, operation)

    items |> Enum.each(fn resource ->
      %{"metadata" => %{"uid" => uid}} = resource

      case apply(state.module, :reconcile, [resource, state.options]) do
        :ok -> :ok
        {:error, reason} ->
          Logger.error([
            event: "reconcile",
            scope: "controller",
            module: state.module,
            api_version: state.api_version,
            kind: state.kind,
            uid: uid,
            reason: reason
          ])
      end
    end)

    self() |> Process.send_after(:reconcile, state.reconcile_delay)

    {:noreply, state}
  end

  @impl true
  def handle_info({:added, resource}, %Datapio.Controller{} = state) do
    %{"metadata" => %{"uid" => uid}} = resource

    case apply(state.module, :add, [resource, state.options]) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error([
          event: "added",
          scope: "controller",
          module: state.module,
          api_version: state.api_version,
          kind: state.kind,
          uid: uid,
          reason: reason
        ])
    end

    cache = state.cache |> Map.put(uid, resource)

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end

  @impl true
  def handle_info({:modified, resource}, %Datapio.Controller{} = state) do
    %{"metadata" => %{"uid" => uid, "resourceVersion" => new_ver}} = resource
    %{"metadata" => %{"resourceVersion" => old_ver}} = state.cache[uid]

    cache = if old_ver != new_ver do
      case apply(state.module, :modify, [resource, state.options]) do
        :ok -> :ok
        {:error, reason} ->
          Logger.error([
            event: "modified",
            scope: "controller",
            module: state.module,
            api_version: state.api_version,
            kind: state.kind,
            uid: uid,
            reason: reason
          ])
      end

      state.cache |> Map.put(uid, resource)
    else
      state.cache
    end

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end

  @impl true
  def handle_info({:deleted, resource}, state) do
    %{"metadata" => %{"uid" => uid}} = resource

    case apply(state.module, :delete, [resource, state.options]) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error([
          event: "deleted",
          scope: "controller",
          module: state.module,
          api_version: state.api_version,
          kind: state.kind,
          uid: uid,
          reason: reason
        ])
    end

    cache = state.cache |> Map.delete(uid)

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end
end
