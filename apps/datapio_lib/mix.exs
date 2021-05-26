defmodule DatapioLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :datapio_lib,
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.2"},
      {:k8s, "~> 0.5"},
      {:norm, "~> 0.12"}
    ]
  end
end
