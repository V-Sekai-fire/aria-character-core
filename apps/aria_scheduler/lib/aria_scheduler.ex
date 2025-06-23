# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaScheduler do
  @moduledoc """
  Activity scheduling and domain conversion system providing resource management and temporal coordination.

  AriaScheduler implements a comprehensive scheduling system that coordinates activities,
  manages resources, and converts between different domain representations. It serves as
  the bridge between high-level planning and low-level execution.

  ## Core Components

  - `AriaScheduler.Core` - Central scheduling coordination and activity management
  - `AriaScheduler.DomainConverter` - Transforms between different domain representations
  - `AriaScheduler.EntityManager` - Manages entities and their relationships
  - `AriaScheduler.PlanConverter` - Converts plans between formats
  - `AriaScheduler.ResourceManager` - Handles resource allocation and constraints
  - `AriaScheduler.StateManager` - Manages scheduling state and transitions

  ## Usage

      # Create scheduler instance
      scheduler = AriaScheduler.Core.new()

      # Schedule activities
      result = AriaScheduler.Core.schedule(scheduler, activities, constraints)

      # Convert domain representations
      converted = AriaScheduler.DomainConverter.convert(domain, target_format)
  """

  # Re-export main scheduler functionality
  defdelegate new(), to: AriaScheduler.Core
  defdelegate schedule(scheduler, activities, constraints \\ []), to: AriaScheduler.Core
end
