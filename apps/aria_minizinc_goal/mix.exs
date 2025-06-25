# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMinizincGoal.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_minizinc_goal,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
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
      {:aria_minizinc_executor, in_umbrella: true},
      {:fixpoint, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:timex, "~> 3.7"}
    ]
  end
end
