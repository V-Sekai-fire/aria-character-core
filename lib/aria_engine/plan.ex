# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan do
  @moduledoc "IPyHOP-style reentrant HTN planning implementation with Run-Lazy-Refineahead.\nThis module acts as a facade for the new, modularized planning components.\n"
  alias Plan.{Core, Backtracking, Execution, Blacklisting}
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaEngine.State.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()
  @type solution_node :: Core.solution_node()
  @type solution_tree :: Core.solution_tree()
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure
  @spec plan(Domain.Core.t(), AriaEngine.State.t(), [todo_item()], keyword()) :: plan_result()
  def plan(domain, state, todos, opts \\ []) do
    Core.plan(domain, state, todos, opts)
  end

  @spec replan(Domain.Core.t(), AriaEngine.State.t(), solution_tree(), node_id(), keyword()) ::
          replan_result()
  def replan(domain, state, solution_tree, fail_node_id, opts \\ []) do
    Backtracking.replan(domain, state, solution_tree, fail_node_id, opts)
  end

  @spec blacklist_command(solution_tree(), todo_item()) :: solution_tree()
  def blacklist_command(solution_tree, command) do
    Blacklisting.blacklist_command(solution_tree, command)
  end

  @spec run_lazy_refineahead(Domain.Core.t(), AriaEngine.State.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def run_lazy_refineahead(domain, initial_state, solution_tree, opts \\ []) do
    Execution.run_lazy_refineahead(domain, initial_state, solution_tree, opts)
  end

  @doc "Validates a plan by executing it step by step.\nFor compatibility with existing AriaEngine usage.\n"
  @spec validate_plan(Domain.Core.t(), AriaEngine.State.t(), [plan_step()] | solution_tree()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def validate_plan(domain, initial_state, plan) do
    AriaEngine.Plan.Utils.validate_plan(domain, initial_state, plan)
  end

  @doc "Estimates the cost of a plan (simple step count for now).\nFor compatibility with existing AriaEngine usage.\n"
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(plan) do
    AriaEngine.Plan.Utils.plan_cost(plan)
  end

  @doc "Get statistics about the solution tree.\n"
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    AriaEngine.Plan.Utils.tree_stats(solution_tree)
  end
end