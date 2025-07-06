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
