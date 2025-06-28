# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Behaviours.PlannerBehaviour do
  @moduledoc """
  Behavior contract for planner implementations.

  This behavior defines the interface that all planner adapters must implement,
  enabling dependency injection and testing with Mox. It abstracts the core
  planning operations needed by AriaEngineCore.

  ## Callbacks

  - `new_coordinator/0` - Create a new coordinator instance
  - `plan/4` - Generate a plan for achieving goals
  - `execute/4` - Execute a plan and return the final state

  ## Implementation Notes

  Implementations should handle errors gracefully and return standardized
  `{:ok, result}` or `{:error, reason}` tuples for consistent error handling.
  """

  @type coordinator :: any()
  @type domain :: any()
  @type state :: any()
  @type goals :: [any()]
  @type plan :: any()

  @doc """
  Create a new coordinator instance for planning operations.

  ## Returns

  - Coordinator instance that can be used for planning and execution

  ## Example

      coordinator = MyPlannerAdapter.new_coordinator()
  """
  @callback new_coordinator() :: coordinator()

  @doc """
  Generate a plan to achieve the specified goals.

  ## Parameters

  - `coordinator` - Coordinator instance from `new_coordinator/0`
  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, plan}` - Success with generated plan
  - `{:error, reason}` - Failure with error description

  ## Example

      case MyPlannerAdapter.plan(coordinator, domain, state, goals) do
        {:ok, plan} -> IO.puts("Planning successful")
        {:error, _reason} -> IO.puts("Planning failed")
      end
  """
  @callback plan(coordinator(), domain(), state(), goals()) :: {:ok, plan()} | {:error, atom()}

  @doc """
  Execute a plan and return the final state.

  ## Parameters

  - `coordinator` - Coordinator instance from `new_coordinator/0`
  - `domain` - Domain definition with actions and methods
  - `state` - Current world state
  - `plan` - Plan to execute (from `plan/4`)

  ## Returns

  - `{:ok, final_state}` - Success with final state after execution
  - `{:error, reason}` - Failure with error description

  ## Example

      case MyPlannerAdapter.execute(coordinator, domain, state, plan) do
        {:ok, final_state} -> IO.puts("Execution successful")
        {:error, _reason} -> IO.puts("Execution failed")
      end
  """
  @callback execute(coordinator(), domain(), state(), plan()) :: {:ok, state()} | {:error, atom()}
end
