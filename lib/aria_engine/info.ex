# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Info do
  @moduledoc """
  Provides functions for retrieving information and status from the Aria Engine.
  """
  alias AriaEngine.Core
  alias AriaEngine.State
  alias AriaEngine.PlannerAdapter
  alias AriaEngine.Plan.Utils # Added alias for Utils

  @type t :: Core.t()
  @type status :: Core.status()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()

  @doc """
  Gets the current status of the engine.
  """
  @spec get_status(t()) :: status()
  def get_status(%Core{status: status}) do
    status
  end

  @doc """
  Gets the current state.
  """
  @spec get_current_state(t()) :: State.t()
  def get_current_state(%Core{current_state: state}) do
    state
  end

  @doc """
  Gets the final state (if completed).
  """
  @spec get_final_state(t()) :: State.t() | nil
  def get_final_state(%Core{status: :completed, current_state: state}) do
    state
  end

  def get_final_state(%Core{}) do
    nil
  end

  @doc """
  Gets the solution tree (if available).
  """
  @spec get_solution_tree(t()) :: solution_tree() | nil
  def get_solution_tree(%Core{solution_tree: solution_tree}) do
    solution_tree
  end

  @doc """
  Gets the current goals.
  """
  @spec get_goals(t()) :: [todo_item()]
  def get_goals(%Core{goals: goals}) do
    goals
  end

  @doc """
  Checks if execution is completed.
  """
  @spec completed?(t()) :: boolean()
  def completed?(%Core{status: status}) do
    status == :completed
  end

  @doc """
  Gets execution progress as a percentage.
  """
  @spec progress(t()) :: float()
  def progress(%Core{progress: %{total_steps: 0}}) do
    0.0
  end

  def progress(%Core{progress: %{total_steps: total, completed_steps: completed}}) do
    min(100.0, (completed / total) * 100.0)
  end

  @doc """
  Gets detailed plan statistics from the solution tree.
  """
  @spec get_plan_stats(t()) :: map()
  def get_plan_stats(%Core{solution_tree: solution_tree}) when not is_nil(solution_tree) do
    PlannerAdapter.tree_stats(solution_tree)
  end

  def get_plan_stats(%Core{solution_tree: nil}) do
    %{error: "No solution tree available"}
  end

  @doc """
  Gets the planned actions from the solution tree.
  """
  @spec get_planned_actions(t()) :: [plan_step()]
  def get_planned_actions(%Core{solution_tree: nil}) do
    []
  end

  def get_planned_actions(%Core{solution_tree: solution_tree}) do
    Utils.get_primitive_actions_dfs(solution_tree)
  end

  @doc """
  Gets execution summary with Plan module integration.
  """
  @spec get_summary(t()) :: map()
  def get_summary(%Core{} = engine) do
    total_duration = case {engine.started_at, engine.completed_at} do
      {%DateTime{} = start_time, %DateTime{} = end_time} ->
        DateTime.diff(end_time, start_time, :millisecond)
      _ -> nil
    end

    tree_stats = case engine.solution_tree do
      nil -> %{}
      solution_tree -> PlannerAdapter.tree_stats(solution_tree)
    end

    %{
      id: engine.id,
      name: engine.name,
      status: engine.status,
      progress: progress(engine),
      total_goals: length(engine.goals),
      current_goals: length(get_goals(engine)),
      created_at: engine.created_at,
      started_at: engine.started_at,
      completed_at: engine.completed_at,
      duration_ms: total_duration,
      solution_tree: engine.solution_tree != nil,
      tree_stats: tree_stats
    }
  end

  @doc """
  Gets execution trace from the Plan module's solution tree.
  """
  @spec get_trace_log(t()) :: String.t()
  def get_trace_log(%Core{solution_tree: nil}) do
    "No solution tree available - not planned yet"
  end

  def get_trace_log(%Core{solution_tree: solution_tree}) do
    actions = Utils.get_primitive_actions_dfs(solution_tree)

    actions
    |> Enum.with_index()
    |> Enum.map(fn {{action_name, args}, index} ->
      "Step #{index + 1}: #{action_name}(#{inspect(args)})"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Updates the current state.
  """
  @spec update_state(t(), State.t()) :: t()
  def update_state(%Core{} = engine, new_state) do
    %{engine | current_state: new_state}
  end
end
