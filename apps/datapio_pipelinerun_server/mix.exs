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
      extra_applications: [:logger, :datapio_cluster, :datapio_mq],
      mod: {DatapioPipelineRunServer.Application, []}
    ]
  end

  defp deps do
    [
      {
        # Cluster management application
        :datapio_cluster,
        in_umbrella: true
      },
      {
        # Kubernetes Operator framework
        :datapio_controller,
        in_umbrella: true
      },
      {
        # Message Queue application
        :datapio_mq,
        in_umbrella: true
      },
      {
        # Ensure single process across cluster
        :highlander, "~> 0.2"
      },
      {
        # Load Balance workload across cluster
        :horde, "~> 0.8"
      }
    ]
  end
end
