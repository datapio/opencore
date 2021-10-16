defmodule Datapio.Test.K8s.Event do
  use ExUnit.Case
  import Mock

  alias Datapio.K8s.Event

  @other_resource %{
    "apiVersion" => "example.com/v1",
    "kind" => "Example",
    "metadata" => %{
      "name" => "example",
      "namespace" => "default",
      "uid" => "UUID"
    }
  }

  @event_resource %{
    "apiVersion" => "events.k8s.io/v1",
    "kind" => "Event",
    "metadata" => %{
      "generateName" => "some-prefix-",
      "namespace" => "default"
    },
    "action" => "test",
    "reportingController" => "datapio-test-suite",
    "reportingInstance" => "datapio-test-suite-0",
    "regarding" => %{
      "apiVersion" => "example.com/v1",
      "kind" => "Example",
      "namespace" => "default",
      "name" => "example",
      "uid" => "UUID"
    },
    "related" => %{
      "apiVersion" => "example.com/v1",
      "kind" => "Example",
      "namespace" => "default",
      "name" => "example",
      "uid" => "UUID"
    },
    "type" => "Normal",
    "reason" => "TestMessage",
    "note" => "This is an example",
    "eventTime" => "2021-10-16T12:00:00.000000Z"
  }

  test "builder" do
    with_mocks([
      {K8s.Client, [:passthrough], [
        create: fn resource -> {:operation, :create, resource} end,
        run: fn :conn, {:operation, :create, resource} -> {:ok, resource} end
      ]}
    ]) do
      result = Event.new(name: "some-prefix", namespace: "default")
        |> Event.action("test")
        |> Event.reporting_controller("datapio-test-suite")
        |> Event.reporting_instance("datapio-test-suite-0")
        |> Event.regarding(@other_resource)
        |> Event.related(@other_resource)
        |> Event.type(:normal)
        |> Event.reason("TestMessage")
        |> Event.message("This is an example")
        |> Event.time(DateTime.new!(~D[2021-10-16], ~T[12:00:00.000], "Etc/UTC"))
        |> Event.publish(:conn)

      assert result == {:ok, @event_resource}
    end
  end
end
