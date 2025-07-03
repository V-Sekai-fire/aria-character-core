# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSimpleTravel.Domain do
  @moduledoc """
  Main planning domain for Simple Travel.

  This module provides the top-level planning interface that integrates
  methods and actions to solve travel planning problems.
  """

  alias AriaSimpleTravel.{Actions, Methods}

  @doc """
  Plan a sequence of actions to achieve the given goals.

  Uses a simple goal decomposition approach:
  1. For each goal, find applicable methods
  2. Apply the first method that works
  3. Concatenate all action sequences

  ## Parameters

  - `state` - Initial state of the world
  - `goals` - List of goals in format {"predicate", arg1, arg2, ...}

  ## Returns

  - `{:ok, plan}` - List of actions to execute
  - `{:error, reason}` - Planning failed
  """
  def plan(state, goals) do
    plan_goals(state, goals, [])
  end

  defp plan_goals(_state, [], acc) do
    {:ok, acc}
  end

  defp plan_goals(state, [goal | rest], acc) do
    case solve_goal(state, goal) do
      {:ok, actions} ->
        # Execute actions to get new state for next goal
        case Actions.validate_plan(state, actions) do
          {:ok, new_state} ->
            plan_goals(new_state, rest, acc ++ actions)

          {:error, reason} ->
            {:error, "Invalid action sequence for goal #{inspect(goal)}: #{reason}"}
        end

      {:error, reason} ->
        {:error, "Cannot solve goal #{inspect(goal)}: #{reason}"}
    end
  end

  @doc """
  Solve a single goal by finding and applying an appropriate method.
  """
  def solve_goal(state, goal) do
    case goal do
      {"loc", person, location} ->
        Methods.solve_travel_goal(state, person, location)

      _ ->
        {:error, "Unknown goal type: #{inspect(goal)}"}
    end
  end

  @doc """
  Check if a goal is satisfied in the current state.
  """
  def goal_satisfied?(state, goal) do
    case goal do
      {"loc", person, location} ->
        state.loc[person] == location

      _ ->
        false
    end
  end

  @doc """
  Check if all goals are satisfied in the current state.
  """
  def all_goals_satisfied?(state, goals) do
    Enum.all?(goals, &goal_satisfied?(state, &1))
  end

  @doc """
  Get information about the domain for debugging and introspection.
  """
  def domain_info do
    %{
      name: "Simple Travel",
      description: "Travel planning with walking and taxi transportation",
      predicates: [
        {"loc", 2, "Location of person or taxi"}
      ],
      actions: [
        {"walk", 3, "Person walks from one location to another"},
        {"call_taxi", 2, "Person calls taxi to current location"},
        {"ride_taxi", 2, "Person rides taxi to destination"},
        {"pay_driver", 2, "Person pays taxi fare and exits"}
      ],
      methods: [
        {"do_nothing", "Person is already at destination"},
        {"travel_by_foot", "Person walks to destination (distance <= 2)"},
        {"travel_by_taxi", "Person takes taxi to destination"}
      ]
    }
  end
end
