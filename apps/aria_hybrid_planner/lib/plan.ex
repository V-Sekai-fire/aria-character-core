# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.PlanCore do
  alias AriaEngine.State

  @moduledoc """
  Main Plan module that provides the public API for planning operations.
  """

  # Import types from Plan.Core
  @type todo_item :: Plan.Core.todo_item()
  @type solution_tree :: Plan.Core.solution_tree()
  @type plan_result :: Plan.Core.plan_result()
  @type node_id :: Plan.Core.node_id()

  # Delegate core planning functions to Plan.Core
  @spec plan(AriaEngine.Domain.Core.t(), AriaEngine.State.t(), [todo_item()], keyword()) ::
          plan_result()
  def plan(domain, state, todos, opts \\ []), do: Plan.Core.plan(domain, state, todos, opts)

  @spec ipyhop(AriaEngine.Domain.Core.t(), AriaEngine.State.t(), solution_tree(), keyword()) ::
          plan_result()
  def ipyhop(domain, state, solution_tree, opts),
    do: Plan.Core.ipyhop(domain, state, solution_tree, opts)

  # Delegate execution functions to Plan.SimpleExecutor (IPyHOP pattern)
  @spec run_lazy_refineahead(AriaEngine.Domain.Core.t(), AriaEngine.State.t(), term(), keyword()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def run_lazy_refineahead(domain, state, plan, opts \\ []),
    do: Plan.SimpleExecutor.execute(domain, state, plan, opts)

  # Delegate replanning functions to Plan.Backtracking
  @spec replan(
          AriaEngine.Domain.Core.t(),
          AriaEngine.State.t(),
          solution_tree(),
          node_id(),
          keyword()
        ) :: plan_result()
  def replan(domain, state, solution_tree, fail_node_id, opts \\ []),
    do: Plan.Backtracking.replan(domain, state, solution_tree, fail_node_id, opts)
end
