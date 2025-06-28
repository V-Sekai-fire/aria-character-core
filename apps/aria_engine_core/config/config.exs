# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Configure AriaEngineCore to use the real hybrid planner adapter by default
config :aria_engine_core,
  planner_adapter: AriaEngineCore.Adapters.HybridPlannerAdapter

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
