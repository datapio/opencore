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
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :datapio_core],
      mod: {DatapioPipelinerunServer.Application, []}
    ]
  end

  defp deps do
    [
      {:datapio_core, in_umbrella: true},  # Datapio Core Library
      {:highlander, "~> 0.2"},             # Ensure single process across cluster
      {:horde, "~> 0.8"},                  # Load Balance workload across cluster
      {:amqp, "~> 2.1"},                   # RabbitMQ client
    ]
  end
end
