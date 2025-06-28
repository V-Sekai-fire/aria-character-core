# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PlannerAdapter do
  @moduledoc """
  Adapter for PlannerAdapter functionality in aria_engine_core.

  This module provides the full planning functionality by delegating to
  AriaEngine.Planner, which contains the real implementation migrated
  from aria_hybrid_planner.
  """

  alias AriaEngine.Plan.Utils
  alias AriaEngine.Planner
  alias AriaEngine.Domain
  alias AriaEngine.State

  @type solution_tree :: Utils.solution_tree()
  @type plan_step :: Utils.plan_step()
  @type domain :: Domain.t()
  @type state :: State.t()

  @doc """
  Get tree statistics - delegates to Plan.Utils for compatibility.
  """
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    Utils.tree_stats(solution_tree)
  end

  @doc """
  Get plan cost - delegates to Plan.Utils for compatibility.
  """
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(plan_or_tree) do
    Utils.plan_cost(plan_or_tree)
  end

  @doc """
  Plan tasks using the AriaEngine.Planner implementation.

  This function converts tasks to goals and delegates to AriaEngine.Planner.plan/4.
  """
  @spec plan_tasks(domain(), state(), [term()], keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def plan_tasks(domain, initial_state, tasks, opts \\ []) do
    # Convert tasks to goals format expected by AriaEngine.Planner
    goals = convert_tasks_to_goals(tasks)
    Planner.plan(domain, initial_state, goals, opts)
  end

  @doc """
  Plan goals using the AriaEngine.Planner implementation.

  This is a direct delegation to AriaEngine.Planner.plan/4.
  """
  @spec plan(domain(), state(), [term()], keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def plan(domain, state, todos, opts \\ []) do
    Planner.plan(domain, state, todos, opts)
  end

  @doc """
  Validate a plan using the AriaEngine.Planner implementation.

  This function delegates to AriaEngine.Planner.validate_plan/3.
  """
  @spec validate_plan(domain(), state(), map()) ::
          {:ok, state()} | {:error, String.t()}
  def validate_plan(domain, initial_state, plan) do
    Planner.validate_plan(domain, initial_state, plan)
  end

  @doc """
  Replan from a failure point.

  This function would need to be implemented when replanning functionality
  is added to AriaEngine.Planner. For now, it returns an error.
  """
  @spec replan(domain(), state(), solution_tree(), String.t(), keyword()) ::
          {:ok, map()} | {:error, String.t()} | :failure
  def replan(_domain, _state, _solution_tree, _fail_node_id, _opts) do
    {:error, "Replanning functionality not yet implemented in AriaEngine.Planner"}
  end

  # ==================== PRIVATE HELPERS ====================

  defp convert_tasks_to_goals(tasks) when is_list(tasks) do
    Enum.map(tasks, &convert_task_to_goal/1)
  end

  defp convert_task_to_goal({task_name, args}) when is_binary(task_name) and is_list(args) do
    {task_name, args}
  end

  defp convert_task_to_goal(task) do
    # Pass through other formats as-is
    task
  end
end
