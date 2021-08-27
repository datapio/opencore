defmodule DatapioProjectOperator.MixProject do
  use Mix.Project

  def project do
    [
      app: :datapio_project_operator,
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
      extra_applications: [:logger, :datapio_core],
      mod: {DatapioProjectOperator.Application, []}
    ]
  end

  defp deps do
    [
      {:highlander, "~> 0.2"},
      {:datapio_core, in_umbrella: true},
      {:datapio_pipelinerun_server, in_umbrella: true}
    ]
  end
end
