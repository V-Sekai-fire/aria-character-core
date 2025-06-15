# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SimpleHtnActingErrorTest do
  @moduledoc """
  Test implementation showing acting errors in HTN planning.

  This example demonstrates how unexpected problems at execution time can
  cause failures if methods are too brittle. Ported from GTPyhop's
  simple_htn_acting_error.py example.
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

  # Actions (these model ideal conditions)
  defp walk_action(state, [person, from, to]) do
    if is_a(person, "person") and is_a(from, "location") and is_a(to, "location") and from != to do
      current_loc = State.get_object(state, "loc", person)
      if current_loc == from do
        State.set_object(state, "loc", person, to)
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
      |> State.set_object("loc", "taxi1", location)
      |> State.set_object("loc", person, "taxi1")
    else
      false
    end
  end

  defp ride_taxi_action(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      person_loc = State.get_object(state, "loc", person)

      if is_a(person_loc, "taxi") do
        taxi = person_loc
        current_loc = State.get_object(state, "loc", taxi)

        if is_a(current_loc, "location") and current_loc != destination do
          dist = distance(current_loc, destination)
          fare = taxi_rate(dist)

          state
          |> State.set_object("loc", taxi, destination)
          |> State.set_object("owe", person, fare)
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
      cash = State.get_object(state, "cash", person) || 0
      owe = State.get_object(state, "owe", person) || 0

      if cash >= owe do
        state
        |> State.set_object("cash", person, cash - owe)
        |> State.set_object("owe", person, 0)
        |> State.set_object("loc", person, location)
      else
        false
      end
    else
      false
    end
  end

  # Command versions that include error handling (simulating real-world execution)
  defp walk_command(state, [person, from, to]) do
    # This version is the same as the action
    walk_action(state, [person, from, to])
  end

  defp call_taxi_command(state, [person, location]) do
    if is_a(person, "person") and is_a(location, "location") do
      # Simulate random taxi selection (can be taxi1 or taxi2)
      taxi = if :rand.uniform() > 0.5, do: "taxi1", else: "taxi2"

      state
      |> State.set_object("loc", taxi, location)
      |> State.set_object("loc", person, taxi)
    else
      false
    end
  end

  defp ride_taxi_command(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      person_loc = State.get_object(state, "loc", person)

      if is_a(person_loc, "taxi") do
        taxi = person_loc
        current_loc = State.get_object(state, "loc", taxi)
        taxi_condition = State.get_object(state, "taxi_condition", taxi) || "good"

        if is_a(current_loc, "location") and current_loc != destination do
          # Check if taxi is in good condition
          if taxi_condition == "good" do
            dist = distance(current_loc, destination)
            fare = taxi_rate(dist)

            state
            |> State.set_object("loc", taxi, destination)
            |> State.set_object("owe", person, fare)
          else
            # Taxi broke down - this is where the error occurs in execution
            false
          end
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

  defp pay_driver_command(state, [person, location]) do
    # This version is the same as the action
    pay_driver_action(state, [person, location])
  end

  # Task methods
  defp do_nothing(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      current_loc = State.get_object(state, "loc", person)
      if current_loc == destination do
        []  # No actions needed
      else
        false
      end
    else
      false
    end
  end

  defp travel_by_foot(state, [person, destination]) do
    if is_a(person, "person") and is_a(destination, "location") do
      current_loc = State.get_object(state, "loc", person)

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
      current_loc = State.get_object(state, "loc", person)
      cash = State.get_object(state, "cash", person) || 0

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

  describe "Simple HTN Acting Error domain" do
    setup do
      action_domain = TestDomains.build_simple_htn_acting_error_actions_domain()
      command_domain = TestDomains.build_simple_htn_acting_error_commands_domain()
      good_state = TestDomains.create_good_taxi_state()
      bad_state = TestDomains.create_bad_taxi_state()
      {:ok, action_domain: action_domain, command_domain: command_domain,
            good_state: good_state, bad_state: bad_state}
    end

    test "domain creates correctly", %{action_domain: domain} do
      summary = AriaEngine.domain_summary(domain)
      assert summary.name == "simple_htn_acting_error_actions"
      assert :walk in summary.actions
      assert :call_taxi in summary.actions
      assert :ride_taxi in summary.actions
      assert :pay_driver in summary.actions
      assert "travel" in summary.task_methods
    end

    test "planning works with good taxis", %{action_domain: domain, good_state: state} do
      tasks = [{"travel", ["alice", "park"]}]

      case AriaEngine.plan(domain, state, tasks) do
        {:ok, plan} ->
          # Should use taxi since distance is 8 (> 2)
          assert length(plan) == 3
          assert {:call_taxi, ["alice", "home_a"]} in plan
          assert {:ride_taxi, ["alice", "park"]} in plan
          assert {:pay_driver, ["alice", "park"]} in plan

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "execution works with good taxis", %{command_domain: domain, good_state: state} do
      tasks = [{"travel", ["alice", "park"]}]

      case AriaEngine.plan(domain, state, tasks) do
        {:ok, plan} ->
          # Execute with good taxis should work
          case AriaEngine.execute_plan(domain, state, plan) do
            {:ok, final_state} ->
              assert State.get_object(final_state, "loc", "alice") == "park"

            {:error, reason} ->
              flunk("Execution failed: #{reason}")
          end

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "execution fails with bad taxis", %{action_domain: plan_domain, command_domain: exec_domain, bad_state: state} do
      tasks = [{"travel", ["alice", "park"]}]

      # Plan using action domain (assumes good conditions)
      case AriaEngine.plan(plan_domain, state, tasks) do
        {:ok, plan} ->
          # Execute with command domain (has bad taxis) should fail
          case AriaEngine.execute_plan(exec_domain, state, plan) do
            {:ok, _final_state} ->
              flunk("Execution should have failed due to bad taxi")

            {:error, _reason} ->
              # Expected to fail due to taxi breakdown
              :ok
          end

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "travel by foot works even with bad taxis", %{command_domain: domain, bad_state: state} do
      tasks = [{"travel", ["bob", "park"]}]

      case AriaEngine.plan(domain, state, tasks) do
        {:ok, plan} ->
          # Should use walking since distance is 2 (== walking limit)
          assert length(plan) == 1
          assert {:walk, ["bob", "home_b", "park"]} in plan

          # Execute should work even with bad taxis since we're walking
          case AriaEngine.execute_plan(domain, state, plan) do
            {:ok, final_state} ->
              assert State.get_object(final_state, "loc", "bob") == "park"

            {:error, reason} ->
              flunk("Execution failed: #{reason}")
          end

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "do nothing method works", %{action_domain: domain, good_state: state} do
      # Alice is already at home_a
      tasks = [{"travel", ["alice", "home_a"]}]

      case AriaEngine.plan(domain, state, tasks) do
        {:ok, plan} ->
          # Should be empty plan since alice is already at home_a
          assert plan == []

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "actions work correctly", %{action_domain: domain, good_state: state} do
      # Test individual action execution

      # Test walk action
      result = Domain.execute_action(domain, state, :walk, ["alice", "home_a", "home_b"])
      assert result != false
      assert State.get_object(result, "loc", "alice") == "home_b"

      # Test call_taxi action
      result = Domain.execute_action(domain, state, :call_taxi, ["alice", "home_a"])
      assert result != false
      assert State.get_object(result, "loc", "taxi1") == "home_a"
      assert State.get_object(result, "loc", "alice") == "taxi1"

      # Test ride_taxi action
      taxi_state = Domain.execute_action(domain, state, :call_taxi, ["alice", "home_a"])
      result = Domain.execute_action(domain, taxi_state, :ride_taxi, ["alice", "park"])
      assert result != false
      assert State.get_object(result, "loc", "taxi1") == "park"
      assert State.get_object(result, "owe", "alice") == taxi_rate(distance("home_a", "park"))
    end

    test "commands differ from actions", %{command_domain: domain, bad_state: state} do
      # Test that command version fails with bad taxi
      taxi_state = Domain.execute_action(domain, state, :call_taxi, ["alice", "home_a"])

      # This should fail because taxi is in bad condition
      result = Domain.execute_action(domain, taxi_state, :ride_taxi, ["alice", "park"])
      assert result == false
    end
  end

  describe "Error handling scenarios" do
    test "demonstrates the brittleness problem" do
      # This test shows how planning can succeed but execution can fail
      # when the real world doesn't match the planning assumptions

      action_domain = TestDomains.build_simple_htn_acting_error_actions_domain()
      command_domain = TestDomains.build_simple_htn_acting_error_commands_domain()
      bad_state = TestDomains.create_bad_taxi_state()

      # 1. Plan assumes good conditions
      tasks = [{"travel", ["alice", "park"]}]
      {:ok, plan} = AriaEngine.plan(action_domain, bad_state, tasks)

      # 2. Plan looks good
      assert length(plan) == 3

      # 3. But execution fails because taxis are actually broken
      {:error, _reason} = AriaEngine.execute_plan(command_domain, bad_state, plan)

      # This demonstrates the need for robust planning/acting integration
      assert true
    end
  end
end
