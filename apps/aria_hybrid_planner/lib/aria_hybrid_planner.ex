# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaHybridPlanner do
  @moduledoc """
  External API for AriaHybridPlanner functionality.

  This module provides a clean external interface that delegates to the internal
  AriaHybridPlanner implementation in the nested umbrella structure.
  """

  # Delegate all functions to the actual implementation
  # Note: This creates a delegation to the nested AriaHybridPlanner module
  # We need to use a different approach since we can't delegate to ourselves

  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type todo_item :: AriaEngineCore.Plan.todo_item()
  @type solution_tree :: AriaEngineCore.Plan.solution_tree()
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @type execution_result :: {:ok, {solution_tree(), state()}} | {:error, String.t()}

  @spec plan(domain(), state(), [todo_item()], keyword()) :: plan_result()
  def plan(_domain, _initial_state, _todos, _opts \\ []) do
    # For now, return a simple error indicating the planner is not available
    {:error, "AriaHybridPlanner not available - nested umbrella structure needs resolution"}
  end

  @spec run_lazy(domain(), state(), [todo_item()], keyword()) :: execution_result()
  def run_lazy(_domain, _initial_state, _todos, _opts \\ []) do
    # For now, return a simple error indicating the planner is not available
    {:error, "AriaHybridPlanner not available - nested umbrella structure needs resolution"}
  end

  @spec run_lazy_tree(domain(), state(), solution_tree(), keyword()) :: execution_result()
  def run_lazy_tree(_domain, _initial_state, _solution_tree, _opts \\ []) do
    # For now, return a simple error indicating the planner is not available
    {:error, "AriaHybridPlanner not available - nested umbrella structure needs resolution"}
  end

  @spec version() :: String.t()
  def version do
    "0.1.0-stub"
  end
end
