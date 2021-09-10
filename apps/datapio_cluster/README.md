# Datapio.Cluster

Integrate [libcluster](https://hexdocs.pm/libcluster/readme.html) into an OTP
application.

## Installation

The package can be installed by adding `datapio_cluster` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {
      :datapio_cluster,
      github: "datapio/opencore",
      ref: "main",
      sparse: "apps/datapio_cluster"
    }
  ]
end
```

Then add the `datapio_cluster` application to the list of extra applications:

```elixir
def application do
  [
    extra_applications: [:logger, :datapio_cluster]
  ]
end
```
