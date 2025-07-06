# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Set a higher stacktrace limit for more detailed errors
config :phoenix, :stacktrace_depth, 20

# Enable debug logs for trace mode debugging
# This allows Logger.debug/1 calls to work when running mix test --trace
# Normal test runs remain silent due to TestOutput module conditional logging
config :logger, level: :debug

# Exclude integration tests by default
# Run integration tests with: mix test --include integration
config :ex_unit, exclude: [:integration]

# Configure Mox for missing modules
config :aria_hybrid_planner, :hybrid_planner_adapter, MockAriaHybridPlannerCore
config :aria_hybrid_planner, :aria_core_module, MockAriaCore
config :aria_hybrid_planner, :aria_state_module, MockAriaStateRelationalState
config :aria_membrane_pipeline, :membrane_pipeline_module, MockMembranePipeline
config :aria_membrane_pipeline, :aria_core_domain_module, MockAriaCoreDomain
