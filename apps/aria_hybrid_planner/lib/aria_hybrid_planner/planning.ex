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

  defp convert_goal_to_todo(%AriaEngineCore.Multigoal{} = multigoal) do
    multigoal
  end

  defp convert_goal_to_todo(other) do
    Logger.warning("HTN Planning: Unknown goal format #{inspect(other)}, passing through")
    other
  end
end
