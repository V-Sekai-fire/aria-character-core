# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_security,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaSecurity.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_cloak, "~> 1.0"},
      {:ex_crypto, "~> 0.10"},
      {:rustler, "~> 0.36", optional: true},
      {:telemetry, "~> 1.2"}
    ]
  end
end
