defmodule ElixirPng.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_png,
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Pure Elixir PNG encoding library.
    Creates PNG files without external dependencies using only Elixir and Erlang standard library.
    """
  end

  defp package do
    [
      name: "elixir_png",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/elixir_png"}
    ]
  end

  defp docs do
    [
      main: "ElixirPng",
      extras: ["README.md"]
    ]
  end
end
