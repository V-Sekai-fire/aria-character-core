# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SimpleTravelActions do
  @moduledoc """
  Actions for the Simple Travel domain.

  Ported from GTPyhop's simple_htn.py example.
  This implements actions for walking, calling taxis, riding taxis, and paying drivers.
  """

  alias AriaEngine.State

  @doc """
  Walk from one location to another.

  Preconditions:
  - p is a person
  - x and y are locations
  - x != y
  - person p is currently at location x

  Effects:
  - person p is now at location y
  """
  def walk(state, [p, x, y]) do
    cond do
      not is_person(p) -> false
      not is_location(x) -> false
      not is_location(y) -> false
      x == y -> false
      State.get_object(state, "loc", p) != x -> false
      true ->
        State.set_object(state, "loc", p, y)
    end
  end

  @doc """
  Call a taxi to the current location.

  Preconditions:
  - p is a person
  - x is a location

  Effects:
  - taxi1 moves to location x
  - person p is now in taxi1
  """
  def call_taxi(state, [p, x]) do
    cond do
      not is_person(p) -> false
      not is_location(x) -> false
      true ->
        state
        |> State.set_object("loc", "taxi1", x)
        |> State.set_object("loc", p, "taxi1")
    end
  end

  @doc """
  Ride a taxi to a destination.

  Preconditions:
  - p is a person
  - p is currently in a taxi
  - y is a location
  - taxi is not already at y

  Effects:
  - taxi moves to location y
  - person p owes the taxi fare
  """
  def ride_taxi(state, [p, y]) do
    person_loc = State.get_object(state, "loc", p)

    cond do
      not is_person(p) -> false
      not is_taxi(person_loc) -> false
      not is_location(y) -> false
      true ->
        taxi = person_loc
        x = State.get_object(state, "loc", taxi)

        cond do
          not is_location(x) -> false
          x == y -> false
          true ->
            fare = taxi_rate(distance(x, y))
            state
            |> State.set_object("loc", taxi, y)
            |> State.set_object("owe", p, fare)
        end
    end
  end

  @doc """
  Pay the taxi driver and exit the taxi.

  Preconditions:
  - p is a person
  - person has enough cash to pay what they owe

  Effects:
  - person's cash is reduced by amount owed
  - person no longer owes anything
  - person exits taxi to location y
  """
  def pay_driver(state, [p, y]) do
    cash = State.get_object(state, "cash", p)
    owe = State.get_object(state, "owe", p)

    cond do
      not is_person(p) -> false
      cash < owe -> false
      true ->
        state
        |> State.set_object("cash", p, cash - owe)
        |> State.set_object("owe", p, 0)
        |> State.set_object("loc", p, y)
    end
  end

  # Helper functions

  defp is_person(p) do
    p in ["alice", "bob"]
  end

  defp is_location(loc) do
    loc in ["home_a", "home_b", "park", "station"]
  end

  defp is_taxi(taxi) do
    taxi in ["taxi1", "taxi2"]
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
  Simple ride taxi action for Pyhop compatibility.
  """
  def ride_taxi_simple(state, [p, taxi, y]) do
    cond do
      not is_person(p) -> false
      not is_taxi(taxi) -> false
      not is_location(y) -> false
      State.get_object(state, "loc", p) != State.get_object(state, "loc", taxi) -> false
      true ->
        state
        |> State.set_object("loc", p, y)
        |> State.set_object("loc", taxi, y)
    end
  end

  @doc """
  Simple pay driver action for Pyhop compatibility.
  """
  def pay_driver_simple(state, [p, taxi]) do
    cond do
      not is_person(p) -> false
      not is_taxi(taxi) -> false
      true ->
        # For simple version, just deduct a fixed amount
        cash = State.get_object(state, "cash", p)
        fare = 5  # Fixed fare for simplicity
        if cash >= fare do
          State.set_object(state, "cash", p, cash - fare)
        else
          false
        end
    end
  end
end
