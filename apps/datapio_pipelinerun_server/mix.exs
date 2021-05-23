defmodule DatapioPipelinerunServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :datapio_pipelinerun_server,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DatapioPipelinerunServer.Application, []}
    ]
  end

  defp deps do
    [
    ]
  end
end
