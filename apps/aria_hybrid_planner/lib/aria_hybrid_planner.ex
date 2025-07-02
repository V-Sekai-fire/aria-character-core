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
  # These provide a bridge between AriaEngineCore's API and AriaHybridPlanner.Core

  @doc """
  Plan only (no execution) - compatible with AriaEngineCore API.
  Returns only the solution tree portion of the plan.
  """
  def plan(domain, state, goals) do
    coordinator = AriaHybridPlanner.Core.new_coordinator()
    case AriaHybridPlanner.Core.plan(coordinator, domain, state, goals) do
      {:ok, plan} ->
        # Extract solution tree from plan structure
        solution_tree = extract_solution_tree(plan)
        {:ok, solution_tree}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Plan and execute with lazy execution - compatible with AriaEngineCore API.
  """
  def run_lazy(domain, state, goals) do
    coordinator = AriaHybridPlanner.Core.new_coordinator()
    case AriaHybridPlanner.Core.plan_and_execute(coordinator, domain, state, goals) do
      {:ok, result} ->
        final_state = Map.get(result, :final_state, state)
        solution_tree = extract_solution_tree(result)
        {:ok, {final_state, solution_tree}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Execute a pre-made solution tree - compatible with AriaEngineCore API.
  """
  def run_lazy_tree(domain, state, solution_tree) do
    coordinator = AriaHybridPlanner.Core.new_coordinator()
    case AriaHybridPlanner.Core.execute(coordinator, domain, state, solution_tree) do
      {:ok, result} ->
        final_state = Map.get(result, :final_state, state)
        {:ok, {final_state, solution_tree}}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper function to extract solution tree from plan structure
  defp extract_solution_tree(plan) when is_map(plan) do
    %{
      root_id: Map.get(plan, :root_id, "root"),
      nodes: Map.get(plan, :nodes, %{}),
      steps: Map.get(plan, :steps, []),
      goal_network: Map.get(plan, :goal_network, %{}),
      blacklisted_commands: Map.get(plan, :blacklisted_commands, MapSet.new()),
      # Include additional useful fields for solution tree
      metrics: Map.get(plan, :metrics, %{}),
      status: Map.get(plan, :status, :unknown)
    }
  end

  defp extract_solution_tree(_), do: %{
    root_id: "root",
    nodes: %{},
    steps: [],
    goal_network: %{},
    blacklisted_commands: MapSet.new(),
    metrics: %{},
    status: :empty
  }

  @spec version() :: String.t()
  @doc """
  Returns the version of the AriaHybridPlanner application.
  """
  def version do
    Application.spec(:aria_hybrid_planner, :vsn) |> to_string()
  end
end
