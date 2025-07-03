# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  AriaHybridPlanner provides core temporal planning and execution capabilities.

  ## Usage

      # Plan and execute in one step (recommended)
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, todos)

      # Plan first, then execute separately
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, opts)
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.run_lazy_tree(domain, state, plan.solution_tree)

      # Advanced planning with options
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, verbose: 2, max_depth: 15)

  ## Key Features

  - HTN (Hierarchical Task Network) planning
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery
  - Entity-based resource management

  ## API Functions

  ### Primary API
  - `plan/4` - Planning with options, returns detailed plan structure
  - `run_lazy/3` - Plan and execute in one step
  - `run_lazy_tree/3` - Execute with existing solution tree
  """

  # Type definitions
  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type todo_item :: AriaEngineCore.Plan.todo_item()
  @type solution_tree :: AriaEngineCore.Plan.solution_tree()
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @type execution_result :: {:ok, {state(), solution_tree()}} | {:error, String.t()}
  @type lazy_execution_result :: {:ok, state()} | {:error, String.t()}

  # Delegate to internal modules
  @spec plan(domain(), state(), [todo_item()], keyword()) :: plan_result()
  defdelegate plan(domain, initial_state, todos, opts \\ []), to: AriaHybridPlanner.Planner

  @spec run_lazy(domain(), state(), [todo_item()], keyword()) :: execution_result()
  defdelegate run_lazy(domain, initial_state, todos, opts \\ []), to: AriaHybridPlanner.Execution

  @spec run_lazy_tree(domain(), state(), solution_tree(), keyword()) :: lazy_execution_result()
  defdelegate run_lazy_tree(domain, initial_state, solution_tree, opts \\ []), to: AriaHybridPlanner.Execution

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
