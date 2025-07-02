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

  @doc "Executes a plan step by step, returning the final state.\n"
  @spec execute_plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [plan_step()]) ::
          {:ok, AriaEngine.Core.state()} | {:error, String.t()}
  def execute_plan(_domain, _initial_state, _plan) do
    # TODO: Implement actual plan execution using aria_hybrid_planner
    {:error, "Plan execution not yet implemented in self-contained mode"}
  end

  @doc "Validate the current plan.\n"
  @spec validate_plan(Core.t()) :: {:ok, map()} | {:error, String.t()}
  def validate_plan(%Core{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do
    _domain_interface = Internal.to_planner_interface(engine)
    # TODO: Implement actual plan validation using aria_hybrid_planner
    {:error, "Plan validation not yet implemented in self-contained mode"}
  end

  def validate_plan(%Core{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end
end
