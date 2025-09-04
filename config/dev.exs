# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Development environment configuration
config :logger, level: :debug

# Configure Membrane Job Processor for development (replaces Oban)
# config :aria_queue, AriaQueue.MembraneJobProcessor,
#   queues: %{
#     # Temporal planner queues (Resolution 2)
#     sequential_actions: 1,    # Single worker for strict temporal ordering
#     parallel_actions: 5,      # Multi-worker for concurrent execution
#     instant_actions: 3,       # High-priority immediate responses
#     # Legacy application queues
#     ai_generation: 5,
#     planning: 10,
#     storage_sync: 3,
#     monitoring: 2
#   }

# Development Hammer rate limiting configuration
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Configure aria_viewer Phoenix endpoint for umbrella
config :aria_viewer, AriaViewerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "tlKgo63lRy4bRcsV0GXDiOz4SaeWdZJltU3GIWMuQ2hoI/E/PV/dF846wr3C5xQx",
  # FIXME: Restore watchers when esbuild and tailwind are set up in umbrella
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/aria_viewer_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]
