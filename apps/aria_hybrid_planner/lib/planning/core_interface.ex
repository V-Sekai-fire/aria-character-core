# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planning.CoreInterface do
  @moduledoc "Replan from a failure point using HybridPlanner.HybridCoordinatorV2.\n"
  alias Planning.Internal
  alias AriaEngine.Core
  @type t :: Planning.HighLevel.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()
  @doc "Simple planning interface - finds a plan to achieve the given todos.\n"
  @spec plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [todo_item()], keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def plan(domain, %AriaEngine.State{} = state, todos, opts \\ []) do
    # Note: AriaEngine.PlannerAdapter.plan currently only returns {:error, String.t()}
    # This is a stub implementation - full planning requires aria_hybrid_planner integration
    AriaEngine.PlannerAdapter.plan(domain, state, todos, opts)
  end

  @doc "Advanced planning interface - returns the full solution tree.\n"
  @spec plan_with_tree(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [todo_item()], keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(domain, %AriaEngine.State{} = state, todos, opts \\ []) do
    AriaEngine.PlannerAdapter.plan(domain, state, todos, opts)
  end

  @doc "Executes a plan step by step, returning the final state.\n"
  @spec execute_plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [plan_step()]) ::
          {:ok, AriaEngine.Core.state()} | {:error, String.t()}
  def execute_plan(domain, %AriaEngine.State{} = initial_state, plan) do
    AriaEngine.PlannerAdapter.validate_plan(domain, initial_state, plan)
  end

  @doc "Replan from a failure point using HybridPlanner.HybridCoordinator.\n"
  @spec replan(AriaEngine.Core.t(), String.t(), keyword()) :: {:ok, AriaEngine.Core.t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\ [])

  def replan(%AriaEngine.Core{solution_tree: solution_tree} = engine, fail_node_id, opts)
      when not is_nil(solution_tree) do
    domain_interface = Internal.to_planner_interface(engine)

    # Note: AriaEngine.PlannerAdapter.replan currently only returns {:error, String.t()}
    # This is a stub implementation - full replanning requires aria_hybrid_planner integration
    AriaEngine.PlannerAdapter.replan(
      domain_interface,
      engine.current_state,
      solution_tree,
      fail_node_id,
      opts
    )
  end

  def replan(%AriaEngine.Core{solution_tree: nil}, _fail_node_id, _opts) do
    {:error, "No solution tree available for replanning"}
  end

  @doc "Validate the current plan.\n"
  @spec validate_plan(AriaEngine.Core.t()) :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def validate_plan(%AriaEngine.Core{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do
    domain_interface = Internal.to_planner_interface(engine)
    AriaEngine.PlannerAdapter.validate_plan(domain_interface, engine.initial_state, solution_tree)
  end

  def validate_plan(%AriaEngine.Core{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end
end
