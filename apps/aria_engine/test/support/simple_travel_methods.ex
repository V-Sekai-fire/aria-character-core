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
end
