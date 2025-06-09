# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SimpleTravelMethods do
  @moduledoc """
  Methods for the Simple Travel domain.

  Ported from GTPyhop's simple_htn.py example.
  This implements task methods and unigoal methods for travel planning.
  """

  alias AriaEngine.State

  # Task Methods

  @doc """
  Do nothing if already at destination.
  """
  def do_nothing(state, ["travel", p, y]) do
    x = State.get_object(state, "loc", p)

    cond do
      not is_person(p) -> nil
      not is_location(y) -> nil
      x == y -> []
      true -> nil
    end
  end

  @doc """
  Travel by foot if destination is close enough.
  """
  def travel_by_foot(state, ["travel", p, y]) do
    x = State.get_object(state, "loc", p)

    cond do
      not is_person(p) -> nil
      not is_location(y) -> nil
      x == y -> nil
      distance(x, y) <= 2 -> [{"walk", p, x, y}]
      true -> nil
    end
  end

  @doc """
  Travel by taxi if person has enough money.
  """
  def travel_by_taxi(state, ["travel", p, y]) do
    x = State.get_object(state, "loc", p)
    cash = State.get_object(state, "cash", p)
    fare = taxi_rate(distance(x, y))

    cond do
      not is_person(p) -> nil
      not is_location(y) -> nil
      x == y -> nil
      cash < fare -> nil
      true -> [
        {"call_taxi", p, x},
        {"ride_taxi", p, y},
        {"pay_driver", p, y}
      ]
    end
  end

  # Unigoal Methods

  @doc """
  Method to achieve the goal that person p is at location y.
  """
  def loc_unigoal(state, {"loc", p, y}) do
    current_loc = State.get_object(state, "loc", p)

    cond do
      current_loc == y -> []  # Already there
      true -> [["travel", p, y]]  # Need to travel
    end
  end

  # Helper functions

  defp is_person(p) do
    p in ["alice", "bob"]
  end

  defp is_location(loc) do
    loc in ["home_a", "home_b", "park", "station"]
  end

  defp taxi_rate(dist) do
    # In this domain, the taxi fares are quite low :-)
    1.5 + 0.5 * dist
  end

  defp distance(x, y) do
    # Distance lookup table
    distances = %{
      {"home_a", "park"} => 8,
      {"home_b", "park"} => 2,
      {"station", "home_a"} => 1,
      {"station", "home_b"} => 7,
      {"home_a", "home_b"} => 7,
      {"station", "park"} => 9
    }

    distances[{x, y}] || distances[{y, x}] || 0
  end

  # Simple versions for Pyhop compatibility

  @doc """
  Simple travel by foot method for Pyhop compatibility.
  """
  def travel_by_foot_simple(state, ["travel", p, y]) do
    x = State.get_object(state, "loc", p)

    cond do
      not is_person(p) -> false
      not is_location(y) -> false
      x == y -> false
      distance(x, y) <= 2 -> [{"walk", p, x, y}]
      true -> false
    end
  end

  @doc """
  Simple travel by taxi method for Pyhop compatibility.
  """
  def travel_by_taxi_simple(state, ["travel", p, y]) do
    x = State.get_object(state, "loc", p)
    cash = State.get_object(state, "cash", p)
    fare = taxi_rate(distance(x, y))

    cond do
      not is_person(p) -> false
      not is_location(y) -> false
      x == y -> false
      cash < fare -> false
      true ->
        # Find an available taxi
        taxi = find_available_taxi(state, x)
        if taxi do
          [
            {"call_taxi", p, taxi},
            {"ride_taxi", p, taxi, y},
            {"pay_driver", p, taxi}
          ]
        else
          false
        end
    end
  end

  defp find_available_taxi(state, location) do
    taxis = ["taxi1", "taxi2"]
    Enum.find(taxis, fn taxi ->
      State.get_object(state, "loc", taxi) == location
    end) || Enum.at(taxis, 0)  # Default to first taxi if none at location
  end
end
