# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSimpleTravel.Actions do
  @moduledoc """
  Action implementations for the Simple Travel domain.

  This module provides the primitive actions that can be executed
  in the travel planning domain: walk, call_taxi, ride_taxi, pay_driver.
  """

  @doc """
  Calculate taxi fare based on distance.

  Formula: 1.5 + 0.5 * distance
  """
  def taxi_rate(distance) do
    1.5 + 0.5 * distance
  end

  @doc """
  Get distance between two locations from the state.
  """
  def distance(state, x, y) do
    state.rigid.dist[{x, y}] || state.rigid.dist[{y, x}]
  end

  @doc """
  Check if a variable is of a specific type.
  """
  def is_a(state, var, type) do
    var in state.rigid.types[type]
  end

  @doc """
  Walk action: person walks from one location to another.

  Preconditions:
  - p is a person
  - x and y are locations
  - x != y
  - person is currently at location x

  Effects:
  - person's location changes to y
  """
  def walk(state, p, x, y) do
    cond do
      not is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      not is_a(state, x, :location) ->
        {:error, "#{x} is not a location"}

      not is_a(state, y, :location) ->
        {:error, "#{y} is not a location"}

      x == y ->
        {:error, "Cannot walk from #{x} to itself"}

      state.loc[p] != x ->
        {:error, "#{p} is not at #{x}"}

      true ->
        new_state = put_in(state.loc[p], y)
        {:ok, new_state}
    end
  end

  @doc """
  Call taxi action: person calls a taxi to their current location.

  Preconditions:
  - p is a person
  - x is a location

  Effects:
  - taxi1 location changes to x
  - person's location changes to taxi1 (they get in)
  """
  def call_taxi(state, p, x) do
    cond do
      not is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      not is_a(state, x, :location) ->
        {:error, "#{x} is not a location"}

      true ->
        new_state = state
        |> put_in([:loc, "taxi1"], x)
        |> put_in([:loc, p], "taxi1")
        {:ok, new_state}
    end
  end

  @doc """
  Ride taxi action: person rides taxi to destination.

  Preconditions:
  - p is a person
  - p is in a taxi
  - y is a location
  - taxi is at a location (not another taxi)
  - destination is different from current location

  Effects:
  - taxi location changes to y
  - person owes taxi fare based on distance
  """
  def ride_taxi(state, p, y) do
    cond do
      not is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      not is_a(state, y, :location) ->
        {:error, "#{y} is not a location"}

      not is_a(state, state.loc[p], :taxi) ->
        {:error, "#{p} is not in a taxi"}

      true ->
        taxi = state.loc[p]
        x = state.loc[taxi]

        cond do
          not is_a(state, x, :location) ->
            {:error, "Taxi is not at a valid location"}

          x == y ->
            {:error, "Already at destination #{y}"}

          true ->
            dist = distance(state, x, y)
            if dist == nil do
              {:error, "No route from #{x} to #{y}"}
            else
              fare = taxi_rate(dist)
              new_state = state
              |> put_in([:loc, taxi], y)
              |> put_in([:owe, p], fare)
              {:ok, new_state}
            end
        end
    end
  end

  @doc """
  Pay driver action: person pays taxi fare and exits taxi.

  Preconditions:
  - p is a person
  - person has enough cash to pay what they owe

  Effects:
  - person's cash decreases by amount owed
  - person's debt becomes 0
  - person's location changes to y (exits taxi)
  """
  def pay_driver(state, p, y) do
    cond do
      not is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      state.cash[p] < state.owe[p] ->
        {:error, "#{p} doesn't have enough cash (has #{state.cash[p]}, owes #{state.owe[p]})"}

      true ->
        new_cash = state.cash[p] - state.owe[p]
        new_state = state
        |> put_in([:cash, p], new_cash)
        |> put_in([:owe, p], 0)
        |> put_in([:loc, p], y)
        {:ok, new_state}
    end
  end

  @doc """
  Execute a single action and return the resulting state.
  """
  def execute_action(state, action) do
    case action do
      {"walk", p, x, y} ->
        walk(state, p, x, y)

      {"call_taxi", p, x} ->
        call_taxi(state, p, x)

      {"ride_taxi", p, y} ->
        ride_taxi(state, p, y)

      {"pay_driver", p, y} ->
        pay_driver(state, p, y)

      _ ->
        {:error, "Unknown action: #{inspect(action)}"}
    end
  end

  @doc """
  Validate that a plan (sequence of actions) is executable from the given state.
  """
  def validate_plan(state, actions) do
    validate_plan_recursive(state, actions)
  end

  defp validate_plan_recursive(state, []) do
    {:ok, state}
  end

  defp validate_plan_recursive(state, [action | rest]) do
    case execute_action(state, action) do
      {:ok, new_state} ->
        validate_plan_recursive(new_state, rest)

      {:error, reason} ->
        {:error, "Action #{inspect(action)} failed: #{reason}"}
    end
  end
end
