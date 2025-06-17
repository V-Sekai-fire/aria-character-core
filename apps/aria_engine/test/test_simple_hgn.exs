# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SimpleHgnTest do
  @moduledoc """
  Test implementation of Simple HGN (goal-oriented travel) domain.

  This is the goal-oriented version of the simple travel domain,
  ported from GTPyhop's simple_hgn.py example.
  """

  use ExUnit.Case
  doctest AriaEngine

  alias AriaEngine.{Domain, State, TestDomains}

  # Rigid relations (constants in the domain)
  @types %{
    "person" => ["alice", "bob"],
    "location" => ["home_a", "home_b", "park", "station"],
    "taxi" => ["taxi1", "taxi2"]
  }

  @distances %{
    {"home_a", "park"} => 8,
    {"home_b", "park"} => 2,
    {"station", "home_a"} => 1,
    {"station", "home_b"} => 7,
    {"home_a", "home_b"} => 7,
    {"station", "park"} => 9
  }

  # Helper functions
  defp taxi_rate(dist), do: 1.5 + 0.5 * dist

  defp distance(x, y) do
    @distances[{x, y}] || @distances[{y, x}] || 0
  end

  defp is_a(variable, type) do
    case @types[type] do
      nil -> false
      list -> variable in list
    end
  end

  # Actions
  defp walk_action(state, [person, from, to]) do
    if is_a(person, "person") and is_a(from, "location") and is_a(to, "location") and from != to do
      current_loc = StateV2.get_fact(state, "loc", person)
      if current_loc == from do
        StateV2.set_fact(state, "loc", person, to)
      else
        false
      end
    else
      false
    end
  end

  defp call_taxi_action(state, [person, location]) do
    if is_a(person, "person") and is_a(location, "location") do
      state
      |> StateV2.set_fact("loc", "taxi1", location)
      |> StateV2.set_fact("loc", person, "taxi1")
    else
      false
    end
  end

  defp ride_taxi_action(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      person_loc = StateV2.get_fact(state, "loc", person)

      if is_a(person_loc, "taxi") do
        taxi = person_loc
        current_loc = StateV2.get_fact(state, "loc", taxi)

        if is_a(current_loc, "location") and current_loc != destination do
          dist = distance(current_loc, destination)
          fare = taxi_rate(dist)

          state
          |> StateV2.set_fact("loc", taxi, destination)
          |> StateV2.set_fact("owe", person, fare)
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  defp pay_driver_action(state, [person, location]) do
    if is_a(person, "person") do
      cash = StateV2.get_fact(state, "cash", person) || 0
      owe = StateV2.get_fact(state, "owe", person) || 0

      if cash >= owe do
        state
        |> StateV2.set_fact("cash", person, cash - owe)
        |> StateV2.set_fact("owe", person, 0)
        |> StateV2.set_fact("loc", person, location)
      else
        false
      end
    else
      false
    end
  end

  # Unigoal methods for 'loc' goal
  defp travel_by_foot(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      current_loc = StateV2.get_fact(state, "loc", person)

      if current_loc != destination and distance(current_loc, destination) <= 2 do
        [{:walk, [person, current_loc, destination]}]
      else
        false
      end
    else
      false
    end
  end

  defp travel_by_taxi(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      current_loc = StateV2.get_fact(state, "loc", person)
      cash = StateV2.get_fact(state, "cash", person) || 0

      if current_loc != destination do
        dist = distance(current_loc, destination)
        fare = taxi_rate(dist)

        if cash >= fare do
          [
            {:call_taxi, [person, current_loc]},
            {:ride_taxi, [person, destination]},
            {:pay_driver, [person, destination]}
          ]
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  describe "Simple HGN domain" do
    setup do
      domain = TestDomains.build_simple_hgn_domain()
      state = TestDomains.create_simple_hgn_state()
      {:ok, domain: domain, state: state}
    end

    test "domain creates correctly", %{domain: domain} do
      summary = AriaEngine.domain_summary(domain)
      assert summary.name == "simple_hgn"
      assert :walk in summary.actions
      assert :call_taxi in summary.actions
      assert :ride_taxi in summary.actions
      assert :pay_driver in summary.actions
      assert "loc" in summary.unigoal_methods
    end

    test "actions work correctly", %{domain: domain, state: state} do
      # Test walk action
      result = Domain.execute_action(domain, state, :walk, ["alice", "home_a", "home_b"])
      assert result != false
      assert StateV2.get_fact(result, "alice", "loc") == "home_b"

      # Walking to same location should fail
      result = Domain.execute_action(domain, state, :walk, ["alice", "home_a", "home_a"])
      assert result == false

      # Test call_taxi action
      result = Domain.execute_action(domain, state, :call_taxi, ["alice", "home_a"])
      assert result != false
      assert StateV2.get_fact(result, "taxi1", "loc") == "home_a"
      assert StateV2.get_fact(result, "alice", "loc") == "taxi1"

      # Test ride_taxi action (after calling taxi)
      taxi_state = Domain.execute_action(domain, state, :call_taxi, ["alice", "home_a"])
      result = Domain.execute_action(domain, taxi_state, :ride_taxi, ["alice", "park"])
      assert result != false
      assert StateV2.get_fact(result, "taxi1", "loc") == "park"
      assert StateV2.get_fact(result, "alice", "owe") == taxi_rate(distance("home_a", "park"))

      # Test pay_driver action
      result = Domain.execute_action(domain, result, :pay_driver, ["alice", "park"])
      assert result != false
      assert StateV2.get_fact(result, "alice", "loc") == "park"
      assert StateV2.get_fact(result, "alice", "owe") == 0
      expected_cash = 20 - taxi_rate(distance("home_a", "park"))
      assert StateV2.get_fact(result, "alice", "cash") == expected_cash
    end

    test "goal planning: alice to park (by taxi)", %{domain: domain, state: state} do
      goals = [{"loc", "alice", "park"}]

      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should use taxi since distance is 8 (> 2)
          assert length(plan) == 3
          assert {:call_taxi, ["alice", "home_a"]} in plan
          assert {:ride_taxi, ["alice", "park"]} in plan
          assert {:pay_driver, ["alice", "park"]} in plan

          # Verify plan execution
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert StateV2.get_fact(final_state, "alice", "loc") == "park"
          assert StateV2.get_fact(final_state, "alice", "owe") == 0

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "goal planning: bob to park (by foot)", %{domain: domain, state: state} do
      goals = [{"loc", "bob", "park"}]

      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should walk since distance is 2 (== walking limit)
          assert length(plan) == 1
          assert {:walk, ["bob", "home_b", "park"]} in plan

          # Verify plan execution
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert StateV2.get_fact(final_state, "bob", "loc") == "park"

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "goal planning: multiple goals", %{domain: domain, state: state} do
      goals = [{"loc", "alice", "park"}, {"loc", "bob", "park"}]

      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should contain actions for both alice and bob
          assert length(plan) >= 4  # At least 3 for alice + 1 for bob

          # Verify plan execution
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert StateV2.get_fact(final_state, "alice", "loc") == "park"
          assert StateV2.get_fact(final_state, "bob", "loc") == "park"

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "goal planning: no action needed", %{domain: domain, state: state} do
      # Alice is already at home_a
      goals = [{"loc", "alice", "home_a"}]

      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should be empty plan since goal is already satisfied
          assert plan == []

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "planning fails when insufficient cash", %{domain: domain, state: state} do
      # Give alice very little cash
      poor_state = StateV2.set_fact(state, "cash", "alice", "1")

      # Try to get alice to park (needs taxi due to distance, but can't afford it)
      goals = [{"loc", "alice", "park"}]

      case AriaEngine.plan(domain, poor_state, goals) do
        {:ok, _plan} ->
          flunk("Planning should have failed due to insufficient cash")

        {:error, _reason} ->
          # Expected to fail
          :ok
      end
    end
  end

  describe "Helper functions" do
    test "distance calculation" do
      assert distance("home_a", "park") == 8
      assert distance("park", "home_a") == 8  # Symmetric
      assert distance("home_b", "park") == 2
      assert distance("station", "home_a") == 1
    end

    test "taxi rate calculation" do
      assert taxi_rate(8) == 5.5
      assert taxi_rate(2) == 2.5
      assert taxi_rate(1) == 2.0
    end

    test "type checking" do
      assert is_a("alice", "person")
      assert is_a("bob", "person")
      assert not is_a("taxi1", "person")

      assert is_a("home_a", "location")
      assert is_a("park", "location")
      assert not is_a("alice", "location")

      assert is_a("taxi1", "taxi")
      assert is_a("taxi2", "taxi")
      assert not is_a("alice", "taxi")
    end
  end
end
