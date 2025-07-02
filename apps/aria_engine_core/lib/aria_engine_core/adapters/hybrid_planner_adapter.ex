# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Adapters.HybridPlannerAdapter do
  @moduledoc """
  Mock adapter for HybridPlanner functionality.

  This is a simplified adapter that provides basic planning functionality
  for testing and development purposes. It implements a simple forward-chaining
  planner that can handle basic blocks world problems.
  """

  require Logger

  @doc """
  Create a new coordinator instance.
  """
  @spec new_coordinator() :: map()
  def new_coordinator do
    %{
      type: :mock_coordinator,
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Plan to achieve goals using a simple forward-chaining approach.
  """
  @spec plan(map(), any(), any(), [any()]) :: {:ok, map()} | {:error, atom()}
  def plan(_coordinator, domain, state, goals) do
    Logger.debug("Mock planner: Planning for #{length(goals)} goals")

    try do
      # Simple planning: convert goals to actions using domain methods
      case plan_goals_simple(domain, state, goals) do
        {:ok, actions} ->
          plan_result = %{
            "actions" => actions,
            "type" => "sequential_plan",
            "goals" => goals,
            "initial_state" => state
          }
          {:ok, plan_result}
        {:error, reason} ->
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Mock planner error: #{inspect(error)}")
        {:error, :planning_failed}
    end
  end

  @doc """
  Execute a plan (optional function).
  """
  @spec execute(map(), any(), any(), any()) :: {:ok, any()} | {:error, atom()}
  def execute(_coordinator, domain, initial_state, plan) do
    Logger.debug("Mock executor: Executing plan")

    try do
      # Extract actions from plan
      actions = case plan do
        %{"actions" => action_list} -> action_list
        _ -> []
      end

      # Execute actions sequentially
      execute_actions_sequentially(domain, initial_state, actions)
    rescue
      error ->
        Logger.error("Mock executor error: #{inspect(error)}")
        {:error, :execution_failed}
    end
  end

  # Private helper functions

  defp plan_goals_simple(domain, state, goals) do
    try do
      # For each goal, try to find a method to achieve it
      actions = Enum.flat_map(goals, fn goal ->
        case plan_single_goal(domain, state, goal) do
          {:ok, goal_actions} -> goal_actions
          {:error, _reason} -> []
        end
      end)

      {:ok, actions}
    rescue
      error ->
        Logger.error("Error planning goals: #{inspect(error)}")
        {:error, :goal_planning_failed}
    end
  end

  defp plan_single_goal(domain, state, goal) do
    case goal do
      {"pos", block, destination} ->
        # Use the domain's achieve_position method
        case apply_domain_method(domain, :achieve_position, [state, {block, destination}]) do
          {:ok, actions} -> {:ok, actions}
          {:error, reason} -> {:error, reason}
        end
      {"clear", block, true} ->
        # Use the domain's achieve_clear method
        case apply_domain_method(domain, :achieve_clear, [state, {block, true}]) do
          {:ok, actions} -> {:ok, actions}
          {:error, reason} -> {:error, reason}
        end
      _ ->
        Logger.warning("Unknown goal format: #{inspect(goal)}")
        {:ok, []}
    end
  end

  defp apply_domain_method(domain, method_name, args) do
    try do
      # Try to call the method on the domain module
      domain_module = get_domain_module(domain)
      apply(domain_module, method_name, args)
    rescue
      UndefinedFunctionError ->
        Logger.warning("Method #{method_name} not found in domain")
        {:ok, []}
      error ->
        Logger.error("Error applying domain method #{method_name}: #{inspect(error)}")
        {:error, :method_application_failed}
    end
  end

  defp get_domain_module(domain) do
    case domain do
      %{name: :blocks_world} -> AriaBlocksWorld.Domain
      _ -> AriaBlocksWorld.Domain  # Default fallback
    end
  end

  defp execute_actions_sequentially(domain, initial_state, actions) do
    Enum.reduce_while(actions, {:ok, initial_state}, fn action, {:ok, current_state} ->
      case execute_single_action(domain, current_state, action) do
        {:ok, new_state} -> {:cont, {:ok, new_state}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp execute_single_action(domain, state, action) do
    try do
      case action do
        {:move_block, [block, destination]} ->
          # This is a task method, need to decompose it
          domain_module = get_domain_module(domain)
          case apply(domain_module, :move_block, [state, [block, destination]]) do
            {:ok, sub_actions} ->
              # Execute the sub-actions
              execute_actions_sequentially(domain, state, sub_actions)
            {:error, reason} ->
              {:error, reason}
          end
        {action_name, args} ->
          # This is a primitive action
          domain_module = get_domain_module(domain)
          apply(domain_module, action_name, [state, args])
        _ ->
          Logger.warning("Unknown action format: #{inspect(action)}")
          {:ok, state}
      end
    rescue
      UndefinedFunctionError ->
        Logger.warning("Action not found in domain: #{inspect(action)}")
        {:ok, state}
      error ->
        Logger.error("Error executing action #{inspect(action)}: #{inspect(error)}")
        {:error, :action_execution_failed}
    end
  end
end
