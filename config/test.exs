# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Test environment configuration
config :logger, level: :warning

# Test database configuration - using SQLite for simplicity
config :aria_data, AriaData.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_data_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.AuthRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_auth_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.QueueRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_queue_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.StorageRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_storage_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.MonitorRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_monitor_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

config :aria_data, AriaData.EngineRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_engine_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

# Test Phoenix configuration
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_for_testing_only",
  server: false

# Test Oban configuration (disable automatic migrations and use explicit ones)
config :aria_queue, Oban,
  testing: :inline,
  repo: AriaData.QueueRepo,
  notifier: Oban.Notifiers.PG,
  queues: [
    # Temporal planner queues (disabled in test - inline execution)
    sequential_actions: 0,
    parallel_actions: 0, 
    instant_actions: 0
  ]

# Test security configuration (using mock)
config :aria_security,
  secrets_module: AriaSecurity.SecretsMock,
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

# Configure ExUnit
config :ex_unit,
  runner: ExUnit.Runner,
  formatter: ExUnit.DotTestReporter,
  trace: true,
  refute_receive_timeout: 500,
  assert_receive_timeout: 500
