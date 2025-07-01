# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Shared configuration for all apps
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :app]

# Configure telemetry for observability
config :telemetry_poller, :default,
  measurements: [
    # System metrics that all services can use
    {:process_info, name: :memory_metrics, event: [:vm, :memory], keys: [:total, :atom, :binary]},
    {:process_info,
     name: :queue_metrics, event: [:vm, :total_run_queue_lengths], keys: [:cpu, :io]}
  ]

# Configure Hammer rate limiting for all environments
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}

# Suppress Porcelain goon executable warning
config :porcelain, goon_warn_if_missing: false

# Configure Nx with TorchX backend for GPU acceleration
config :nx, :default_backend, Torchx.Backend

# Configure TorchX for CUDA support (RTX 4090)
# This will use CUDA 12.8 for optimal RTX 4090 performance
config :torchx, :default_device, :cuda

# Import environment specific config files
import_config "#{config_env()}.exs"
