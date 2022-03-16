defmodule Datapio.Controller do
  @moduledoc """
  Behaviour used to implement a Kubernetes operator.

  Example:

  ```elixir
  defmodule MyApp.MyOperator do
    use Datapio.Controller,
      api_version: "v1"
      kind: "Pod"

    @impl true
    def add(pod, _opts) do
      :ok
    end

    @impl true
    def modify(pod, _opts) do
      :ok
    end

    @impl true
    def delete(pod, _opts) do
      :ok
    end

    @impl true
    def reconcile(pod, _opts) do
      :ok
    end
  end
  ```
  """

  @type schema :: Datapio.K8s.Resource.schema()
  @type resource :: Datapio.K8s.Resource.resource()

  @typedoc "Options passed to the controller's callbacks"
  @type controller_options :: keyword()

  @typedoc "Option controlling what Kubernetes resources are watched"
  @type watch_option ::
    {:api_version, String.t()}
    | {:kind, String.t()}
    | {:namespace, :all | String.t()}
    | {:reconcile_delay, non_neg_integer()}

  @typedoc "Option controlling how the `Datapio.Controller` should be supervised"
  @type supervisor_option ::
    {:restart, :temporary | :transient | :permanent}
    | {:shutdown, timeout() | :brutal_kill}

  @type supervisor_options :: [supervisor_option()]

  @typedoc "Option passed to `start_link/2`"
  @type start_option ::
    watch_option()
    | {:options, controller_options()}

  @type start_options :: [start_option(), ...]

  @typedoc "Default options "
  @type module_option ::
    watch_option()
    | {:schema, schema()}
    | {:supervisor, supervisor_options()}

  @type module_options :: [module_option(), ...]

  @callback add(resource(), controller_options()) :: :ok | {:error, term()}
  @callback modify(resource(), controller_options()) :: :ok | {:error, term()}
  @callback delete(resource(), controller_options()) :: :ok | {:error, term()}
  @callback reconcile(resource(), controller_options()) :: :ok | {:error, term()}

  defmodule State do
    @moduledoc false

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
  end

  require Logger
  use GenServer

  @spec __using__(module_options()) :: Macro.t
  defmacro __using__(opts) do
    supervisor_opts = opts |> Keyword.get(:supervisor, [])

    quote do
      @behaviour Datapio.Controller

      @type schema :: Datapio.Controller.schema()
      @type resource :: Datapio.Controller.resource()

      @type controller_options :: Datapio.Controller.controller_options()

      @doc "Return a specification to run the controller under a supervisor"
      @spec child_spec(controller_options()) :: Supervisor.child_spec()
      def child_spec(args) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, args}
        } |> Supervisor.child_spec(unquote(supervisor_opts))
      end

      @doc "Start a controller linked to the current process with no options"
      @spec start_link() :: GenServer.on_start()
      def start_link() do
        start_link([])
      end

      @doc "Start a controller linked to the current process"
      @spec start_link(controller_options()) :: GenServer.on_start()
      def start_link(options) do
        args = unquote(opts) |> Keyword.merge([options: options])
        Datapio.Controller.start_link(__MODULE__, args)
      end

      @doc "Return the schema configured for this controller"
      @spec schema() :: schema()
      def schema do
        unquote(opts)
          |> Keyword.get(:schema, %{})
      end

      @doc "Validate a resource against this controller's schema"
      @spec validate_resource(resource()) :: :ok | {:error, term()}
      def validate_resource(resource) do
        Datapio.K8s.Resource.validate(resource, schema())
      end

      @doc "Run a function with resource only if the resource is validated"
      @spec with_resource(resource(), (resource() -> any())) :: {:ok, any()} | {:error, term()}
      def with_resource(resource, func) do
        case validate_resource(resource) do
          :ok ->
            try do
              {:ok, func.(resource)}

            rescue
              err ->
                {:error, err}
            end

          err ->
            err
        end
      end

      @doc "Run a Kubernetes operation using this controller's connection"
      @spec run_operation(K8s.Operation.t()) :: {:ok, any()} | {:error, term()}
      def run_operation(operation) do
        GenServer.call(__MODULE__, {:run, operation})
      end

      @doc "Run many Kubernetes operations in parallel using this controller's connection"
      @spec run_operations([K8s.Operation.t(), ...]) :: [{:ok, any()} | {:error, term()}]
      def run_operations(operations) do
        GenServer.call(__MODULE__, {:async, operations})
      end
    end
  end

  @doc "Start a controller linked to the current process"
  @spec start_link(module(), start_options()) :: GenServer.on_start()
  def start_link(module, opts) do
    options = [
      module: module,
      api_version: opts |> Keyword.fetch!(:api_version),
      kind: opts |> Keyword.fetch!(:kind),
      namespace: opts |> Keyword.get(:namespace, :all),
      reconcile_delay: opts |> Keyword.get(:reconcile_delay, 30_000),
      options: opts |> Keyword.get(:options, [])
    ]
    GenServer.start_link(__MODULE__, options, name: module)
  end

  @impl true
  def init(opts) do
    {:ok, conn} = Datapio.K8s.Conn.lookup()

    self() |> send(:watch)
    self() |> send(:reconcile)

    {:ok, %State{
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
  def handle_call({:run, operation}, _from, %State{} = state) do
    {:reply, K8s.Client.run(state.conn, operation), state}
  end

  @impl true
  def handle_call({:async, operations}, _from, %State{} = state) do
    {:reply, K8s.Client.async(state.conn, operations), state}
  end

  @impl true
  def handle_info(:watch, %State{} = state) do
    operation = K8s.Client.list(state.api_version, state.kind, namespace: state.namespace)
    {:ok, watcher} = K8s.Client.watch(state.conn, operation, stream_to: self())
    {:noreply, %State{state | watcher: watcher}}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{code: 200}, %State{} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{code: code}, %State{} = state) do
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
  def handle_info(%HTTPoison.AsyncHeaders{}, %State{} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, %State{} = state) do
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
  def handle_info(%HTTPoison.Error{id: id, reason: {:closed, :timeout}}, %State{} = state) do
    self() |> send(:watch)
    {:noreply, %State{state | watcher: nil}}
  end

  @impl true
  def handle_info(:reconcile, %State{} = state) do
    operation = K8s.Client.list(state.api_version, state.kind, namespace: state.namespace)
    {:ok, %{"items" => items}} = K8s.Client.run(state.conn, operation)

    cache = items |> Enum.reduce(state.cache, fn resource, cache ->
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

      cache |> Map.put(uid, resource)
    end)

    self() |> Process.send_after(:reconcile, state.reconcile_delay)

    {:noreply, %State{state | cache: cache}}
  end

  @impl true
  def handle_info({:added, resource}, %State{} = state) do
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

    {:noreply, %State{state | cache: cache}}
  end

  @impl true
  def handle_info({:modified, resource}, %State{} = state) do
    %{"metadata" => %{"uid" => uid, "resourceVersion" => new_ver}} = resource
    old_ver = state.cache[uid]["metadata"]["resourceVersion"]

    cache = cond do
      old_ver == nil ->
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

        state.cache |> Map.put(uid, resource)

      old_ver != new_ver ->
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

      true ->
        state.cache
    end

    {:noreply, %State{state | cache: cache}}
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

    {:noreply, %State{state | cache: cache}}
  end
end
