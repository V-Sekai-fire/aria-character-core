# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Development environment configuration
config :logger, level: :debug

# Configure development databases (PostgreSQL adapter for CockroachDB compatibility)
# Main repository for general data
config :aria_data, AriaData.Repo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_data_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  adapter: Ecto.Adapters.Postgres

config :aria_data, AriaData.Repo,
  database: "aria_data_dev.sqlite3",
  pool_size: 10

# Authentication repository for user data
config :aria_data, AriaData.AuthRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_auth_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 8,
  adapter: Ecto.Adapters.Postgres

config :aria_data, AriaData.AuthRepo,
  database: "aria_auth_dev.sqlite3",
  pool_size: 10

# Queue repository for background jobs
config :aria_data, AriaData.QueueRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_queue_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 8,
  adapter: Ecto.Adapters.Postgres

config :aria_data, AriaData.QueueRepo,
  database: "aria_queue_dev.sqlite3",
  pool_size: 10

# Storage repository for file metadata
config :aria_data, AriaData.StorageRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_storage_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 8,
  adapter: Ecto.Adapters.Postgres

config :aria_data, AriaData.StorageRepo,
  database: "aria_storage_dev.sqlite3",
  pool_size: 10

# Monitor repository for telemetry data
config :aria_data, AriaData.MonitorRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_monitor_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 6,
  adapter: Ecto.Adapters.Postgres

config :aria_data, AriaData.MonitorRepo,
  database: "aria_monitor_dev.sqlite3",
  pool_size: 10

# Engine repository for planning data
config :aria_data, AriaData.EngineRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_engine_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 6,
  adapter: Ecto.Adapters.Postgres

config :aria_data, AriaData.EngineRepo,
  database: "aria_engine_dev.sqlite3",
  pool_size: 10

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
  plugins: [Oban.Plugins.Pruner],
  queues: [
    ai_generation: 5,
    planning: 10,
    storage_sync: 3,
    monitoring: 2
  ]

# OpenBao development configuration (security service)
config :aria_security,
  openbao_url: "http://localhost:8200",
  openbao_token: System.get_env("OPENBAO_DEV_TOKEN") || "dev-token"

config :aria_security, AriaSecurity.SecretsRepo,
  database: "aria_security_dev.sqlite3",
  pool_size: 5

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

