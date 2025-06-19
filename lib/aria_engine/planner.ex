# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planner do
  @moduledoc """
  Main planner interface that delegates to PlannerAdapter.
  
  This module provides a simple interface that forwards calls to the PlannerAdapter,
  which in turn uses the HybridCoordinator for actual planning functionality.
  """

  # alias AriaEngine.PlannerAdapter
  alias AriaEngine.StateV2

  @type domain :: map()
  @type state :: StateV2.t()
  @type todos :: list()
  @type plan :: term()
  @type solution_tree :: term()
  @type opts :: keyword()
  @type action :: term()

  @doc """
  Plan using the hybrid planner system.
  """
  @spec plan(domain(), state(), todos(), opts()) :: {:ok, plan()} | {:error, String.t()}
  defdelegate plan(domain, state, todos, opts \\ []), to: AriaEngine.PlannerAdapter

  @doc """
  Calculate the cost of a plan.
  """
  @spec plan_cost(plan()) :: number()
  defdelegate plan_cost(plan), to: AriaEngine.PlannerAdapter

  @doc """
  Execute a plan - delegates to run_lazy_refineahead.
  """
  @spec execute(domain(), state(), solution_tree(), opts()) :: {:ok, state()} | {:error, String.t()}
  def execute(domain, state, solution_tree, opts \\ []) do
    AriaEngine.PlannerAdapter.run_lazy_refineahead(domain, state, solution_tree, opts)
  end

  @doc """
  Extract actions from a solution tree for compatibility.
  """
  @spec extract_actions(solution_tree()) :: [action()]
  def extract_actions(solution_tree) when is_map(solution_tree) do
    # For now, return an empty list - this would need proper implementation
    # based on the solution tree structure
    []
  end

  def extract_actions(_), do: []
end
