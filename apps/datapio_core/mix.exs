defmodule DatapioLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :datapio_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/mocks"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {Datapio.Application, []}
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.2"},  # Automatic Node discovery
      {:k8s, "~> 1.0"},         # Kubernetes Client
      {:json_xema, "~> 0.6"}    # JSON Schema validation
    ]
  end
end
