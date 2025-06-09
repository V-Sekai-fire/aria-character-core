# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Production configuration
config :logger, level: :info

# Production database configuration
config :aria_data, AriaData.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

# Production Phoenix configuration
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 443, scheme: "https"],
  http: [
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

# Production Oban configuration
config :aria_queue, Oban,
  repo: AriaData.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron, 
     crontab: [
       {"0 2 * * *", AriaData.Workers.DatabaseCleanup},
       {"*/15 * * * *", AriaStorage.Workers.CDNSync}
     ]}
  ],
  queues: [
    ai_generation: String.to_integer(System.get_env("AI_QUEUE_SIZE") || "10"),
    planning: String.to_integer(System.get_env("PLANNING_QUEUE_SIZE") || "20"),
    storage_sync: String.to_integer(System.get_env("STORAGE_QUEUE_SIZE") || "5"),
    monitoring: String.to_integer(System.get_env("MONITOR_QUEUE_SIZE") || "3")
  ]

# Production OpenBao configuration
config :aria_security,
  openbao_url: System.get_env("OPENBAO_URL"),
  openbao_token: System.get_env("OPENBAO_TOKEN")

# Production AI Service configuration
config :aria_interpret,
  qwen_model_path: System.get_env("QWEN_MODEL_PATH"),
  gpu_enabled: System.get_env("ARIA_GPU_ENABLED") == "true",
  batch_size: String.to_integer(System.get_env("AI_BATCH_SIZE") || "4")
