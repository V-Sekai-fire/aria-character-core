# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  AriaHybridPlanner provides core temporal planning and execution capabilities.

  This module contains the unified implementation for the Aria planning system,
  combining the functionality previously split between AriaEngineCore and AriaHybridPlanner.

  ## Usage

      # Plan and execute in one step (recommended)
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, goals)

      # Plan first, then execute separately
      {:ok, solution_tree} = AriaHybridPlanner.plan(domain, state, goals)
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.run_lazy_tree(domain, state, solution_tree)

      # Use the coordinator API for advanced control
      coordinator = AriaHybridPlanner.Core.new_coordinator()
      {:ok, plan} = AriaHybridPlanner.Core.plan(coordinator, domain, state, goals)
      {:ok, final_state} = AriaHybridPlanner.Core.execute(coordinator, domain, state, plan)

  ## Key Features

  - Unified durative action specification
  - Entity-based resource management
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery
  - HTN (Hierarchical Task Network) planning

  ## Types

  The module uses standardized types from the AriaEngine ecosystem:
  - `AriaHybridPlanner.Domain.t()` - Domain definitions
  - `AriaHybridPlanner.State.t()` - World state representation
  - `AriaHybridPlanner.todo_item()` - Work items and goals
  - `AriaHybridPlanner.Plan.solution_tree()` - Planning results

  ## API Functions

  ### Simple API (recommended for most use cases)
  - `plan/3` - Planning only, returns solution tree
  - `run_lazy/3` - Planning + execution, returns final state and solution tree
  - `run_lazy_tree/3` - Execute pre-made plan, returns final state and updated tree

  ### Advanced API (for fine-grained control)
  - `AriaHybridPlanner.Core.*` - Coordinator-based planning with advanced options
  """

  # Type aliases for external API compatibility
  @type domain :: AriaHybridPlanner.Domain.t()
  @type state :: AriaHybridPlanner.State.t()
  @type todo_item :: AriaHybridPlanner.Core.todo_item()
  @type solution_tree :: AriaHybridPlanner.Plan.solution_tree()

  # Delegate core functions to the unified API for convenience
  defdelegate new_coordinator(opts \\ []), to: AriaHybridPlanner.Core
  defdelegate plan(coordinator, domain, state, goals, opts \\ []), to: AriaHybridPlanner.Core
  defdelegate execute(coordinator, domain, state, plan, opts \\ []), to: AriaHybridPlanner.Core
  defdelegate validate_plan(coordinator, domain, state, plan), to: AriaHybridPlanner.Core
  defdelegate replan(coordinator, domain, state, plan, fail_node_id, opts \\ []), to: AriaHybridPlanner.Core
  defdelegate plan_and_execute(coordinator, domain, state, goals, opts \\ []), to: AriaHybridPlanner.Core

  # Engine integration functions for AriaEngineCore compatibility
  # These provide a bridge between AriaEngineCore's API and AriaHybridPlanner.Core

  @doc """
  Plan only (no execution) - compatible with AriaEngineCore API.
  Returns only the solution tree portion of the plan.
  """
  def plan(domain, state, goals) do
    coordinator = AriaHybridPlanner.Core.new_coordinator()
    case AriaHybridPlanner.Core.plan(coordinator, domain, state, goals) do
      {:ok, plan} ->
        # Extract solution tree from plan structure
        solution_tree = extract_solution_tree(plan)
        {:ok, solution_tree}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Plan and execute with lazy execution - compatible with AriaEngineCore API.
  """
  def run_lazy(domain, state, goals) do
    coordinator = AriaHybridPlanner.Core.new_coordinator()
    case AriaHybridPlanner.Core.plan_and_execute(coordinator, domain, state, goals) do
      {:ok, result} ->
        final_state = Map.get(result, :final_state, state)
        solution_tree = extract_solution_tree(result)
        {:ok, {final_state, solution_tree}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Execute a pre-made solution tree - compatible with AriaEngineCore API.
  """
  def run_lazy_tree(domain, state, solution_tree) do
    coordinator = AriaHybridPlanner.Core.new_coordinator()
    case AriaHybridPlanner.Core.execute(coordinator, domain, state, solution_tree) do
      {:ok, result} ->
        final_state = Map.get(result, :final_state, state)
        {:ok, {final_state, solution_tree}}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper function to extract solution tree from plan structure
  defp extract_solution_tree(plan) when is_map(plan) do
    # Extract actions from the plan and convert to steps format
    actions = Map.get(plan, :actions, [])
    steps = convert_actions_to_steps(actions)

    %{
      root_id: Map.get(plan, :root_id, "root"),
      nodes: Map.get(plan, :nodes, %{}),
      steps: steps,
      goal_network: Map.get(plan, :goal_network, %{}),
      blacklisted_commands: Map.get(plan, :blacklisted_commands, MapSet.new()),
      # Include additional useful fields for solution tree
      metrics: Map.get(plan, :metrics, %{}),
      status: Map.get(plan, :status, :unknown)
    }
  end

  defp extract_solution_tree(_), do: %{
    root_id: "root",
    nodes: %{},
    steps: [],
    goal_network: %{},
    blacklisted_commands: MapSet.new(),
    metrics: %{},
    status: :empty
  }

  defp convert_actions_to_steps(_), do: []

  # State Management API - Delegate to internal State module
  defdelegate new_state(), to: AriaHybridPlanner.State, as: :new
  defdelegate new_state(data), to: AriaHybridPlanner.State, as: :new
  defdelegate get_fact(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate set_fact(state, predicate, subject, value), to: AriaHybridPlanner.State
  defdelegate has_subject?(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate remove_fact(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate get_subjects_with_fact(state, predicate, value), to: AriaHybridPlanner.State

  @doc """
  Get the domain type for external API compatibility.

  Returns the domain type for use in external type specifications.

  ## Examples

      @type my_domain :: AriaHybridPlanner.domain()
  """
  @spec domain() :: module()
  def domain, do: AriaHybridPlanner.Domain

  @doc """
  Get the state type for external API compatibility.

  Returns the state type for use in external type specifications.

  ## Examples

      @type my_state :: AriaHybridPlanner.state()
  """
  @spec state() :: module()
  def state, do: AriaHybridPlanner.State

  @doc """
  Get the todo_item type for external API compatibility.

  Returns the todo_item type for use in external type specifications.

  ## Examples

      @type my_todo :: AriaHybridPlanner.todo_item()
  """
  @spec todo_item() :: module()
  def todo_item, do: AriaHybridPlanner.Core

  @doc """
  Get the solution tree from the planner.

  Returns the current solution tree if available.
  """
  @spec solution_tree() :: solution_tree() | nil
  def solution_tree do
    # This would typically be stored in process state or ETS
    # For now, return nil as a placeholder
    nil
  end

  @spec version() :: String.t()
  @doc """
  Returns the version of the AriaHybridPlanner application.
  """
  def version do
    case Application.spec(:aria_hybrid_planner, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
