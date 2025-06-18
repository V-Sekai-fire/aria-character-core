# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planner do
  @moduledoc """
  Main planner interface that delegates to PlannerAdapter.
  
  This module provides a simple interface that forwards calls to the PlannerAdapter,
  which in turn uses the HybridCoordinator for actual planning functionality.
  """

  alias PlannerAdapter

  @doc """
  Plan using the hybrid planner system.
  """
  defdelegate plan(domain, state, todos, opts \\ []), to: PlannerAdapter

  @doc """
  Calculate the cost of a plan.
  """
  defdelegate plan_cost(plan), to: PlannerAdapter

  @doc """
  Execute a plan - delegates to run_lazy_refineahead.
  """
  def execute(domain, state, solution_tree, opts \\ []) do
    PlannerAdapter.run_lazy_refineahead(domain, state, solution_tree, opts)
  end

  @doc """
  Extract actions from a solution tree for compatibility.
  """
  def extract_actions(solution_tree) when is_map(solution_tree) do
    # For now, return an empty list - this would need proper implementation
    # based on the solution tree structure
    []
  end

  def extract_actions(_), do: []
end
