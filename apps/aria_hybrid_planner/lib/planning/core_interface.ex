# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planning.CoreInterface do
  @moduledoc "Replan from a failure point using HybridPlanner.HybridCoordinatorV2.\n"
  alias Planning.Internal
  alias Core
  @type t :: Planning.HighLevel.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()
  @doc "Simple planning interface - finds a plan to achieve the given todos.\n"
  @spec plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [todo_item()], keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def plan(domain, state, todos, opts \\ []) do
    # Note: AriaEngine.PlannerAdapter.plan currently only returns {:error, String.t()}
    # This is a stub implementation - full planning requires aria_hybrid_planner integration
    # TODO: Implement actual planning logic using aria_hybrid_planner
    {:error, "Planning not yet implemented in self-contained mode"}
  end

  @doc "Advanced planning interface - returns the full solution tree.\n"
  @spec plan_with_tree(
          AriaEngine.DomainBehaviour.t(),
          AriaEngine.Core.state(),
          [todo_item()],
          keyword()
        ) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(domain, state, todos, opts \\ []) do
    # TODO: Implement actual planning logic using aria_hybrid_planner
    {:error, "Planning not yet implemented in self-contained mode"}
  end

  @doc "Executes a plan step by step, returning the final state.\n"
  @spec execute_plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [plan_step()]) ::
          {:ok, AriaEngine.Core.state()} | {:error, String.t()}
  def execute_plan(domain, initial_state, plan) do
    # TODO: Implement actual plan execution using aria_hybrid_planner
    {:error, "Plan execution not yet implemented in self-contained mode"}
  end

  @doc "Replan from a failure point using HybridPlanner.HybridCoordinator.\n"
  @spec replan(Core.t(), String.t(), keyword()) ::
          {:ok, Core.t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\ [])

  def replan(%Core{solution_tree: solution_tree} = engine, fail_node_id, opts)
      when not is_nil(solution_tree) do
    domain_interface = Internal.to_planner_interface(engine)

    # Note: AriaEngine.PlannerAdapter.replan currently only returns {:error, String.t()}
    # This is a stub implementation - full replanning requires aria_hybrid_planner integration
    # TODO: Implement actual replanning logic using aria_hybrid_planner
    {:error, "Replanning not yet implemented in self-contained mode"}
  end

  def replan(%Core{solution_tree: nil}, _fail_node_id, _opts) do
    {:error, "No solution tree available for replanning"}
  end

  @doc "Validate the current plan.\n"
  @spec validate_plan(Core.t()) :: {:ok, map()} | {:error, String.t()}
  def validate_plan(%Core{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do
    domain_interface = Internal.to_planner_interface(engine)
    # TODO: Implement actual plan validation using aria_hybrid_planner
    {:error, "Plan validation not yet implemented in self-contained mode"}
  end

  def validate_plan(%Core{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end
end
