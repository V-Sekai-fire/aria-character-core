# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore do
  @moduledoc """
  AriaEngineCore provides a unified interface for temporal planning and execution.

  This module serves as the main entry point for the Aria planning system,
  offering both planning-only and planning-with-execution capabilities.
  Implements the R25W1398085 unified durative action specification.

  ## Usage

      # Plan and execute in one step
      {:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)

      # Plan first, then execute separately
      {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)
      {:ok, {final_state, updated_tree}} = AriaEngineCore.run_lazy_tree(domain, state, solution_tree)

  ## Key Features

  - Unified durative action specification (R25W1398085)
  - Entity-based resource management
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery

  ## Types

  The module uses standardized types from the AriaEngine ecosystem:
  - `AriaEngine.Domain.t()` - Domain definitions
  - `AriaState.t()` - World state representation
  - `AriaEngine.todo_item()` - Work items and goals
  - `AriaEngineCore.Plan.solution_tree()` - Planning results

  ## API Functions

  - `plan/3` - Planning only, returns solution tree
  - `run_lazy/3` - Planning + execution, returns final state and solution tree
  - `run_lazy_tree/3` - Execute pre-made plan, returns final state and updated tree
  """

  # Type aliases for external API matching ADR R25W1398085
  @type domain :: AriaEngine.Domain.t()
  @type state :: AriaState.t()
  @type todo_item :: AriaEngine.todo_item()
  @type solution_tree :: AriaEngineCore.Plan.solution_tree()

  @doc """
  Plan to achieve goals without execution.

  This function only performs planning and returns the solution tree without executing it.
  Use this when you need to inspect or modify the plan before execution.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, solution_tree}` - Success with generated solution tree
  - `{:error, reason}` - Failure with error description

  ## Example

      {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)
      IO.inspect(solution_tree, label: "Generated plan")
  """
  @spec plan(domain(), state(), [todo_item()]) :: {:ok, solution_tree()} | {:error, atom()}
  def plan(domain, state, goals) do
    AriaEngineCore.Planner.plan(domain, state, goals)
  end

  @doc """
  Plan and execute goals with automatic recovery.

  This is the recommended function for most use cases. It combines planning
  and execution with intelligent recovery from failures.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, {final_state, solution_tree}}` - Success with final state and solution tree
  - `{:error, reason}` - Failure with error description

  ## Example

      domain = MyDomain.new()
      state = MyState.new()
      goals = [{:achieve, :goal1}, {:achieve, :goal2}]

      {:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)
      IO.puts("Goals achieved!")
  """
  @spec run_lazy(domain(), state(), [todo_item()]) :: {:ok, {state(), solution_tree()}} | {:error, atom()}
  def run_lazy(domain, state, goals) do
    AriaEngineCore.Planner.run_lazy(domain, state, goals)
  end

  @doc """
  Execute a pre-made solution tree.

  This function takes a solution tree that was created and validated earlier
  and executes it, returning the final state and updated tree.

  ## Parameters

  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `solution_tree` - Pre-made solution tree to execute

  ## Returns

  - `{:ok, {final_state, updated_tree}}` - Success with final state and updated tree
  - `{:error, reason}` - Failure with error description

  ## Example

      # Execute a solution tree that was created earlier
      {:ok, {final_state, updated_tree}} = AriaEngineCore.run_lazy_tree(domain, state, solution_tree)
      IO.puts("Plan executed successfully!")
  """
  @spec run_lazy_tree(domain(), state(), solution_tree()) :: {:ok, {state(), solution_tree()}} | {:error, atom()}
  def run_lazy_tree(domain, state, solution_tree) do
    AriaEngineCore.Planner.run_lazy_tree(domain, state, solution_tree)
  end

  @doc """
  Get the version of AriaEngine Core.

  ## Examples

      iex> AriaEngineCore.version()
      "0.1.0"
  """
  @spec version() :: String.t()
  def version do
    case Application.spec(:aria_engine_core, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
