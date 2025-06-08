import Config

# Shared configuration for all apps
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :app]

# Configure telemetry for observability
config :telemetry_poller, :default,
  measurements: [
    # VM Metrics
    {__MODULE__, :dispatch_vm_metrics, []},
    
    # System metrics that all services can use
    {:process_info, event: [:vm, :memory], keys: [:total, :atom, :binary]},
    {:process_info, event: [:vm, :total_run_queue_lengths], keys: [:cpu, :io]}
  ]

# Import environment specific config files
import_config "#{config_env()}.exs"