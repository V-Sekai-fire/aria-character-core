# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Configure AriaEngineCore to use mock adapter in test environment
config :aria_engine_core,
  planner_adapter: AriaEngineCore.Mocks.PlannerMock

# Test-specific logging configuration
config :logger, level: :warn

# Disable Oban in tests to avoid background job interference
config :aria_engine_core, Oban, testing: :inline
