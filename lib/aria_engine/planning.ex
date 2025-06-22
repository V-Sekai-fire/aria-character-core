# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planning do
  @moduledoc """
  Provides core planning and execution functionalities for the Aria Engine.
  """

  alias AriaEngine.Planning.CoreInterface
  alias AriaEngine.Plan.Core

  @type t :: Core.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()
  @type domain :: AriaEngine.Domain.Core.t()
  @type state :: AriaEngine.StateV2.t()

  # CoreInterface functions
  @spec plan(domain(), state(), [todo_item()], keyword()) :: {:ok, solution_tree()} | {:error, String.t()}
  defdelegate plan(domain, state, todos, opts), to: CoreInterface
  
  @spec plan_with_tree(domain(), state(), [todo_item()], keyword()) :: {:ok, {solution_tree(), t()}} | {:error, String.t()}
  defdelegate plan_with_tree(domain, state, todos, opts), to: CoreInterface
  
  @spec execute_plan(domain(), state(), [plan_step()]) :: {:ok, state()} | {:error, String.t()}
  defdelegate execute_plan(domain, initial_state, plan), to: CoreInterface
  
  @spec replan(t(), String.t(), keyword()) :: {:ok, solution_tree()} | {:error, String.t()}
  defdelegate replan(engine, fail_node_id, opts), to: CoreInterface
  
  @spec validate_plan(t()) :: {:ok, state()} | {:error, String.t()}
  defdelegate validate_plan(engine), to: CoreInterface

  # Internal functions (if any need to be exposed, though typically not)
  # defdelegate to_planner_interface(engine), to: Internal
end
