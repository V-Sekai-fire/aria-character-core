# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Configure AriaEngine domain providers for development
config :aria_engine,
  domain_providers: [
    AriaEngine.BasicActionsDomainProvider,
    # Add more providers as needed in development
  ]

# Development environment configuration
config :logger, level: :info


# Configure Membrane Job Processor for development (replaces Oban)
# config :aria_queue, AriaQueue.MembraneJobProcessor,
#   queues: %{
#     # Temporal planner queues (Resolution 2)
#     sequential_actions: 1,    # Single worker for strict temporal ordering
#     parallel_actions: 5,      # Multi-worker for concurrent execution
#     instant_actions: 3,       # High-priority immediate responses
#     # Legacy application queues
#     ai_generation: 5,
#     planning: 10,
#     storage_sync: 3,
#     monitoring: 2
#   }

# Security Service development configuration (using mock for simplicity)
config :aria_security,
  secrets_module: AriaSecurity.SecretsMock,
  openbao_url: "http://localhost:8200",
  openbao_token: System.get_env("OPENBAO_DEV_TOKEN") || "dev-token"

# Storage Service development configuration
config :aria_storage,
  backend: :local,
  local_path: "tmp/storage",
  chunk_size: 64 * 1024,
  cdn_enabled: false

# Authentication Service development configuration
config :aria_auth,
  macaroon_secret: "development_macaroon_secret_key",
  session_ttl: 3600,
  webrtc_enabled: false

# Monitor Service development configuration
config :aria_monitor,
  prometheus_enabled: false,
  live_dashboard_enabled: true

# Development Hammer rate limiting configuration
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
