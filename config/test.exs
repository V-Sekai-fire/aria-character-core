# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Test environment configuration
config :logger, level: :warning

# Test database configuration
config :aria_data, AriaData.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost", 
  database: "aria_data_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :aria_data, AriaData.AuthRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aria_auth_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.QueueRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aria_queue_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.StorageRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aria_storage_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 8

config :aria_data, AriaData.MonitorRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aria_monitor_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 6

config :aria_data, AriaData.EngineRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
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
