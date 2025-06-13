# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Development environment configuration
config :logger, level: :debug

# Configure development databases (SQLite for weekend simplification)
# Main repository for general data
config :aria_data, AriaData.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_data_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Authentication repository for user data
config :aria_data, AriaData.AuthRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_auth_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 8

# Queue repository for background jobs
config :aria_data, AriaData.QueueRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_queue_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 8

# Storage repository for file metadata
config :aria_data, AriaData.StorageRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_storage_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 8

# Monitor repository for telemetry data
config :aria_data, AriaData.MonitorRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_monitor_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 6

# Engine repository for planning data
config :aria_data, AriaData.EngineRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_engine_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 6

# Development Phoenix configuration for coordinate service
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_secret_key_base_replace_in_production",
  watchers: []

# Configure Oban for development (used by queue service)
config :aria_queue, Oban,
  repo: AriaData.QueueRepo,
  notifier: Oban.Notifiers.PG,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    ai_generation: 5,
    planning: 10,
    storage_sync: 3,
    monitoring: 2
  ]

# Security Service development configuration (using mock for simplicity)
config :aria_security,
  secrets_module: AriaSecurity.SecretsMock,
  openbao_url: "http://localhost:8200",
  openbao_token: System.get_env("OPENBAO_DEV_TOKEN") || "dev-token"

# AI Service development configuration
config :aria_interpret,
  qwen_model_path: "/models/qwen3.onnx",
  gpu_enabled: System.get_env("ARIA_GPU_ENABLED") == "true",
  batch_size: 1

# Shape Service development configuration
config :aria_shape,
  qwen_model_path: "/models/qwen3.onnx",
  gpu_enabled: System.get_env("ARIA_GPU_ENABLED") == "true",
  batch_size: 1,
  grpo_enabled: true

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

# Interface Service development configuration
config :aria_interface, AriaInterfaceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_interface_secret_key_base"

# Monitor Service development configuration
config :aria_monitor,
  prometheus_enabled: false,
  live_dashboard_enabled: true

# Development Hammer rate limiting configuration
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}
