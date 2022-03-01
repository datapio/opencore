defmodule Datapio.K8s.MixProject do
  use Mix.Project

  def project do
    [
      app: :datapio_k8s,
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {
        # Kubernetes Client
        :k8s, "~> 1.1"
      },
      {
        # JSON Schema validation
        :json_xema, "~> 0.6"
      },
      {
        # JSON Encoder/Decoder
        :jason, "~> 1.2"
      },
      {
        # extended DateTime library
        :calendar, "~> 1.0.0"
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
