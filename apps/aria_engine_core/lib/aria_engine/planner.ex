# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planner do
  @moduledoc """
  Main external API for the Aria planning system following R25W1398085 specification.

  This module provides a clean, GTpyHOP-style interface with intelligent recovery
  for planning and execution. All implementation complexity is hidden behind
  this simple API.

  ## Basic Usage

      # Plan and execute with automatic recovery
      {:ok, final_state} = AriaEngine.Planner.run_lazy(domain, state, goals)

      # Just planning, no execution
      {:ok, plan} = AriaEngine.Planner.plan(domain, state, goals)

  ## API Functions

  - `run_lazy/3` - Plan and execute with recovery (recommended)
  - `plan/3` - Just planning, no execution

  No configuration options are exposed - all complexity is handled internally.
  """

  alias AriaHybridPlanner.Core

  @type domain :: AriaEngine.Domain.t()
  @type state :: AriaEngine.State.t()
  @type goal :: term()
  @type plan :: [term()]

  @doc """
  Plan and execute goals with automatic recovery.

  This is the recommended function for most use cases. It combines planning
  and execution with intelligent recovery from failures.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, final_state}` - Success with final state after execution
  - `{:error, reason}` - Failure with error description

  ## Example

      domain = MyDomain.new()
      state = MyState.new()
      goals = [{:achieve, :goal1}, {:achieve, :goal2}]

      {:ok, final_state} = AriaEngine.Planner.run_lazy(domain, state, goals)
      IO.puts("Goals achieved!")
  """
  @spec run_lazy(domain(), state(), [goal()]) :: {:ok, state()} | {:error, String.t()}
  def run_lazy(domain, state, goals) do
    # Delegate to aria_hybrid_planner implementation
    Core.plan_execute_with_recovery(domain, state, goals, [], [])
  end

  @doc """
  Plan to achieve goals without execution.

  This function only performs planning and returns the plan without executing it.
  Use this when you need to inspect or modify the plan before execution.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, plan}` - Success with generated plan
  - `{:error, reason}` - Failure with error description

  ## Example

      {:ok, plan} = AriaEngine.Planner.plan(domain, state, goals)
      IO.inspect(plan, label: "Generated plan")
      # Execute plan manually if needed
  """
  @spec plan(domain(), state(), [goal()]) :: {:ok, plan()} | {:error, String.t()}
  def plan(domain, state, goals) do
    # Delegate to aria_hybrid_planner implementation
    case Core.plan(domain, state, goals, []) do
      {:ok, solution_tree} ->
        # Extract plan from solution tree
        plan = extract_plan_from_solution_tree(solution_tree)
        {:ok, plan}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helper to extract plan from solution tree
  defp extract_plan_from_solution_tree(solution_tree) do
    # TODO: Implement plan extraction from solution tree
    # For now, return the solution tree as-is
    solution_tree
  end
end
