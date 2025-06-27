# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.PlanningCore do
  @moduledoc "Provides core planning and execution functionalities for the Aria Engine.\n"
  alias Planning.CoreInterface
  @type t :: AriaEngine.Core.t()
  @type solution_tree :: AriaEngine.Core.solution_tree()
  @type plan_step :: AriaEngine.Core.plan_step()
  @type todo_item :: AriaEngine.Core.todo_item()
  defdelegate plan(domain, state, todos, opts), to: CoreInterface
  defdelegate plan_with_tree(domain, state, todos, opts), to: CoreInterface
  defdelegate execute_plan(domain, initial_state, plan), to: CoreInterface
  defdelegate replan(engine, fail_node_id, opts), to: CoreInterface
  defdelegate validate_plan(engine), to: CoreInterface
end
