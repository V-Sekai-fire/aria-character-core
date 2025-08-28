# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
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
      # Internal dependencies
      {:aria_state, in_umbrella: true},
      # External dependencies
      {:jason, "~> 1.4"},
      {:timex, "~> 3.7"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
