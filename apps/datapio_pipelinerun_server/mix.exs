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
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/mocks"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:lager, :logger, :amqp, :mnesia, :datapio_core],
      mod: {DatapioPipelineRunServer.Application, []}
    ]
  end

  defp deps do
    [
      {:datapio_core, in_umbrella: true},  # Datapio Core Library
      {:highlander, "~> 0.2"},             # Ensure single process across cluster
      {:horde, "~> 0.8"},                  # Load Balance workload across cluster
      {:amqp, "~> 3.0"},                   # RabbitMQ client
    ]
  end
end
