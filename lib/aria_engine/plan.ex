# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan do
  @moduledoc """
  IPyHOP-style reentrant HTN planning implementation with Run-Lazy-Refineahead.
  This module acts as a facade for the new, modularized planning components.
  """

  # Removed NodeExpansion
  alias AriaEngine.Plan.{Core, Backtracking, Execution, Blacklisting}

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaEngine.StateV2.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}

  @type node_id :: String.t()
  # Reference from Core
  @type solution_node :: Core.solution_node()
  # Reference from Core
  @type solution_tree :: Core.solution_tree()

  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure

  # Delegate to Core
  @spec plan(AriaEngine.Domain.Core.t(), AriaEngine.StateV2.t(), [todo_item()], keyword()) :: plan_result()
  def plan(domain, state, todos, opts \\ []), do: Core.plan(domain, state, todos, opts)

  # Delegate to Backtracking
  @spec replan(AriaEngine.Domain.Core.t(), AriaEngine.StateV2.t(), solution_tree(), node_id(), keyword()) ::
          replan_result()
  def replan(domain, state, solution_tree, fail_node_id, opts \\ []),
    do: Backtracking.replan(domain, state, solution_tree, fail_node_id, opts)

  # Delegate to Blacklisting
  @spec blacklist_command(solution_tree(), todo_item()) :: solution_tree()
  def blacklist_command(solution_tree, command),
    do: Blacklisting.blacklist_command(solution_tree, command)

  # Delegate to Execution
  @spec run_lazy_refineahead(AriaEngine.Domain.Core.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def run_lazy_refineahead(domain, initial_state, solution_tree, opts \\ []),
    do: Execution.run_lazy_refineahead(domain, initial_state, solution_tree, opts)

  # Delegate to Utils
  @doc """
  Validates a plan by executing it step by step.
  For compatibility with existing AriaEngine usage.
  """
  @spec validate_plan(AriaEngine.Domain.Core.t(), AriaEngine.StateV2.t(), [plan_step()] | solution_tree()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def validate_plan(domain, initial_state, plan),
    do: AriaEngine.Plan.Utils.validate_plan(domain, initial_state, plan)

  @doc """
  Get statistics about the solution tree.
  """
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree), do: AriaEngine.Plan.Utils.tree_stats(solution_tree)
end
