# Datapio.Controller

A `Datapio.Controller` is a wrapper around
[k8s](https://hexdocs.pm/k8s/readme.html), providing the tools to build
Kubernetes operators.

## Installation

The package can be installed by adding `datapio_controller` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {
      :datapio_controller,
      github: "datapio/opencore",
      ref: "main",
      sparse: "apps/datapio_controller"
    }
  ]
end
```
