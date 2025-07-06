# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEwbik.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_ewbik,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaEwbik.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Mathematical foundation
      {:aria_math, in_umbrella: true},

      # Joint hierarchy management
      {:aria_joint, in_umbrella: true},

      # Quaternion Characteristic Polynomial algorithm
      {:aria_qcp, in_umbrella: true},

      # State management for VRM1 configuration
      {:aria_state, in_umbrella: true},

      # Development and testing
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Entirely Wahba's-problem Based Inverse Kinematics (EWBIK) solver with
    multi-effector coordination, VRM1 collision detection, and anatomical constraints.
    """
  end

  defp package do
    [
      name: "aria_ewbik",
      files: ~w(lib mix.exs README.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/iFire/aria-character-core"}
    ]
  end

  defp docs do
    [
      main: "AriaEwbik",
      source_url: "https://github.com/iFire/aria-character-core",
      extras: ["README.md"]
    ]
  end
end
