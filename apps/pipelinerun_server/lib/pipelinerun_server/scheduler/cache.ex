defmodule PipelineRunServer.Scheduler.Cache do
  @moduledoc false

  alias :mnesia, as: Mnesia

  @spec get(atom(), Datapio.K8s.Resource.t()) ::
    :miss
    | {:hit, Datapio.K8s.Resource.t()}
    | {:error, term()}

  def get(kind, resource) do
    %{"metadata" => %{"uid" => uid}} = resource

    response = Mnesia.transaction(fn ->
      match = ETS.fun2ms(fn resource -> resource["metadata"]["uid"] == uid end)
      case Mnesia.select(kind, match) do
        [] -> :miss
        [{^uid, req}] -> {:hit, req}
      end
    end)

    case response do
      {:atomic, result} ->
        result

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  @spec put(atom(), Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def put(kind, resource) do
    response = Mnesia.transaction(fn ->
      record = %{
        uid: resource["metadata"]["uid"],
        resource: resource
      }
      Mnesia.write(kind, resource, :write)
    end)

    case response do
      {:atomic, :ok} ->
        :ok

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  @spec clear(atom(), Datapio.K8s.Resource.t()) :: :ok | {:error, term()}
  def clear(kind, resource) do
    response = Mnesia.transaction(fn ->
      Mnesia.delete(kind, resource["metadata"]["uid"], :write)
    end)

    case response do
      {:atomic, :ok} ->
        :ok

      {:aborted, reason} ->
        {:error, reason}
    end
  end
end
