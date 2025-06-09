# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_auth,
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
      mod: {AriaAuth.Application, []}
    ]
  end

  defp deps do
    [
      # Authentication and authorization
      {:guardian, "~> 2.3"},
      {:joken, "~> 2.6"},
      {:bcrypt_elixir, "~> 3.0"},
      
      # OAuth2 and OIDC
      {:oauth2, "~> 2.1"},
      {:oidc, "~> 0.5.0"},
      
      # WebRTC for real-time identity verification
      {:ex_webrtc, "~> 0.3"},
      
      # HTTP client for external identity providers
      {:req, "~> 0.4"},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # Security service integration
      {:aria_security, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end