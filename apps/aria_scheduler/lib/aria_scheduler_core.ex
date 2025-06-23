# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaScheduler.Core do
  @moduledoc """
  Public API wrapper for AriaEngine.Scheduler.Core.

  This module provides a clean public interface while delegating to the internal
  AriaEngine.Scheduler.Core implementation.
  """

  # Delegate to AriaEngine.Scheduler.Core for the main scheduling functions
  defdelegate schedule_with_enhanced_features(
                schedule_name,
                activities,
                entities,
                resources,
                constraints,
                simulation_mode,
                activity_log,
                verbose,
                base_datetime
              ),
              to: AriaEngine.Scheduler.Core

  # Simple new/0 function for basic scheduler creation
  def new() do
    %{
      type: :aria_scheduler,
      created_at: DateTime.utc_now(),
      version: "0.1.0"
    }
  end

  # Simple schedule/3 function that delegates to the enhanced version
  def schedule(_scheduler, activities, constraints \\ []) do
    # Extract basic parameters and use defaults for enhanced features
    schedule_name = "default_schedule"
    entities = []
    resources = %{}
    simulation_mode = false
    activity_log = []
    verbose = 0
    base_datetime = DateTime.utc_now()

    schedule_with_enhanced_features(
      schedule_name,
      activities,
      entities,
      resources,
      constraints,
      simulation_mode,
      activity_log,
      verbose,
      base_datetime
    )
  end
end
