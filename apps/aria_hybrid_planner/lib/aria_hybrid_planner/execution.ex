# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.Execution do
  @moduledoc """
  Execution logic for AriaHybridPlanner.

  This module handles the execution of planned solution trees using lazy execution.
  """

  alias Plan.ReentrantExecutor

  # Type definitions
  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type todo_item :: AriaEngineCore.Plan.todo_item()
  @type solution_tree :: AriaEngineCore.Plan.solution_tree()
  @type execution_result :: {:ok, {state(), solution_tree()}} | {:error, String.t()}
  @type lazy_execution_result :: {:ok, state()} | {:error, String.t()}

  @doc """
  Plan and execute in one step using lazy execution.
  """
  @spec run_lazy(domain(), state(), [todo_item()], keyword()) :: execution_result()
  def run_lazy(domain, initial_state, todos, opts \\ []) do
    case AriaHybridPlanner.Planner.plan(domain, initial_state, todos, opts) do
      {:ok, plan} ->
        case run_lazy_tree(domain, initial_state, plan.solution_tree, opts) do
          {:ok, final_state} ->
            {:ok, {final_state, plan.solution_tree}}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Execute a solution tree using lazy execution.
  """
  @spec run_lazy_tree(domain(), state(), solution_tree(), keyword()) :: lazy_execution_result()
  def run_lazy_tree(domain, initial_state, solution_tree, opts \\ []) do
    # Add domain to options for executor
    execution_opts = Keyword.put(opts, :domain, domain)
    ReentrantExecutor.execute_plan_lazy(solution_tree, initial_state, execution_opts)
  end
end
