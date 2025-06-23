# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PlannerAdapter do
  @moduledoc "Stub adapter for PlannerAdapter functionality in aria_engine_core.\n\nThis module provides basic functionality needed by Info module while avoiding\ncircular dependencies. For full PlannerAdapter functionality, use the one in\naria_hybrid_planner.\n"

  alias AriaEngine.Plan.Utils

  @type solution_tree :: Utils.solution_tree()
  @type plan_step :: Utils.plan_step()

  @doc "Get tree statistics - delegates to Plan.Utils for compatibility.\n"
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    Utils.tree_stats(solution_tree)
  end

  @doc "Get plan cost - delegates to Plan.Utils for compatibility.\n"
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(plan_or_tree) do
    Utils.plan_cost(plan_or_tree)
  end

  @doc "Stub for plan_tasks - returns error indicating full implementation needed.\n"
  @spec plan_tasks(any(), any(), any(), any()) :: {:error, String.t()}
  def plan_tasks(_domain, _initial_state, _tasks, _opts) do
    {:error, "plan_tasks requires full AriaEngine.PlannerAdapter from aria_hybrid_planner"}
  end

  @doc "Stub for plan - returns error indicating full implementation needed.\n"
  @spec plan(any(), any(), any(), any()) :: {:error, String.t()}
  def plan(_domain, _state, _todos, _opts) do
    {:error, "plan requires full AriaEngine.PlannerAdapter from aria_hybrid_planner"}
  end

  @doc "Stub for validate_plan - returns error indicating full implementation needed.\n"
  @spec validate_plan(any(), any(), any()) :: {:error, String.t()}
  def validate_plan(_domain, _initial_state, _plan) do
    {:error, "validate_plan requires full AriaEngine.PlannerAdapter from aria_hybrid_planner"}
  end

  @doc "Stub for replan - returns error indicating full implementation needed.\n"
  @spec replan(any(), any(), any(), any(), any()) :: {:error, String.t()}
  def replan(_domain, _state, _solution_tree, _fail_node_id, _opts) do
    {:error, "replan requires full AriaEngine.PlannerAdapter from aria_hybrid_planner"}
  end
end
