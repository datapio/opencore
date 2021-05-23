defmodule Datapio.Controller do
  @moduledoc false

  use GenServer

  defstruct [
    :module,
    :api_version,
    :kind,
    :namespace,
    :conn,
    :poll_delay,
    :cache
  ]

  @callback add(map()) :: :ok | :error
  @callback modify(map()) :: :ok | :error
  @callback delete(map()) :: :ok | :error

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
    end
  end

  def start_link(module, opts) do
    options = [
      module: module,
      api_version: opts |> Keyword.fetch!(:api_version),
      kind: opts |> Keyword.fetch!(:kind),
      namespace: opts |> Keyword.get(:namespace, :all),
      poll_delay: opts |> Keyword.get(:poll_delay, 5000)
    ]
    GenServer.start_link(__MODULE__, options, name: module)
  end

  @impl true
  def init(opts) do
    conn = case System.get_env("KUBECONFIG") do
      nil -> K8s.Conn.from_service_account()
      path -> K8s.Conn.from_file(path)
    end

    send(self(), :list)
    {:ok, %Datapio.Controller{
      module: opts[:module],
      api_version: opts[:api_version],
      kind: opts[:kind],
      namespace: opts[:namespace],
      conn: conn,
      poll_delay: opts[:poll_delay],
      cache: %{}
    }}
  end

  @impl true
  def handle_info(:list, %Datapio.Controller{} = state) do
    resources =
      K8s.Client.list(state.api_version, state.kind, namespace: state.namespace)
        # Execute Query
        |> K8s.Client.run(state.conn)
        # Parse API Server Response
        |> (fn {:ok, %{ "items" => items }} -> items end).()
        # Split items into added/modified
        |> Stream.map(fn resource ->
          %{ "metadata" => %{ "uid" => uid }} = resource

          case state.cache[uid] do
            nil ->
              {:added, uid, resource}

            _ ->
              {:modified, uid, resource}
          end
        end)
        # Build Map from added/modified items with removed from cache
        |> Enum.reduce(
          %{ added: %{}, modified: %{}, deleted: state.cache },
          fn
            {:added, uid, resource}, resources -> %{
              added: resources[:added] |> Map.put(uid, resource),
              modified: resources[:modified],
              deleted: resources[:deleted] |> Map.delete(uid)
            }
            {:modified, uid, resource}, resources -> %{
              added: resources[:added],
              modified: resources[:modified] |> Map.put(uid, resource),
              deleted: resources[:deleted] |> Map.delete(uid)
            }
          end
        )

    resources = %{
      added: resources[:added] |> Map.values(),
      modified: resources[:modified] |> Map.values(),
      deleted: resources[:deleted] |> Map.values()
    }

    resources[:added]
      |> Map.values()
      |> Enum.map(&send(self(), {:added, &1}))

    resources[:modified]
      |> Map.values()
      |> Enum.map(&send(self(), {:modified, &1}))

    resources[:deleted]
      |> Map.values()
      |> Enum.map(&send(self(), {:deleted, &1}))

    Process.send_after(self(), :list, state.poll_delay)

    {:noreply, state}
  end

  def handle_info({:added, resource}, %Datapio.Controller{} = state) do
    %{ "metadata" => %{ "uid" => uid }} = resource
    :ok = apply(state.module, :add, [resource])

    cache = state.cache |> Map.put(uid, resource)

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end

  def handle_info({:modified, resource}, %Datapio.Controller{} = state) do
    %{ "metadata" => %{ "uid" => uid, "resourceVersion" => new_ver }} = resource
    %{ "metadata" => %{ "resourceVersion" => old_ver }} = state.cache[uid]

    cache = if old_ver != new_ver do
      :ok = apply(state.module, :modify, [resource])
      state.cache |> Map.put(uid, resource)
    else
      state.cache
    end

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end

  def handle_info({:deleted, resource}, state) do
    %{ "metadata" => %{ "uid" => uid }} = resource
    :ok = apply(state.module, :delete, [resource])
    cache = state.cache |> Map.delete(uid)

    {:noreply, %Datapio.Controller{state | cache: cache}}
  end
end
