# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_qcp,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaQcp.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aria_state, path: "../aria_state"},
      {:aria_math, in_umbrella: true},
      {:nx, "~> 0.10.0"},
      {:torchx, "~> 0.10"},
    ]
  end
end
