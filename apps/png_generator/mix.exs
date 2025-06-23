# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule PngGenerator.MixProject do
  use Mix.Project

  def project do
    [
      app: :png_generator,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_png, path: "../elixir_png"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Pure Elixir PNG generation for timeline and Gantt chart visualization.
    No external dependencies required - generates PNG files directly from Elixir data structures.
    """
  end

  defp package do
    [
      name: "png_generator",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/png_generator"}
    ]
  end

  defp docs do
    [
      main: "PngGenerator",
      extras: ["README.md"]
    ]
  end
end
