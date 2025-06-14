# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Shared configuration for all apps
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :app]

# Configure Ecto repositories only for apps that use them
config :aria_data, ecto_repos: [
  AriaData.Repo,
  AriaData.AuthRepo,
  AriaData.QueueRepo,
  AriaData.StorageRepo,
  AriaData.MonitorRepo,
  AriaData.EngineRepo
]

# Other apps that don't use Ecto don't need repo configuration
# This eliminates warnings about missing repos in:
# aria_queue, aria_interpret, aria_security, aria_auth, aria_storage,
# aria_shape, aria_engine, aria_workflow, aria_interface, aria_coordinate,
# aria_monitor, aria_tune, aria_debugger

# Configure telemetry for observability
config :telemetry_poller, :default,
  measurements: [
    # System metrics that all services can use
    {:process_info, name: :memory_metrics, event: [:vm, :memory], keys: [:total, :atom, :binary]},
    {:process_info, name: :queue_metrics, event: [:vm, :total_run_queue_lengths], keys: [:cpu, :io]}
  ]

# Configure Hammer rate limiting for all environments
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}

# Configure AriaEngine domain providers
config :aria_engine,
  domain_providers: [
    AriaEngine.BasicActionsDomainProvider
    # Additional providers can be added when their apps are included
    # AriaFileManagement.DomainProvider,
    # AriaWorkflowSystem.DomainProvider,
    # AriaTimestrike.DomainProvider
  ]

# Import environment specific config files
import_config "#{config_env()}.exs"
