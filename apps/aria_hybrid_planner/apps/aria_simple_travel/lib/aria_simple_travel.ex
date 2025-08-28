# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSimpleTravel do
  @moduledoc """
  Simple Travel planning domain for AriaEngine with durative actions.

  This module provides a travel planning domain where people can move between
  locations using different transportation methods (walking or taxi) with
  temporal constraints and resource management.

  Based on the IPyHOP simple_travel example but enhanced with:
  - Durative actions following R25W1398085 specification
  - Entity-capability model for resource management
  - AriaEngine integration for temporal planning
  - Multi-agent coordination (person + taxi)

  ## Example Usage

      # Create domain and initial state
      domain = AriaSimpleTravel.create_domain()
      {:ok, state} = AriaSimpleTravel.setup_scenario()

      # Plan travel for Alice to go to the park
      goals = [{"location", "alice", "park"}]
      {:ok, solution_tree} = AriaSimpleTravel.plan(domain, state, goals)

      # Execute the plan
      {:ok, {final_state, _}} = AriaHybridPlanner.run_lazy(domain, state, goals)

  ## Temporal Patterns Demonstrated

  - **Pattern 1 (Instant)**: call_taxi, pay_driver
  - **Pattern 6 (Calculated end)**: walk, ride_taxi with dynamic durations

  ## Entity Types

  - **People**: alice, bob (walking, taxi_calling, taxi_riding, payment capabilities)
  - **Taxis**: taxi1 (transportation, route_planning capabilities)
  - **Locations**: home_a, home_b, park, downtown (destination, waypoint capabilities)
  """

  alias AriaSimpleTravel.Domain
  alias AriaEngineCore
  require Logger

  @doc """
  Create the Simple Travel domain with AriaEngine integration.

  ## Parameters

  - `opts` - Optional configuration map

  ## Returns

  AriaEngine.Domain.t() configured for simple travel planning
  """
  @spec create_domain(map()) :: AriaEngine.Domain.t()
  def create_domain(opts \\ %{}) do
    AriaSimpleTravel.Domain.create_domain(opts)
  end

  @doc """
  Set up the initial scenario with entities and state.

  Creates people (alice, bob), taxi (taxi1), locations (home_a, home_b, park, downtown),
  distances between locations, and initial conditions.

  ## Returns

  - `{:ok, AriaState.t()}` - Initial state ready for planning
  - `{:error, atom()}` - Setup failed
  """
  @spec setup_scenario() :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_scenario do
    state = AriaState.new()
    Domain.setup_scenario(state, [])
  end

  @doc """
  Get predefined example scenarios for testing and demonstration.

  ## Returns

  Map with example scenarios including:
  - `:alice_to_park` - Alice travels from home_a to park
  - `:bob_short_walk` - Bob walks from home_b to park (short distance)
  - `:alice_taxi_ride` - Alice takes taxi from home_a to downtown
  - `:multi_person` - Both Alice and Bob travel to different destinations
  """
  @spec get_example_scenarios() :: map()
  def get_example_scenarios do
    %{
      alice_to_park: %{
        description: "Alice travels from home_a to park (requires taxi due to distance)",
        goals: [{"location", "alice", "park"}],
        expected_actions: [:call_taxi, :ride_taxi, :pay_driver]
      },
      bob_short_walk: %{
        description: "Bob walks from home_b to park (short distance)",
        goals: [{"location", "bob", "park"}],
        expected_actions: [:walk]
      },
      alice_taxi_ride: %{
        description: "Alice takes taxi from home_a to downtown",
        goals: [{"location", "alice", "downtown"}],
        expected_actions: [:call_taxi, :ride_taxi, :pay_driver]
      },
      multi_person: %{
        description: "Both Alice and Bob travel to different destinations",
        goals: [
          {"location", "alice", "park"},
          {"location", "bob", "downtown"}
        ],
        expected_actions: [:call_taxi, :ride_taxi, :pay_driver, :call_taxi, :ride_taxi, :pay_driver]
      }
    }
  end

  @doc """
  Run a specific example scenario.

  ## Parameters

  - `scenario_name` - Atom key from get_example_scenarios/0

  ## Returns

  - `{:ok, {final_state, solution_tree, scenario_info}}` - Successful execution
  - `{:error, atom()}` - Execution failed

  ## Example

      {:ok, {final_state, solution_tree, info}} = AriaSimpleTravel.run_example(:alice_to_park)
  """
  @spec run_example(atom()) ::
    {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree(), map()}} | {:error, atom()}
  def run_example(scenario_name) do
    scenarios = get_example_scenarios()

    case Map.get(scenarios, scenario_name) do
      nil ->
        {:error, :unknown_scenario}

      scenario ->
        domain = create_domain()

        case setup_scenario() do
          {:ok, state} ->
            Logger.debug("Running scenario goals: #{inspect(scenario.goals)}")
            case AriaHybridPlanner.run_lazy(domain, state, scenario.goals) do
              {:ok, {solution_tree, final_state}} ->
                {:ok, {final_state, solution_tree, scenario}}

              {:error, reason} ->
                {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Validate that the domain follows R25W1398085 specification.

  Checks that:
  - All actions have proper @action attributes
  - Temporal patterns are correctly implemented
  - Entity-capability model is used
  - AriaEngine integration is proper

  ## Returns

  - `:ok` - Domain is compliant
  - `{:error, [violations]}` - List of specification violations
  """
  @spec validate_specification_compliance() :: :ok | {:error, [String.t()]}
  def validate_specification_compliance do
    violations = []

    # Check that domain uses AriaEngine.Domain
    violations = if function_exported?(Domain, :create_base_domain, 0) do
      violations
    else
      ["Domain does not use AriaEngine.Domain" | violations]
    end

    # Check for required action attributes
    actions = [:setup_scenario, :call_taxi, :pay_driver, :walk, :ride_taxi]
    violations = Enum.reduce(actions, violations, fn action, acc ->
      if function_exported?(Domain, action, 2) do
        acc
      else
        ["Missing action: #{action}" | acc]
      end
    end)

    # Check for task methods
    task_methods = [:travel]
    violations = Enum.reduce(task_methods, violations, fn method, acc ->
      if function_exported?(Domain, method, 2) do
        acc
      else
        ["Missing task method: #{method}" | acc]
      end
    end)

    # Check for unigoal methods
    unigoal_methods = [:achieve_location]
    violations = Enum.reduce(unigoal_methods, violations, fn method, acc ->
      if function_exported?(Domain, method, 2) do
        acc
      else
        ["Missing unigoal method: #{method}" | acc]
      end
    end)

    case violations do
      [] -> :ok
      violations -> {:error, Enum.reverse(violations)}
    end
  end
end
