defmodule AriaViewer.MixProject do
  use Mix.Project

  def project do
    [
      listeners: [Phoenix.CodeReloader],
      app: :aria_viewer,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaViewer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:gettext, "~> 0.20"},
      {:mox, "~> 1.0", only: [:test]},  # Required for WebSocket testing
      {:aria_ewbik, in_umbrella: true},
      {:aria_joint, in_umbrella: true},
      {:aria_gltf, in_umbrella: true}
    ]
  end
end
