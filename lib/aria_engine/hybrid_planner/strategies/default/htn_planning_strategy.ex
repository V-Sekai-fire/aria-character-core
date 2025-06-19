# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies.Default.HTNPlanningStrategy do
  @moduledoc """
  Default HTN planning strategy implementation wrapping existing Plan.Core logic.
  
  This strategy encapsulates the current HTN planning functionality from
  Plan.Core while providing the clean strategy interface defined in ADR-091.
  It serves as the default implementation during the migration period.
  """

  @behaviour HybridPlanner.Strategies.PlanningStrategy

  require Logger

  @impl true
  def plan(domain, %AriaEngine.StateV2{} = state, goals, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 1 do
      Logger.debug("HTNPlanningStrategy: Starting planning with #{length(goals)} goals")
    end

    try do
      # Convert goals to todos format expected by Plan.Core
      todos = convert_goals_to_todos(goals)
      
      # Use existing Plan.Core.plan/4 logic
      case Plan.Core.plan(domain, state, todos, opts) do
        {:ok, solution_tree} ->
          if verbose > 1 do
            action_count = AriaEngine.Plan.Utils.plan_cost(solution_tree)
            Logger.debug("HTNPlanningStrategy: Planning successful with #{action_count} actions")
          end
          {:ok, solution_tree}
        
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("HTNPlanningStrategy: Planning failed - #{reason}")
          end
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTNPlanningStrategy planning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def replan(domain, %AriaEngine.StateV2{} = state, solution_tree, fail_node_id, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 1 do
      Logger.debug("HTNPlanningStrategy: Starting replanning from failed node #{fail_node_id}")
    end

    try do
      # Use existing Plan.replan/5 logic which handles sophisticated backtracking
      case Plan.replan(domain, state, solution_tree, fail_node_id, opts) do
        {:ok, new_solution_tree} ->
          if verbose > 1 do
            action_count = AriaEngine.Plan.Utils.plan_cost(new_solution_tree)
            Logger.debug("HTNPlanningStrategy: Replanning successful with #{action_count} actions")
          end
          {:ok, new_solution_tree}
        
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("HTNPlanningStrategy: Replanning failed - #{reason}")
          end
          {:error, reason}
        
        :failure ->
          if verbose > 1 do
            Logger.debug("HTNPlanningStrategy: Replanning returned failure - no viable alternatives")
          end
          :failure
      end
    rescue
      e ->
        error_msg = "HTNPlanningStrategy replanning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def validate_plan(domain, %AriaEngine.StateV2{} = initial_state, solution_tree) do
    try do
      # Extract primitive actions from solution tree
      primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
      
      # Use existing AriaEngine.Plan.Utils.validate_plan/3 logic
      case AriaEngine.Plan.Utils.validate_plan(domain, initial_state, primitive_actions) do
        {:ok, final_state} ->
          {:ok, final_state}
        
        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTNPlanningStrategy validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Convert goals to todos format expected by Plan.Core
  defp convert_goals_to_todos(goals) when is_list(goals) do
    Enum.map(goals, &convert_goal_to_todo/1)
  end

  defp convert_goal_to_todo({task_name, args}) when is_binary(task_name) and is_list(args) do
    # Task format: already in correct format
    {task_name, args}
  end

  defp convert_goal_to_todo({predicate, subject, value}) when is_binary(predicate) and is_binary(subject) do
    # Goal format: already in correct format for Plan.Core
    {predicate, subject, value}
  end

  defp convert_goal_to_todo(%Multigoal{} = multigoal) do
    # Multigoal: pass through, Plan.Core handles this
    multigoal
  end

  defp convert_goal_to_todo(other) do
    # Unknown format: pass through and let Plan.Core handle or error
    Logger.warning("HTNPlanningStrategy: Unknown goal format #{inspect(other)}, passing through")
    other
  end

  # ==================== STRATEGY METADATA ====================

  @impl true
  @doc """
  Get strategy metadata and capabilities.
  """
  def strategy_info do
    %{
      name: "HTN Planning Strategy",
      version: "1.0.0",
      description: "Default HTN planning strategy wrapping Plan.Core logic",
      capabilities: [
        :task_decomposition,
        :goal_achievement,
        :hierarchical_planning,
        :replanning,
        :plan_validation
      ],
      limitations: [
        :no_temporal_reasoning,
        :no_resource_constraints,
        :no_continuous_planning
      ],
      underlying_implementation: "Plan.Core"
    }
  end

  @doc """
  Check if this strategy can handle specific planning features.
  """
  def supports?(feature) when is_atom(feature) do
    capabilities = strategy_info()[:capabilities]
    feature in capabilities
  end

  @doc """
  Get performance characteristics of this strategy.
  """
  def performance_profile do
    %{
      planning_complexity: :exponential,
      memory_usage: :moderate,
      replanning_efficiency: :good,
      scalability: :medium,
      optimality: :satisficing
    }
  end
end
