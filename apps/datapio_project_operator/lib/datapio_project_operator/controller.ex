defmodule DatapioProjectOperator.Controller do
  @moduledoc false

  use Datapio.Controller,
    api_version: "datapio.co/v1",
    kind: :project,
    schema: schema(%{
      "spec" => schema(%{
        "ingress" => one_of([
          schema(%{
            "enabled" => false
          }),
          schema(%{
            "enabled" => true,
            "host" => spec(is_binary() and &(String.length(&1) > 0)),
            "labels" => one_of([
              nil,
              spec(is_map())
            ]),
            "annotations" => one_of([
              nil,
              spec(is_map())
            ]),
            "tls" => one_of([
              nil,
              false,
              spec(is_binary() and &(String.length(&1) > 0))
            ])
          })
        ]),
        "webhooks" => coll_of(schema(%{
          "name" => spec(is_binary() and &(String.length(&1) > 0)),
          "max_concurrent_jobs" => spec(is_integer() and &(&1 > 0)),
          "history" => spec(is_integer() and &(&1 >= 0))
        }))
      })
    })


  @impl true
  def add(resource) do
    IO.puts("ADDED #{resource["metadata"]["name"]}")
    :ok
  end

  @impl true
  def modify(resource) do
    IO.puts("MODIFIED #{resource["metadata"]["name"]}")
    :ok
  end

  @impl true
  def delete(resource) do
    IO.puts("DELETED #{resource["metadata"]["name"]}")
    :ok
  end
end
