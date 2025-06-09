# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Test environment configuration
config :logger, level: :warning

# Test database configuration - using CockroachDB
config :aria_data, AriaData.Repo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_data_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.AuthRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_auth_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.QueueRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_queue_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.StorageRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_storage_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.MonitorRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_monitor_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

config :aria_data, AriaData.EngineRepo,
  username: "root",
  password: "",
  hostname: "localhost",
  port: 26257,
  database: "aria_engine_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

# Test Phoenix configuration
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_for_testing_only",
  server: false

# Test Oban configuration (disable in tests)
config :aria_queue, Oban, testing: :inline, repo: AriaData.QueueRepo

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
