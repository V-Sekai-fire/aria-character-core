# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Test environment configuration
config :logger, level: :warning

# Test database configuration - using SQLite
config :aria_data, AriaData.Repo,
  database: "aria_data_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.AuthRepo,
  database: "aria_auth_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.QueueRepo,
  database: "aria_queue_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.StorageRepo,
  database: "aria_storage_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.MonitorRepo,
  database: "aria_monitor_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.EngineRepo,
  database: "aria_engine_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_security, AriaSecurity.SecretsRepo,
  database: "aria_security_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

# Test Phoenix configuration
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_for_testing_only",
  server: false

# Test Oban configuration (disable automatic migrations and use explicit ones)
config :aria_queue, Oban,
  testing: :inline,
  repo: AriaData.QueueRepo,
  queues: []

# Test security configuration (mock OpenBao)
config :aria_security,
  openbao_url: "http://localhost:8200",
  openbao_token: "test-token"

# Test AI configuration (use mock models)
config :aria_interpret,
  qwen_model_path: "test/fixtures/mock_model.onnx",
  gpu_enabled: false,
  batch_size: 1

# Test Hammer rate limiting configuration
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}

# Configure vaultex to use MockVaultex in test.exs

# For CI environments - skip database-dependent repositories if DATABASE_URL is not set
if System.get_env("CI_UNIT_TESTS") == "true" do
  # In CI unit test mode, we disable database-dependent features
  config :aria_data, AriaData.Repo, adapter: Ecto.Adapters.SQL.Sandbox, pool: Ecto.Adapters.SQL.Sandbox
  config :aria_data, AriaData.AuthRepo, adapter: Ecto.Adapters.SQL.Sandbox, pool: Ecto.Adapters.SQL.Sandbox
  config :aria_data, AriaData.QueueRepo, adapter: Ecto.Adapters.SQL.Sandbox, pool: Ecto.Adapters.SQL.Sandbox
  config :aria_data, AriaData.StorageRepo, adapter: Ecto.Adapters.SQL.Sandbox, pool: Ecto.Adapters.SQL.Sandbox
  config :aria_data, AriaData.MonitorRepo, adapter: Ecto.Adapters.SQL.Sandbox, pool: Ecto.Adapters.SQL.Sandbox
  config :aria_data, AriaData.EngineRepo, adapter: Ecto.Adapters.SQL.Sandbox, pool: Ecto.Adapters.SQL.Sandbox
end
