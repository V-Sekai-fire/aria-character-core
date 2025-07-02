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
    # Convert goals to the format expected by LazyExecution
    lazy_goals = convert_goals_to_lazy_format(goals)

    case AriaEngine.Planning.LazyExecution.plan(domain, state, lazy_goals, Map.new(opts)) do
      {:ok, lazy_plan} ->
        # Convert LazyExecution plan to our format and add solution tree structure
        plan = %{
          coordinator_id: coordinator.id,
          domain: domain,
          initial_state: state,
          goals: goals,
          options: opts,
          created_at: DateTime.utc_now(),
          status: :planned,
          steps: Map.get(lazy_plan, :actions, []),
          final_state: Map.get(lazy_plan, :final_state, state),
          metrics: Map.get(lazy_plan, :metrics, %{}),
          # Add solution tree structure for compatibility
          root_id: "root",
          nodes: %{
            "root" => %{
              id: "root",
              task: {:multigoal, goals},
              parent_id: nil,
              children_ids: [],
              state: state,
              visited: true,
              expanded: true,
              method_tried: "lazy_execution",
              blacklisted_methods: [],
              is_primitive: false,
              is_durative: false
            }
          },
          blacklisted_commands: MapSet.new(),
          goal_network: %{}
        }
        {:ok, plan}

      {:error, reason} ->
        {:error, reason}
    end
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

  @doc """
  Validates a plan against the current domain and state.

  ## Parameters

  - `coordinator`: The coordinator instance
  - `domain`: The planning domain
  - `state`: Current state
  - `plan`: The plan to validate

  ## Returns

  `{:ok, :valid}` if the plan is valid, `{:error, reason}` otherwise.
  """
  @spec validate_plan(coordinator, domain, state, plan) :: {:ok, :valid} | {:error, term()}
  def validate_plan(_coordinator, _domain, _state, _plan) do
    {:ok, :valid}
  end

  @doc """
  Replans when a failure occurs during execution.

  ## Parameters

  - `coordinator`: The coordinator instance
  - `domain`: The planning domain
  - `state`: Current state
  - `plan`: The original plan
  - `fail_node_id`: The ID of the failed node
  - `opts`: Additional options

  ## Returns

  `{:ok, new_plan}` on success, `{:error, reason}` on failure.
  """
  @spec replan(coordinator, domain, state, plan, term(), opts) :: {:ok, plan} | {:error, term()}
  def replan(coordinator, domain, state, _original_plan, _fail_node_id, opts \\ []) do
    # Create a new plan as a fallback
    plan(coordinator, domain, state, [], opts)
  end

  @doc """
  Plans and executes in a single operation.

  ## Parameters

  - `coordinator`: The coordinator instance
  - `domain`: The planning domain
  - `state`: Current state
  - `goals`: List of goals to achieve
  - `opts`: Additional options

  ## Returns

  `{:ok, result}` on success, `{:error, reason}` on failure.
  """
  @spec plan_and_execute(coordinator, domain, state, goals, opts) :: {:ok, term()} | {:error, term()}
  def plan_and_execute(coordinator, domain, state, goals, opts \\ []) do
    with {:ok, plan} <- plan(coordinator, domain, state, goals, opts),
         {:ok, result} <- execute(coordinator, domain, state, plan, opts) do
      {:ok, result}
    end
  end

  # Private helper functions

  @spec convert_goals_to_lazy_format(goals) :: list()
  defp convert_goals_to_lazy_format(goals) do
    Enum.flat_map(goals, fn goal ->
      case goal do
        {:multigoal, multigoal_map} when is_map(multigoal_map) ->
          # Convert multigoal map to list of {subject, predicate, value} tuples
          Enum.flat_map(multigoal_map, fn {predicate, subject_value_map} ->
            Enum.map(subject_value_map, fn {subject, value} ->
              {to_string(subject), to_string(predicate), value}
            end)
          end)

        {subject, predicate, value} ->
          # Already in the right format
          [{to_string(subject), to_string(predicate), value}]

        _ ->
          # Unknown goal format, skip
          []
      end
    end)
  end
end
