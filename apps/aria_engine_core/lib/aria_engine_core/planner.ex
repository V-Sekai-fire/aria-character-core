# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Planner do
  @moduledoc """
  Internal planning implementation for the Aria planning system.

  This module provides the core planning functionality that is exposed through
  the main AriaEngineCore module. It implements the R25W1398085 specification
  with a clean, GTpyHOP-style interface.

  ## Usage

  Most users should use the main AriaEngineCore module:

      # Recommended usage
      {:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)
      {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)

  ## Direct Usage (Advanced)

      # Direct access to this module
      {:ok, {final_state, solution_tree}} = AriaEngineCore.Planner.run_lazy(domain, state, goals)
      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, state, goals)

  ## API Functions

  - `plan/3` - Just planning, no execution (returns solution tree only)
  - `run_lazy/3` - Plan and execute with recovery (returns final state and solution tree)
  - `run_lazy_tree/3` - Execute pre-made plan (returns final state and updated tree)

  All implementation complexity is handled internally.
  """

  require Logger
  alias AriaEngineCore.Plan

  # Dependency injection for planner adapter (runtime configuration for testing)
  defp planner_adapter do
    Application.get_env(:aria_engine_core, :planner_adapter, AriaEngineCore.Adapters.HybridPlannerAdapter)
  end

  # Type aliases matching ADR R25W1398085 specification
  @type domain :: AriaEngineCore.Domain.t()
  @type state :: AriaEngineCore.State.t()
  @type todo_item :: AriaEngine.todo_item()
  @type solution_tree :: AriaEngineCore.Plan.solution_tree()

  @doc """
  Plan to achieve goals without execution.

  This function only performs planning and returns the solution tree without executing it.
  Use this when you need to inspect or modify the plan before execution.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, solution_tree}` - Success with generated solution tree
  - `{:error, reason}` - Failure with error description

  ## Example

      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, state, goals)
      IO.inspect(solution_tree, label: "Generated plan")
      # Execute plan manually if needed
  """
  @spec plan(domain(), state(), [todo_item()]) :: {:ok, solution_tree()} | {:error, atom()}
  def plan(domain, state, goals) do
    Logger.debug("Starting planning for #{length(goals)} goals")

    try do
      # Create initial solution tree
      solution_tree = Plan.create_initial_solution_tree(goals, state)

      # Perform planning (placeholder implementation)
      case perform_planning(domain, state, solution_tree) do
        {:ok, final_tree} ->
          Logger.debug("Planning completed successfully")
          {:ok, final_tree}
        {:error, reason} ->
          Logger.error("Planning failed: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Planning error: #{inspect(error)}")
        {:error, :planning_error}
    end
  end

  @doc """
  Plan and execute goals with automatic recovery.

  This is the recommended function for most use cases. It combines planning
  and execution with intelligent recovery from failures.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, {final_state, solution_tree}}` - Success with final state and solution tree
  - `{:error, reason}` - Failure with error description

  ## Example

      domain = MyDomain.new()
      state = MyState.new()
      goals = [{:achieve, :goal1}, {:achieve, :goal2}]

      {:ok, {final_state, solution_tree}} = AriaEngineCore.Planner.run_lazy(domain, state, goals)
      IO.puts("Goals achieved!")
  """
  @spec run_lazy(domain(), state(), [todo_item()]) :: {:ok, {state(), solution_tree()}} | {:error, atom()}
  def run_lazy(domain, state, goals) do
    Logger.debug("Starting lazy execution for #{length(goals)} goals")

    case plan(domain, state, goals) do
      {:ok, solution_tree} ->
        Logger.debug("Planning successful, starting execution")
        run_lazy_tree(domain, state, solution_tree)
      {:error, reason} ->
        Logger.error("Planning failed during run_lazy: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Execute a pre-made solution tree.

  This function takes a solution tree that was created and validated earlier
  and executes it, returning the final state and updated tree.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `solution_tree` - Pre-made solution tree to execute

  ## Returns

  - `{:ok, {final_state, updated_tree}}` - Success with final state and updated tree
  - `{:error, reason}` - Failure with error description

  ## Example

      # Execute a solution tree that was created earlier
      {:ok, {final_state, updated_tree}} = AriaEngineCore.Planner.run_lazy_tree(domain, state, solution_tree)
      IO.puts("Plan executed successfully!")
  """
  @spec run_lazy_tree(domain(), state(), solution_tree()) :: {:ok, {state(), solution_tree()}} | {:error, atom()}
  def run_lazy_tree(domain, state, solution_tree) do
    Logger.debug("Starting execution of pre-made solution tree")

    try do
      case execute_solution_tree(domain, state, solution_tree) do
        {:ok, final_state, updated_tree} ->
          Logger.debug("Solution tree execution completed successfully")
          {:ok, {final_state, updated_tree}}
        {:error, reason} ->
          Logger.error("Solution tree execution failed: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Execution error: #{inspect(error)}")
        {:error, :execution_error}
    end
  end

  # Private implementation functions

  @spec perform_planning(domain(), state(), solution_tree()) :: {:ok, solution_tree()} | {:error, atom()}
  defp perform_planning(domain, state, solution_tree) do
    # Extract goals from solution tree
    goals = Plan.get_goals_from_tree(solution_tree)

    # Create planner coordinator using injected adapter
    adapter = planner_adapter()
    coordinator = adapter.new_coordinator()

    # Convert domain to hybrid planner format if needed
    hybrid_domain = convert_domain_to_hybrid_format(domain)

    Logger.debug("Using injected planner adapter for planning with #{length(goals)} goals")

    # Use injected planner adapter for actual planning
    case adapter.plan(coordinator, hybrid_domain, state, goals) do
      {:ok, hybrid_plan} ->
        # Convert hybrid plan back to solution tree format
        case convert_hybrid_plan_to_solution_tree(hybrid_plan, goals, state) do
          {:ok, final_tree} ->
            Logger.debug("Successfully converted hybrid plan to solution tree")
            {:ok, final_tree}
          {:error, reason} ->
            Logger.error("Failed to convert hybrid plan: #{inspect(reason)}")
            {:error, reason}
        end
      {:error, reason} ->
        Logger.error("Planner adapter planning failed: #{inspect(reason)}")
        {:error, :planning_failed}
    end
  end

  @spec execute_solution_tree(domain(), state(), solution_tree()) ::
    {:ok, state(), solution_tree()} | {:error, atom()}
  defp execute_solution_tree(domain, initial_state, solution_tree) do
    try do
      # Use the injected adapter for execution if it supports it
      adapter = planner_adapter()

      if function_exported?(adapter, :execute, 4) do
        # Use adapter execution
        coordinator = adapter.new_coordinator()
        case adapter.execute(coordinator, domain, initial_state, solution_tree) do
          {:ok, final_state} ->
            # For simplified solution tree formats (like in tests), just return the tree as-is
            updated_tree = if Map.has_key?(solution_tree, :nodes) do
              Plan.update_cached_states(solution_tree, final_state)
            else
              solution_tree
            end
            {:ok, final_state, updated_tree}
          {:error, reason} ->
            {:error, reason}
        end
      else
        # Fall back to internal execution
        execute_solution_tree_internal(domain, initial_state, solution_tree)
      end
    rescue
      error ->
        Logger.error("Execution error: #{inspect(error)}")
        {:error, :execution_error}
    end
  end

  @spec execute_solution_tree_internal(domain(), state(), solution_tree()) ::
    {:ok, state(), solution_tree()} | {:error, atom()}
  defp execute_solution_tree_internal(domain, initial_state, solution_tree) do
    # Extract primitive actions from solution tree
    actions = Plan.get_primitive_actions_dfs(solution_tree)

    Logger.debug("Executing #{length(actions)} primitive actions")

    # Execute actions sequentially
    case execute_actions(domain, initial_state, actions) do
      {:ok, final_state} ->
        # Update solution tree with final state
        updated_tree = Plan.update_cached_states(solution_tree, final_state)
        {:ok, final_state, updated_tree}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec execute_actions(domain(), state(), [Plan.plan_step()]) :: {:ok, state()} | {:error, atom()}
  defp execute_actions(_domain, state, []) do
    {:ok, state}
  end

  defp execute_actions(domain, state, [{action_name, args} | remaining_actions]) do
    Logger.debug("Executing action: #{inspect(action_name)} with args: #{inspect(args)}")

    # TODO: Implement actual action execution
    # This is a placeholder that assumes all actions succeed
    # Real implementation would:
    # 1. Look up action in domain
    # 2. Execute action with current state and args
    # 3. Handle failures and trigger replanning if needed
    # 4. Update state with action results

    case execute_single_action(domain, state, action_name, args) do
      {:ok, new_state} ->
        execute_actions(domain, new_state, remaining_actions)
      {:error, reason} ->
        Logger.error("Action #{action_name} failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec execute_single_action(domain(), state(), atom() | String.t(), list()) :: {:ok, state()}
  defp execute_single_action(_domain, state, action_name, _args) do
    # For now, just return the same state (placeholder implementation)
    # Real implementation would execute the action through the domain
    Logger.debug("Action #{action_name} executed successfully")
    {:ok, state}
  end

  # ==================== CONVERSION HELPERS ====================

  @spec convert_domain_to_hybrid_format(domain()) :: any()
  defp convert_domain_to_hybrid_format(domain) do
    # For now, pass through the domain as-is
    # AriaHybridPlanner.Core should be able to handle AriaEngine.Domain.t()
    # If type conversion is needed, it would be implemented here
    domain
  end

  @spec convert_hybrid_plan_to_solution_tree(map(), [todo_item()], state()) :: {:ok, solution_tree()} | {:error, atom()}
  defp convert_hybrid_plan_to_solution_tree(hybrid_plan, goals, state) do
    try do
      # Extract actions from hybrid plan and convert to solution tree format
      case extract_actions_from_hybrid_plan(hybrid_plan) do
        {:ok, actions} ->
          # Create solution tree with the extracted actions
          solution_tree = Plan.create_solution_tree_from_actions(actions, goals, state)
          {:ok, solution_tree}
        {:error, reason} ->
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Error converting hybrid plan to solution tree: #{inspect(error)}")
        {:error, :conversion_failed}
    end
  end

  @spec extract_actions_from_hybrid_plan(map()) :: {:ok, [Plan.plan_step()]} | {:error, atom()}
  defp extract_actions_from_hybrid_plan(hybrid_plan) when is_map(hybrid_plan) do
    try do
      # Handle different hybrid plan formats
      actions = case hybrid_plan do
        %{"actions" => action_list} when is_list(action_list) ->
          Enum.map(action_list, &convert_hybrid_action_to_plan_step/1)
        %{"plan" => plan_data} ->
          extract_actions_from_plan_data(plan_data)
        _ ->
          # Try to extract actions from the plan structure
          extract_actions_recursive(hybrid_plan)
      end

      {:ok, actions}
    rescue
      error ->
        Logger.error("Failed to extract actions from hybrid plan: #{inspect(error)}")
        {:error, :action_extraction_failed}
    end
  end

  defp extract_actions_from_hybrid_plan(_), do: {:error, :invalid_plan_format}

  @spec convert_hybrid_action_to_plan_step(any()) :: Plan.plan_step()
  defp convert_hybrid_action_to_plan_step(action) do
    case action do
      %{"name" => name, "args" => args} ->
        {name, args}
      {name, args} when is_binary(name) or is_atom(name) ->
        {name, args}
      name when is_binary(name) or is_atom(name) ->
        {name, []}
      _ ->
        # Fallback for unknown formats
        {"unknown_action", [action]}
    end
  end

  @spec extract_actions_from_plan_data(any()) :: [Plan.plan_step()]
  defp extract_actions_from_plan_data(plan_data) when is_list(plan_data) do
    Enum.flat_map(plan_data, &extract_actions_recursive/1)
  end

  defp extract_actions_from_plan_data(plan_data) do
    extract_actions_recursive(plan_data)
  end

  @spec extract_actions_recursive(any()) :: [Plan.plan_step()]
  defp extract_actions_recursive(data) when is_map(data) do
    case data do
      %{"type" => "action", "name" => name, "args" => args} ->
        [{name, args}]
      %{"type" => "action", "name" => name} ->
        [{name, []}]
      %{"children" => children} when is_list(children) ->
        Enum.flat_map(children, &extract_actions_recursive/1)
      _ ->
        # Look for any nested structures that might contain actions
        data
        |> Map.values()
        |> Enum.flat_map(fn
          value when is_list(value) -> Enum.flat_map(value, &extract_actions_recursive/1)
          value when is_map(value) -> extract_actions_recursive(value)
          _ -> []
        end)
    end
  end

  defp extract_actions_recursive(data) when is_list(data) do
    Enum.flat_map(data, &extract_actions_recursive/1)
  end

  defp extract_actions_recursive({name, args}) when is_binary(name) or is_atom(name) do
    [{name, args}]
  end

  defp extract_actions_recursive(_), do: []
end
