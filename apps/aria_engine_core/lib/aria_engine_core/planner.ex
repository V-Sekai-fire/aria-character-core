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

  # Type aliases matching ADR R25W1398085 specification
  @type domain :: AriaEngine.Domain.t()
  @type state :: AriaState.t()
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
  defp perform_planning(_domain, _state, solution_tree) do
    # TODO: Implement actual planning logic
    # This is a placeholder that returns the initial tree as "planned"
    # Real implementation would:
    # 1. Expand non-primitive tasks using domain methods
    # 2. Resolve goals using domain goal methods
    # 3. Handle temporal constraints and resource allocation
    # 4. Build complete solution tree with all primitive actions

    Logger.warn("Planning implementation is placeholder - returning initial tree")
    {:ok, solution_tree}
  end

  @spec execute_solution_tree(domain(), state(), solution_tree()) ::
    {:ok, state(), solution_tree()} | {:error, atom()}
  defp execute_solution_tree(domain, initial_state, solution_tree) do
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

  @spec execute_single_action(domain(), state(), atom() | String.t(), list()) :: {:ok, state()} | {:error, atom()}
  defp execute_single_action(_domain, state, _action_name, _args) do
    # TODO: Implement actual single action execution
    # This is a placeholder that returns the state unchanged
    # Real implementation would:
    # 1. Convert action_name to proper format
    # 2. Look up action function in domain
    # 3. Call action function with state and args
    # 4. Return updated state or error

    Logger.warn("Action execution is placeholder - returning unchanged state")
    {:ok, state}
  end
end
