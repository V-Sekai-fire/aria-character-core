# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  AriaHybridPlanner provides core temporal planning and execution capabilities.

  ## Usage

      # Plan and execute in one step (recommended)
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, todos)

      # Plan first, then execute separately
      {:ok, solution_tree} = AriaHybridPlanner.plan(domain, state, todos)
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.run_lazy_tree(domain, state, solution_tree)

      # Use the coordinator API for advanced control
      coordinator = AriaHybridPlanner.new_coordinator()
      {:ok, plan} = AriaHybridPlanner.plan(coordinator, domain, state, todos)
      {:ok, final_state} = AriaHybridPlanner.execute(coordinator, domain, state, plan)

  ## Key Features

  - HTN (Hierarchical Task Network) planning
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery
  - Entity-based resource management

  ## API Functions

  ### Simple API (recommended for most use cases)
  - `plan/3` - Planning only, returns solution tree
  - `run_lazy/3` - Planning + execution, returns final state and solution tree
  - `run_lazy_tree/3` - Execute pre-made plan, returns final state and updated tree

  ### Advanced API (for fine-grained control)
  - `new_coordinator/1` - Create coordinator for advanced planning
  - `plan/5` - Coordinator-based planning with options
  - `execute/5` - Coordinator-based execution with options
  """

  # Type definitions
  @type domain :: AriaHybridPlanner.Domain.t()
  @type state :: AriaHybridPlanner.State.t()
  @type todo_item :: term()
  @type solution_tree :: map()

  # Core coordinator functions
  defdelegate new_coordinator(opts \\ []), to: AriaHybridPlanner.Coordinator, as: :new_default
  defdelegate plan(coordinator, domain, state, todos, opts \\ []), to: AriaHybridPlanner.Coordinator
  defdelegate execute(coordinator, domain, state, plan, opts \\ []), to: AriaHybridPlanner.Coordinator
  defdelegate validate_plan(coordinator, domain, state, plan), to: AriaHybridPlanner.Coordinator

  # Replan is not implemented in HybridCoordinatorV2 yet
  def replan(_coordinator, _domain, _state, _plan, _fail_node_id, _opts \\ []) do
    {:error, "Replanning not yet implemented"}
  end

  # Plan and execute combines planning and execution
  def plan_and_execute(coordinator, domain, state, goals, opts \\ []) do
    case plan(coordinator, domain, state, goals, opts) do
      {:ok, plan} ->
        execute(coordinator, domain, state, plan, opts)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Simple API functions

  @doc """
  Plan only (no execution).
  Returns solution tree for the given todos.
  """
  def plan(domain, state, todos) do
    coordinator = new_coordinator()
    case plan(coordinator, domain, state, todos) do
      {:ok, plan} ->
        solution_tree = Map.get(plan, :solution_tree, %{})
        {:ok, solution_tree}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Plan and execute with lazy execution.
  """
  def run_lazy(domain, state, todos) do
    coordinator = new_coordinator()
    case plan_and_execute(coordinator, domain, state, todos) do
      {:ok, final_state} ->
        # Get solution tree from the plan
        case plan(coordinator, domain, state, todos) do
          {:ok, plan} ->
            solution_tree = Map.get(plan, :solution_tree, %{})
            {:ok, {final_state, solution_tree}}
          {:error, _} ->
            {:ok, {final_state, %{}}}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Execute a pre-made solution tree.
  """
  def run_lazy_tree(domain, state, solution_tree) do
    coordinator = new_coordinator()
    plan = %{solution_tree: solution_tree}
    case execute(coordinator, domain, state, plan) do
      {:ok, final_state} ->
        {:ok, {final_state, solution_tree}}
      {:error, reason} -> {:error, reason}
    end
  end

  # State Management API - Delegate to internal State module
  defdelegate new_state(), to: AriaHybridPlanner.State, as: :new
  defdelegate new_state(data), to: AriaHybridPlanner.State, as: :new
  defdelegate get_fact(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate set_fact(state, predicate, subject, value), to: AriaHybridPlanner.State
  defdelegate has_subject?(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate remove_fact(state, predicate, subject), to: AriaHybridPlanner.State
  defdelegate get_subjects_with_fact(state, predicate, value), to: AriaHybridPlanner.State


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
