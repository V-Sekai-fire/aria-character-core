defmodule AriaBmeshDomain.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_bmesh_domain,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaBmeshDomain.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aria_core, git: "https://github.com/V-Sekai-fire/aria-hybrid-planner.git", sparse: "apps/aria_core"}
    ]
  end
end
