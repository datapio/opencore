defmodule DatapioProjectOperator.Controller do
  @moduledoc false

  use GenServer
  alias DatapioProjectOperator.Resources, as: Resources

  @poll_delay 5000
  @api_version "datapio.co/v1"
  @kind :project

  def start_link(args) do
    GenServer.start_link(__MODULE__, [args], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    with {:ok, conn} <- K8s.Conn.lookup(:default)
    do
      send(self(), :list)
      {:ok, [conn: conn, cache: %{}]}

    else
      err -> {:stop, err}
    end
  end

  @impl true
  def handle_info(:list, state) do
    conn = state[:conn]
    cache = state[:cache]
    pid = self()

    K8s.Client.list(@api_version, @kind, namespace: :all)
      # Execute Query
      |> K8s.Client.run(conn)
      # Parse API Server Response
      |> (fn {:ok, %{ "items" => items }} -> items end).()
      # Split items into added/modified
      |> Stream.map(fn resource ->
        %{ "metadata" => %{ "uid" => uid }} = resource

        case cache[uid] do
          nil ->
            {:added, uid, resource}

          _ ->
            {:modified, uid, resource}
        end
      end)
      # Build Map from added/modified items with removed from cache
      |> Enum.reduce(
        %{ added: %{}, modified: %{}, deleted: cache },
        fn
          {:added, uid, resource}, resources ->
            %{
              added: resources[:added] |> Map.put(uid, resource),
              modified: resources[:modified],
              deleted: resources[:deleted] |> Map.delete(uid)
            }
          {:modified, uid, resource}, resources ->
            %{
              added: resources[:added],
              modified: resources[:modified] |> Map.put(uid, resource),
              deleted: resources[:deleted] |> Map.delete(uid)
            }
        end
      )
      # Transform submaps into arrays
      |> (fn resources -> %{
        added: resources[:added] |> Map.values(),
        modified: resources[:modified] |> Map.values(),
        deleted: resources[:deleted] |> Map.values()
      } end).()
      # Send events
      |> (fn resources ->
        resources[:added] |> Enum.map(&send(self(), {:added, &1}))
        resources[:modified] |> Enum.map(&send(self(), {:modified, &1}))
        resources[:deleted] |> Enum.map(&send(self(), {:deleted, &1}))
      end).()

    Process.send_after(pid, :list, @poll_delay)

    {:noreply, [conn: conn, cache: cache]}
  end

  def handle_info({:added, resource}, state) do
    IO.puts("ADDED #{resource["metadata"]["name"]}")
    conn = state[:conn]
    cache = state[:cache]

    %{ "metadata" => %{ "uid" => uid }} = resource
    :ok = resource |> reconcile(conn)

    cache = cache |> Map.put(uid, resource)

    {:noreply, [conn: conn, cache: cache]}
  end

  def handle_info({:modified, resource}, state) do

    conn = state[:conn]
    cache = state[:cache]

    %{ "metadata" => %{ "uid" => uid, "resourceVersion" => new_ver }} = resource
    %{ "metadata" => %{ "resourceVersion" => old_ver }} = cache[uid]

    cache = if old_ver != new_ver do
      IO.puts("MODIFIED #{resource["metadata"]["name"]}")
      :ok = resource |> reconcile(conn)
      cache |> Map.put(uid, resource)
    else
      cache
    end

    {:noreply, [conn: conn, cache: cache]}
  end

  def handle_info({:deleted, resource}, state) do
    IO.puts("DELETED #{resource["metadata"]["name"]}")
    conn = state[:conn]
    cache = state[:cache]

    %{ "metadata" => %{ "uid" => uid }} = resource
    cache = cache |> Map.delete(uid)

    {:noreply, [conn: conn, cache: cache]}
  end

  defp reconcile(resource, conn) do
    :ok
  end
end
