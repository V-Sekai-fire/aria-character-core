# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planning do
  @moduledoc """
  Provides core planning and execution functionalities for the Aria Engine.
  """

  alias Planning.HighLevel
  alias Planning.CoreInterface
  alias Core

  @type t :: Core.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()

  # HighLevel functions
  defdelegate plan_advanced(engine, opts), to: HighLevel
  defdelegate execute(engine, opts), to: HighLevel
  defdelegate run(engine, opts), to: HighLevel

  # CoreInterface functions
  defdelegate plan(domain, state, todos, opts), to: CoreInterface
  defdelegate plan_with_tree(domain, state, todos, opts), to: CoreInterface
  defdelegate execute_plan(domain, initial_state, plan), to: CoreInterface
  defdelegate replan(engine, fail_node_id, opts), to: CoreInterface
  defdelegate validate_plan(engine), to: CoreInterface

  # Internal functions (if any need to be exposed, though typically not)
  # defdelegate to_planner_interface(engine), to: Internal
end
