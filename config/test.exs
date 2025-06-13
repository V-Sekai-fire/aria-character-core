# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Test environment configuration
config :logger, level: :warning

# Test database configuration - using SQLite for simplicity
config :aria_data, AriaData.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_data_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.AuthRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_auth_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.QueueRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_queue_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.StorageRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_storage_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.MonitorRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_monitor_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

config :aria_data, AriaData.EngineRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/aria_engine_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

# Test Phoenix configuration
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_for_testing_only",
  server: false

# Test Membrane Job Processor configuration (replaces Oban for testing)
config :aria_queue, AriaQueue.MembraneJobProcessor,
  queues: %{
    # Temporal planner queues (set to 1 for testing)
    sequential_actions: 1,
    parallel_actions: 1,
    instant_actions: 1
  }

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
