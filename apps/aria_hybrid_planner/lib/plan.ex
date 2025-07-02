# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.PlanCore do

  @moduledoc """
  Main Plan module that provides the public API for planning operations.
  """

  # Import types from Plan.Core
  @type todo_item :: Plan.Core.todo_item()
  @type solution_tree :: Plan.Core.solution_tree()
  @type plan_result :: Plan.Core.plan_result()
  @type node_id :: Plan.Core.node_id()

  # Delegate execution functions to Plan.ReentrantExecutor (IPyHOP pattern)
  @spec run_lazy_refineahead(AriaEngine.Domain.Core.t(), AriaEngine.State.t(), term(), keyword()) ::
          {:ok, AriaEngine.State.t(), term()} | {:error, String.t(), term()}
  def run_lazy_refineahead(domain, state, plan, opts \\ []),
    do: Plan.ReentrantExecutor.execute_with_recovery(domain, state, plan, opts)
end
