# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.Planning do
  @moduledoc """
  HTN planning functions for HybridCoordinatorV2.

  Handles goal-to-todo conversion, HTN planning, replanning, and plan validation.
  """

  require Logger
  alias Plan.Utils

  @doc """
  Plan goals using HTN planning with temporal constraint validation.
  """
  @spec htn_plan(Domain.Core.t(), State.t(), [term()], keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def htn_plan(domain, state, goals, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("HTN Planning: Starting planning with #{length(goals)} goals")
    end

    try do
      todos = convert_goals_to_todos(goals)

      case Plan.Core.plan(domain, state, todos, opts) do
        {:ok, solution_tree} ->
          if verbose > 1 do
            action_count = Utils.plan_cost(solution_tree)
            Logger.debug("HTN Planning: Planning successful with #{action_count} actions")
          end
          {:ok, solution_tree}

        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("HTN Planning: Planning failed - #{reason}")
          end
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTN planning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Replan from a failure point using HTN replanning.
  """
  @spec htn_replan(Domain.Core.t(), State.t(), map(), String.t(), keyword()) ::
          {:ok, map()} | {:error, String.t()} | :failure
  def htn_replan(domain, state, solution_tree, fail_node_id, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("HTN Replanning: Starting replanning from failed node #{fail_node_id}")
    end

    try do
      case AriaHybridPlanner.PlanCore.replan(domain, state, solution_tree, fail_node_id, opts) do
        {:ok, new_solution_tree} ->
          if verbose > 1 do
            action_count = Utils.plan_cost(new_solution_tree)
            Logger.debug("HTN Replanning: Replanning successful with #{action_count} actions")
          end
          {:ok, new_solution_tree}

        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("HTN Replanning: Replanning failed - #{reason}")
          end
          {:error, reason}

        :failure ->
          if verbose > 1 do
            Logger.debug("HTN Replanning: Replanning returned failure - no viable alternatives")
          end
          :failure
      end
    rescue
      e ->
        error_msg = "HTN replanning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Validate a plan using HTN planning validation.
  """
  @spec htn_validate_plan(Domain.Core.t(), State.t(), map()) ::
          {:ok, State.t()} | {:error, String.t()}
  def htn_validate_plan(domain, initial_state, solution_tree) do
    try do
      primitive_actions = Utils.get_primitive_actions_dfs(solution_tree)

      case Utils.validate_plan(domain, initial_state, primitive_actions) do
        {:ok, final_state} -> {:ok, final_state}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTN validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Convert goals to todos for HTN planning.
  """
  @spec convert_goals_to_todos([term()]) :: [term()]
  def convert_goals_to_todos(goals) when is_list(goals) do
    Enum.map(goals, &convert_goal_to_todo/1)
  end

  # ==================== PRIVATE FUNCTIONS ====================

  defp convert_goal_to_todo({task_name, args}) when is_binary(task_name) and is_list(args) do
    {task_name, args}
  end

  defp convert_goal_to_todo({predicate, subject, value})
       when is_binary(predicate) and is_binary(subject) do
    {predicate, subject, value}
  end

  defp convert_goal_to_todo(%Multigoal{} = multigoal) do
    multigoal
  end

  defp convert_goal_to_todo(other) do
    Logger.warning("HTN Planning: Unknown goal format #{inspect(other)}, passing through")
    other
  end
end
