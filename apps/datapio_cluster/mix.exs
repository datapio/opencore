defmodule Datapio.Cluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :datapio_cluster,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mnesia],
      mod: {Datapio.Cluster.Application, []}
    ]
  end

  defp deps do
    [
      {
        # Automatic Node discovery
        :libcluster, "~> 3.2"
      },
      # Dev Dependencies
      {
        # Mocking framework
        :mock, "~> 0.3",
        only: :test,
        runtime: false
      }
    ]
  end
end
