defmodule Datapio.K8s.Event do
  @moduledoc """
  This module allows you to create and publish custom Kubernetes Events.
  For more information about the Event spec, please read this
  [reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#event-v1-events-k8s-io).

  Usage example:

  ```elixir
  alias Datapio.K8s.Event

  {:ok, conn} = Datapio.K8s.Conn.lookup()
  operation = K8s.Client.get("apps/v1", :deployment, [namespace: "default", name: "nginx-deployment"])
  {:ok, deployment} = K8s.Client.run(conn, operation)

  Event.new(name: "some-prefix", namespace: "default")
    |> Event.action("notify")
    |> Event.reporting_controller("my-app")
    |> Event.reporting_instance("my-app-0")
    |> Event.regarding(deployment)
    |> Event.type(:normal)
    |> Event.reason("TestMessage")
    |> Event.message("This is an example")
    |> Event.time(:now)
    |> Event.publish(conn)
  ```
  """

  alias Datapio.K8s.Resource

  @typedoc "Represent a Kubernetes Event"
  @type t :: Resource.t()

  @typedoc "Represent a partial Kubernetes Event (not publishable yet)"
  @type partial :: t()

  @doc "Create a new event"
  @spec new(name: String.t(), namespace: String.t()) :: partial()
  def new(name: name, namespace: namespace) do
    %{
      "apiVersion" => "events.k8s.io/v1",
      "kind" => "Event",
      "metadata" => %{
        "generateName" => "#{name}-",
        "namespace" => namespace
      }
    }
  end

  @doc "Specify what action was taken/failed"
  @spec action(partial(), String.t()) :: partial()
  def action(event, name) do
    %{event | "action" => name}
  end

  @doc "Specify the name of the controller that emitted this Event"
  @spec reporting_controller(partial(), String.t()) :: partial()
  def reporting_controller(event, name) do
    %{event | "reportingController" => name}
  end

  @doc "Specify the ID of the controller instance"
  @spec reporting_instance(partial(), String.t()) :: partial()
  def reporting_instance(event, name) do
    %{event | "reportingInstance" => name}
  end

  @doc "Specify the object this event is about"
  @spec regarding(partial(), Resource.t()) :: partial()
  def regarding(event, resource) do
    %{event | "regarding" => Resource.get_ref(resource)}
  end

  @doc "Specify a secondary object this event is related to"
  @spec related(partial(), Resource.t()) :: partial()
  def related(event, resource) do
    %{event | "related" => Resource.get_ref(resource)}
  end

  @doc "Specify the type of the event"
  @spec type(partial(), :normal | :warning) :: partial()
  def type(event, :normal) do
    %{event | "type" => "Normal"}
  end
  def type(event, :warning) do
    %{event | "type" => "Warning"}
  end

  @doc "Specify the reason of the event"
  @spec reason(partial(), String.t()) :: partial()
  def reason(event, val) do
    %{event | "reason" => val}
  end

  @doc "Specify the time at which the event was first observed"
  @spec time(partial(), :now | DateTime.t()) :: partial()
  def time(event, :now) do
    event |> time(Calendar.DateTime.now!("UTC"))
  end
  def time(event, dt) do
    %{event | "eventTime" => dt |> Calendar.DateTime.Format.rfc3339(6)}
  end

  @doc "Specify the message describing this event"
  @spec message(partial(), String.t()) :: partial()
  def message(event, val) do
    %{event | "note" => val}
  end

  @doc "Publish the event to Kubernetes"
  @spec publish(t(), K8s.Conn.t()) :: {:ok, any()} | {:error, term()}
  def publish(event, conn) do
    K8s.Client.create(event) |> then(&K8s.Client.run(conn, &1))
  end
end
