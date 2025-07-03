# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSimpleTravel do
  @moduledoc """
  Simple Travel planning domain for AriaEngine.

  This module provides a travel planning domain where people can move between
  locations using different transportation methods (walking or taxi) with
  resource constraints (money for taxi fares).

  ## Example

      iex> state = AriaSimpleTravel.get_initial_state()
      iex> goals = [{"loc", "alice", "park"}]
      iex> {:ok, plan} = AriaSimpleTravel.plan(state, goals)
      iex> plan
      [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"}
      ]
  """

  alias AriaSimpleTravel.{Domain, Actions, Problem}

  @doc """
  Plan a sequence of actions to achieve the given goals.

  ## Parameters

  - `state` - Initial state of the world
  - `goals` - List of goals to achieve in format {predicate, args...}

  ## Returns

  - `{:ok, plan}` - List of actions to execute
  - `{:error, reason}` - Planning failed
  """
  def plan(state, goals) do
    Domain.plan(state, goals)
  end

  @doc """
  Get the initial state for the simple travel domain.

  ## Returns

  A state map with people, locations, distances, and initial conditions.
  """
  def get_initial_state do
    Problem.get_initial_state()
  end

  @doc """
  Get predefined example problems for testing and demonstration.

  ## Returns

  A map with example problem scenarios.
  """
  def get_example_problems do
    Problem.get_example_problems()
  end

  @doc """
  Validate that a plan is executable from the given state.

  ## Parameters

  - `state` - Initial state
  - `actions` - List of actions to validate

  ## Returns

  - `{:ok, final_state}` - Plan is valid
  - `{:error, reason}` - Plan validation failed
  """
  def validate_plan(state, actions) do
    Actions.validate_plan(state, actions)
  end

  @doc """
  Execute a single action and return the resulting state.

  ## Parameters

  - `state` - Current state
  - `action` - Action tuple to execute

  ## Returns

  - `{:ok, new_state}` - Action executed successfully
  - `{:error, reason}` - Action execution failed
  """
  def execute_action(state, action) do
    Actions.execute_action(state, action)
  end
end
