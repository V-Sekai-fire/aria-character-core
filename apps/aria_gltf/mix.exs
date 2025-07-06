# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGltf.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_gltf,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaGltf.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Mathematical operations and tensor support
      {:aria_math, in_umbrella: true},

      # Joint hierarchy and skeletal animation support
      {:aria_joint, in_umbrella: true},

      # JSON parsing for glTF files
      {:jason, "~> 1.4"},

      # Tensor operations for mesh transformations and image processing
      {:nx, "~> 0.10.0"},
      {:torchx, "~> 0.10"},

      # Image format support (JPG/PNG read/write)
      {:image, "~> 0.54"},

      # Development and testing
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
