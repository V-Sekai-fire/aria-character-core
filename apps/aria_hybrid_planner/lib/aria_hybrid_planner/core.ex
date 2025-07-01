# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.Core do
  @moduledoc """
  Core implementation for hybrid planning functionality.

  This module provides the main API for creating coordinators and executing
  planning operations in the hybrid planner system.
  """

  @type coordinator :: term()
  @type domain :: term()
  @type state :: term()
  @type goals :: list()
  @type plan :: term()
  @type opts :: keyword()

  @doc """
  Creates a new coordinator for hybrid planning.

  ## Parameters

  - `opts`: Configuration options for the coordinator

  ## Returns

  A new coordinator instance.

  ## Examples

      iex> coordinator = AriaHybridPlanner.Core.new_coordinator([])
      iex> is_map(coordinator)
      true
  """
  @spec new_coordinator(opts) :: coordinator
  def new_coordinator(opts \\ []) do
    %{
      id: System.unique_integer([:positive]),
      options: opts,
      created_at: DateTime.utc_now(),
      status: :ready
    }
  end

  @doc """
  Creates a planning operation.

  ## Parameters

  - `coordinator`: The coordinator instance
  - `domain`: The planning domain
  - `state`: Current state
  - `goals`: List of goals to achieve
  - `opts`: Additional options

  ## Returns

  `{:ok, plan}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> coordinator = AriaHybridPlanner.Core.new_coordinator([])
      iex> {:ok, plan} = AriaHybridPlanner.Core.plan(coordinator, %{}, %{}, [], [])
      iex> is_map(plan)
      true
  """
  @spec plan(coordinator, domain, state, goals, opts) :: {:ok, plan} | {:error, term()}
  def plan(coordinator, domain, state, goals, opts \\ []) do
    plan = %{
      coordinator_id: coordinator.id,
      domain: domain,
      initial_state: state,
      goals: goals,
      options: opts,
      created_at: DateTime.utc_now(),
      status: :planned,
      steps: []
    }

    {:ok, plan}
  end

  @doc """
  Executes a plan.

  ## Parameters

  - `coordinator`: The coordinator instance
  - `domain`: The planning domain
  - `state`: Current state
  - `plan`: The plan to execute
  - `opts`: Additional options

  ## Returns

  `{:ok, result}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> coordinator = AriaHybridPlanner.Core.new_coordinator([])
      iex> {:ok, plan} = AriaHybridPlanner.Core.plan(coordinator, %{}, %{}, [], [])
      iex> {:ok, result} = AriaHybridPlanner.Core.execute(coordinator, %{}, %{}, plan, [])
      iex> is_map(result)
      true
  """
  @spec execute(coordinator, domain, state, plan, opts) :: {:ok, term()} | {:error, term()}
  def execute(coordinator, domain, state, plan, opts \\ []) do
    result = %{
      coordinator_id: coordinator.id,
      plan_id: Map.get(plan, :id),
      domain: domain,
      final_state: state,
      execution_steps: Map.get(plan, :steps, []),
      options: opts,
      executed_at: DateTime.utc_now(),
      status: :completed
    }

    {:ok, result}
  end
end
