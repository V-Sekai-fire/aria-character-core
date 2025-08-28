# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSimpleTravel.Methods do
  @moduledoc """
  Planning methods for the Simple Travel domain.

  This module provides the goal methods that decompose travel goals
  into sequences of primitive actions.
  """

  alias AriaSimpleTravel.Actions

  @doc """
  Do nothing method: person is already at the desired location.

  Preconditions:
  - p is a person
  - y is a location
  - person is already at location y

  Returns:
  - Empty action list (no actions needed)
  """
  def do_nothing(state, p, y) do
    cond do
      not Actions.is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      not Actions.is_a(state, y, :location) ->
        {:error, "#{y} is not a location"}

      state.loc[p] == y ->
        {:ok, []}

      true ->
        {:error, "#{p} is not at #{y}"}
    end
  end

  @doc """
  Travel by foot method: person walks to destination.

  Preconditions:
  - p is a person
  - y is a location
  - person is not already at y
  - distance from current location to y is <= 2

  Returns:
  - Single walk action
  """
  def travel_by_foot(state, p, y) do
    cond do
      not Actions.is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      not Actions.is_a(state, y, :location) ->
        {:error, "#{y} is not a location"}

      state.loc[p] == y ->
        {:error, "#{p} is already at #{y}"}

      true ->
        x = state.loc[p]
        dist = Actions.distance(state, x, y)

        if dist != nil and dist <= 2 do
          {:ok, [{"walk", p, x, y}]}
        else
          {:error, "Distance too far for walking (#{dist})"}
        end
    end
  end

  @doc """
  Travel by taxi method: person takes taxi to destination.

  Preconditions:
  - p is a person
  - y is a location
  - person is not already at y
  - person has enough cash to pay taxi fare

  Returns:
  - Sequence of taxi actions: call_taxi, ride_taxi, pay_driver
  """
  def travel_by_taxi(state, p, y) do
    cond do
      not Actions.is_a(state, p, :person) ->
        {:error, "#{p} is not a person"}

      not Actions.is_a(state, y, :location) ->
        {:error, "#{y} is not a location"}

      state.loc[p] == y ->
        {:error, "#{p} is already at #{y}"}

      true ->
        x = state.loc[p]
        dist = Actions.distance(state, x, y)

        if dist == nil do
          {:error, "No route from #{x} to #{y}"}
        else
          fare = Actions.taxi_rate(dist)

          if state.cash[p] >= fare do
            {:ok, [
              {"call_taxi", p, x},
              {"ride_taxi", p, y},
              {"pay_driver", p, y}
            ]}
          else
            {:error, "Not enough cash for taxi (has #{state.cash[p]}, needs #{fare})"}
          end
        end
    end
  end

  @doc """
  Get all applicable methods for achieving a location goal.

  Returns methods in order of preference:
  1. do_nothing (if already there)
  2. travel_by_foot (if distance <= 2)
  3. travel_by_taxi (if can afford it)
  """
  def get_travel_methods(state, person, location) do
    methods = [
      {:do_nothing, &do_nothing/3},
      {:travel_by_foot, &travel_by_foot/3},
      {:travel_by_taxi, &travel_by_taxi/3}
    ]

    for {name, method} <- methods,
        {:ok, actions} <- [method.(state, person, location)] do
      {name, actions}
    end
  end

  @doc """
  Apply the first applicable method for a travel goal.

  Tries methods in preference order and returns the first one that works.
  """
  def solve_travel_goal(state, person, location) do
    case get_travel_methods(state, person, location) do
      [] ->
        {:error, "No applicable methods for #{person} to reach #{location}"}

      [{_method_name, actions} | _rest] ->
        {:ok, actions}
    end
  end
end
