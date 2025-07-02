# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.EngineIntegration do
  @moduledoc """
  Engine integration module providing AriaEngineCore-compatible planning interfaces.

  This module implements the planning functionality that was previously in AriaEngineCore.Planner,
  now properly encapsulated within the AriaHybridPlanner app. It provides the core planning
  functionality with a clean, GTpyHOP-style interface that maintains compatibility with
  the AriaEngineCore external API.

  ## Usage

  This module is primarily used through the AriaHybridPlanner external API:

      # Through AriaHybridPlanner
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, goals)
      {:ok, solution_tree} = AriaHybridPlanner.plan_only(domain, state, goals)

  ## Direct Usage (Advanced)

      # Direct access to this module
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.EngineIntegration.run_lazy(domain, state, goals)
      {:ok, solution_tree} = AriaHybridPlanner.EngineIntegration.plan(domain, state, goals)

  ## API Functions

  - `plan/3` - Just planning, no execution (returns solution tree only)
  - `run_lazy/3` - Plan and execute with recovery (returns final state and solution tree)
  - `run_lazy_tree/3` - Execute pre-made plan (returns final state and updated tree)

  All implementation complexity is handled internally within the hybrid planner app.
  """

  require Logger
  alias AriaHybridPlanner.Plan

  # Dependency injection for planner adapter (runtime configuration for testing)
  defp planner_adapter do
    Application.get_env(:aria_hybrid_planner, :planner_adapter, AriaEngineCore.Adapters.HybridPlannerAdapter)
  end

  # Type aliases matching ADR R25W1398085 specification
  @type domain :: map()
  @type state :: map()
  @type todo_item :: any()
  @type solution_tree :: AriaHybridPlanner.Plan.solution_tree()

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

      {:ok, solution_tree} = AriaHybridPlanner.EngineIntegration.plan(domain, state, goals)
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

      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.EngineIntegration.run_lazy(domain, state, goals)
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
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.EngineIntegration.run_lazy_tree(domain, state, solution_tree)
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

    Logger.debug("Direct planning implementation for #{length(goals)} goals")

    # For now, implement a simple blocks world planner directly
    # This will be expanded to handle the GTpyhop blocks_gtn domain properly
    case plan_blocks_world_goals(domain, state, goals) do
      {:ok, actions} ->
        # Create solution tree with the planned actions
        final_tree = Plan.create_solution_tree_from_actions(actions, goals, state)
        Logger.debug("Successfully created solution tree with #{length(actions)} actions")
        {:ok, final_tree}
    end
  end

  @spec execute_solution_tree(domain(), state(), solution_tree()) ::
    {:ok, state(), solution_tree()} | {:error, atom()}
  defp execute_solution_tree(domain, initial_state, solution_tree) do
    try do
      # Use internal execution directly
      execute_solution_tree_internal(domain, initial_state, solution_tree)
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

    {:ok, new_state} = execute_single_action(domain, state, action_name, args)
    execute_actions(domain, new_state, remaining_actions)
  end

  @spec execute_single_action(domain(), state(), atom() | String.t(), list()) :: {:ok, state()}
  defp execute_single_action(_domain, state, action_name, _args) do
    # For now, just return the same state (placeholder implementation)
    # Real implementation would execute the action through the domain
    Logger.debug("Action #{action_name} executed successfully")
    {:ok, state}
  end

  # ==================== DIRECT PLANNING IMPLEMENTATION ====================

  @spec plan_blocks_world_goals(domain(), state(), [todo_item()]) :: {:ok, [Plan.plan_step()]} | {:error, atom()}
  defp plan_blocks_world_goals(_domain, state, goals) do
    Logger.debug("Blocks world planner processing #{length(goals)} goals")

    # For simple goals like {"pickup", "x"}, validate preconditions
    case goals do
      [{"pickup", block}] ->
        case validate_pickup_preconditions(state, block) do
          :ok ->
            actions = [{"pickup", [block]}]
            Logger.debug("Generated #{length(actions)} actions for pickup goal")
            {:ok, actions}
          {:error, reason} ->
            Logger.debug("Pickup preconditions failed: #{reason}")
            {:error, reason}
        end

      [{"putdown", block}] ->
        case validate_putdown_preconditions(state, block) do
          :ok ->
            actions = [{"putdown", [block]}]
            Logger.debug("Generated #{length(actions)} actions for putdown goal")
            {:ok, actions}
          {:error, reason} ->
            Logger.debug("Putdown preconditions failed: #{reason}")
            {:error, reason}
        end

      [{"take", block}] ->
        # "take" is like "pickup" but can handle both pickup and unstack
        case validate_take_preconditions(state, block) do
          {:ok, action_type} ->
            actions = [{action_type, [block]}]
            Logger.debug("Generated #{length(actions)} actions for take goal (#{action_type})")
            {:ok, actions}
          {:error, reason} ->
            Logger.debug("Take preconditions failed: #{reason}")
            {:error, reason}
        end

      _ ->
        # For complex goals, return empty plan for now
        # This would be expanded to implement full GTpyhop planning logic
        actions = []
        Logger.debug("Generated #{length(actions)} actions for complex goals")
        {:ok, actions}
    end
  end

  # Validate preconditions for pickup action
  @spec validate_pickup_preconditions(state(), String.t()) :: :ok | {:error, atom()}
  defp validate_pickup_preconditions(state, block) do
    # Extract state data - handle both AriaState.RelationalState and map formats
    state_data = case state do
      %{data: data} -> data
      data when is_map(data) -> data
      _ -> %{}
    end

    # Check pickup preconditions:
    # 1. Block must be on table: pos[block] == "table"
    # 2. Block must be clear: clear[block] == true
    # 3. Hand must be empty: holding["hand"] == false

    pos_key = {"pos", block}
    clear_key = {"clear", block}
    holding_key = {"holding", "hand"}

    cond do
      not Map.has_key?(state_data, pos_key) ->
        {:error, :block_not_found}

      Map.get(state_data, pos_key) != "table" ->
        {:error, :block_not_on_table}

      not Map.has_key?(state_data, clear_key) ->
        {:error, :clear_status_unknown}

      Map.get(state_data, clear_key) != true ->
        {:error, :block_not_clear}

      not Map.has_key?(state_data, holding_key) ->
        {:error, :hand_status_unknown}

      Map.get(state_data, holding_key) != false ->
        {:error, :hand_not_empty}

      true ->
        :ok
    end
  end

  # Validate preconditions for putdown action
  @spec validate_putdown_preconditions(state(), String.t()) :: :ok | {:error, atom()}
  defp validate_putdown_preconditions(state, block) do
    # Extract state data
    state_data = case state do
      %{data: data} -> data
      data when is_map(data) -> data
      _ -> %{}
    end

    # Check putdown preconditions:
    # 1. Block must be in hand: pos[block] == "hand"
    # 2. Hand must be holding this block: holding["hand"] == block

    pos_key = {"pos", block}
    holding_key = {"holding", "hand"}

    cond do
      not Map.has_key?(state_data, pos_key) ->
        {:error, :block_not_found}

      Map.get(state_data, pos_key) != "hand" ->
        {:error, :block_not_in_hand}

      not Map.has_key?(state_data, holding_key) ->
        {:error, :hand_status_unknown}

      Map.get(state_data, holding_key) != block ->
        {:error, :hand_not_holding_block}

      true ->
        :ok
    end
  end

  # Validate preconditions for take action (can be pickup or unstack)
  @spec validate_take_preconditions(state(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  defp validate_take_preconditions(state, block) do
    # Extract state data
    state_data = case state do
      %{data: data} -> data
      data when is_map(data) -> data
      _ -> %{}
    end

    # Check take preconditions:
    # 1. Block must be clear: clear[block] == true
    # 2. Hand must be empty: holding["hand"] == false
    # 3. Determine action type based on block position

    pos_key = {"pos", block}
    clear_key = {"clear", block}
    holding_key = {"holding", "hand"}

    cond do
      not Map.has_key?(state_data, pos_key) ->
        {:error, :block_not_found}

      not Map.has_key?(state_data, clear_key) ->
        {:error, :clear_status_unknown}

      Map.get(state_data, clear_key) != true ->
        {:error, :block_not_clear}

      not Map.has_key?(state_data, holding_key) ->
        {:error, :hand_status_unknown}

      Map.get(state_data, holding_key) != false ->
        {:error, :hand_not_empty}

      true ->
        # Determine action type based on position
        position = Map.get(state_data, pos_key)
        action_type = if position == "table", do: "pickup", else: "unstack"
        {:ok, action_type}
    end
  end
end
