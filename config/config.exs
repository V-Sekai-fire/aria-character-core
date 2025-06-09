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
    {:process_info, name: :queue_metrics, event: [:vm, :total_run_queue_lengths], keys: [:cpu, :io]}
  ]

# Import environment specific config files
import_config "#{config_env()}.exs"