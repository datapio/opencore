# Datapio.K8s

This project provides some utility functions to work with the
[k8s](https://hexdocs.pm/k8s/readme.html) library, such as:

 - connection lookup
 - resource schema validation
 - owner references manipulation
 - ...

## Installation

The package can be installed by adding `datapio_k8s` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {
      :datapio_k8s,
      github: "datapio/opencore",
      ref: "main",
      sparse: "apps/datapio_k8s"
    }
  ]
end
```
