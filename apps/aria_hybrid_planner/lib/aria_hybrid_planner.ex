# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  Hybrid planning coordination system providing strategy-based planning with temporal reasoning integration.

  This module serves as the main entry point for the Aria Hybrid Planner application.
  For the unified API, use `AriaHybridPlanner.Core` which provides a comprehensive,
  single-interface approach to hybrid planning.

  ## Quick Start

      # Use the unified API (recommended)
      coordinator = AriaHybridPlanner.Core.new_coordinator()
      {:ok, plan} = AriaHybridPlanner.Core.plan(coordinator, domain, state, goals)
      {:ok, final_state} = AriaHybridPlanner.Core.execute(coordinator, domain, state, plan)

  ## Legacy APIs

  The following legacy APIs are still available for backward compatibility:

  - `AriaHybridPlanner.PlanCore` - HTN planning interface
  - `AriaHybridPlanner.PlanningCore` - General planning interface
  - `HybridPlanner.HybridCoordinatorV2` - Monolithic coordinator

  However, new code should use `AriaHybridPlanner.Core` for the best experience.
  """

  # Delegate core functions to the unified API for convenience
  defdelegate new_coordinator(opts \\ []), to: AriaHybridPlanner.Core
  defdelegate plan(coordinator, domain, state, goals, opts \\ []), to: AriaHybridPlanner.Core
  defdelegate execute(coordinator, domain, state, plan, opts \\ []), to: AriaHybridPlanner.Core
  defdelegate validate_plan(coordinator, domain, state, plan), to: AriaHybridPlanner.Core
  defdelegate replan(coordinator, domain, state, plan, fail_node_id, opts \\ []), to: AriaHybridPlanner.Core
  defdelegate plan_and_execute(coordinator, domain, state, goals, opts \\ []), to: AriaHybridPlanner.Core

  # Engine integration functions for AriaEngineCore compatibility
  defdelegate plan_only(domain, state, goals), to: AriaHybridPlanner.EngineIntegration, as: :plan
  defdelegate run_lazy(domain, state, goals), to: AriaHybridPlanner.EngineIntegration
  defdelegate run_lazy_tree(domain, state, solution_tree), to: AriaHybridPlanner.EngineIntegration

  @spec version() :: String.t()
  @doc """
  Returns the version of the AriaHybridPlanner application.
  """
  def version do
    Application.spec(:aria_hybrid_planner, :vsn) |> to_string()
  end
end
