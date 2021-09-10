defmodule ProjectOperator.MixProject do
  use Mix.Project

  def project do
    [
      app: :project_operator,
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
      extra_applications: [:logger, :datapio_cluster, :pipelinerun_server],
      mod: {ProjectOperator.Application, []}
    ]
  end

  defp deps do
    [
      {:highlander, "~> 0.2"},
      {:datapio_cluster, in_umbrella: true},
      {:datapio_k8s, in_umbrella: true},
      {:datapio_controller, in_umbrella: true},
      {:pipelinerun_server, in_umbrella: true}
    ]
  end
end
