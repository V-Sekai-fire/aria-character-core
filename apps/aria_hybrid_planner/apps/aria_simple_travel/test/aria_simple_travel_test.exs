# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSimpleTravelTest do
  use ExUnit.Case, async: true
  doctest AriaSimpleTravel
  require Logger

  alias AriaSimpleTravel
  alias AriaSimpleTravel.Domain

  describe "domain creation and setup" do
    test "sets up scenario with entities and initial state" do
      {:ok, state} = AriaSimpleTravel.setup_scenario()

      # Check people are registered
      assert AriaState.get_fact(state, "type", "alice") == "person"
      assert AriaState.get_fact(state, "type", "bob") == "person"
      assert AriaState.get_fact(state, "cash", "alice") == 20.0
      assert AriaState.get_fact(state, "cash", "bob") == 15.0

      # Check taxi is registered
      assert AriaState.get_fact(state, "type", "taxi1") == "taxi"
      assert AriaState.get_fact(state, "status", "taxi1") == "available"

      # Check locations are registered
      assert AriaState.get_fact(state, "type", "home_a") == "location"
      assert AriaState.get_fact(state, "type", "park") == "location"

      # Check initial positions
      assert AriaState.get_fact(state, "location", "alice") == "home_a"
      assert AriaState.get_fact(state, "location", "bob") == "home_b"
      assert AriaState.get_fact(state, "location", "taxi1") == "downtown"

      # Check distances are set up
      assert AriaState.get_fact(state, "distance", {"home_a", "park"}) == 8
      assert AriaState.get_fact(state, "distance", {"home_b", "park"}) == 2
    end
  end

  describe "instant actions" do
    setup do
      domain = AriaSimpleTravel.create_domain()
      {:ok, state} = AriaSimpleTravel.setup_scenario()
      {:ok, domain: domain, state: state}
    end

    test "call_taxi brings taxi to person and places person inside", %{state: state} do
      {:ok, new_state} = Domain.call_taxi(state, ["alice", "taxi1"])

      # Taxi should be at alice's location
      assert AriaState.get_fact(new_state, "location", "taxi1") == "home_a"
      # Alice should be in the taxi
      assert AriaState.get_fact(new_state, "location", "alice") == "taxi1"
    end

    test "pay_driver processes payment and exits taxi", %{state: state} do
      # Set up: Alice owes money and is at park
      state = state
      |> AriaState.set_fact("owe", "alice", 5.0)
      |> AriaState.set_fact("location", "alice", "taxi1")

      {:ok, new_state} = Domain.pay_driver(state, ["alice", "park"])

      # Alice should have less cash
      assert AriaState.get_fact(new_state, "cash", "alice") == 15.0
      # Alice should owe nothing
      assert AriaState.get_fact(new_state, "owe", "alice") == 0
      # Alice should be at park
      assert AriaState.get_fact(new_state, "location", "alice") == "park"
    end

    test "pay_driver fails with insufficient funds", %{state: state} do
      # Set up: Alice owes more than she has
      state = state
      |> AriaState.set_fact("owe", "alice", 25.0)
      |> AriaState.set_fact("location", "alice", "taxi1")

      assert {:error, :insufficient_funds} = Domain.pay_driver(state, ["alice", "park"])
    end
  end

  describe "durative actions" do
    setup do
      domain = AriaSimpleTravel.create_domain()
      {:ok, state} = AriaSimpleTravel.setup_scenario()
      {:ok, domain: domain, state: state}
    end

    test "walk_step changes person location", %{state: state} do
      {:ok, new_state} = Domain.walk_step(state, ["alice", "home_a", "park"])

      assert AriaState.get_fact(new_state, "location", "alice") == "park"
    end

    test "walk_step fails when from equals to", %{state: state} do
      assert {:error, :same_location} = Domain.walk_step(state, ["alice", "home_a", "home_a"])
    end

    test "walk returns decomposed walk_step actions", %{state: state} do
      {:ok, actions} = Domain.walk(state, ["alice", "home_a", "park"])

      # Distance from home_a to park is 8, so should get 8 walk_step actions
      assert length(actions) == 8
      assert Enum.all?(actions, fn action -> match?({:walk_step, ["alice", "home_a", "park"]}, action) end)
    end

    test "walk fails when from equals to", %{state: state} do
      assert {:error, :same_location} = Domain.walk(state, ["alice", "home_a", "home_a"])
    end

    test "ride_step moves taxi and charges fare", %{state: state} do
      # Set up: Alice is in taxi at home_a
      state = state
      |> AriaState.set_fact("location", "taxi1", "home_a")
      |> AriaState.set_fact("location", "alice", "taxi1")

      {:ok, new_state} = Domain.ride_step(state, ["alice", "park"])

      # Taxi should be at park
      assert AriaState.get_fact(new_state, "location", "taxi1") == "park"
      # Alice should owe fare (1.5 + 0.5 * 8 = 5.5)
      assert AriaState.get_fact(new_state, "owe", "alice") == 5.5
    end

    test "ride_taxi returns decomposed ride_step actions", %{state: state} do
      # Set up: Alice is in taxi at home_a
      state = state
      |> AriaState.set_fact("location", "taxi1", "home_a")
      |> AriaState.set_fact("location", "alice", "taxi1")

      {:ok, actions} = Domain.ride_taxi(state, ["alice", "park"])

      # Distance from home_a to park is 8, so should get 8 ride_step actions
      assert length(actions) == 8
      assert Enum.all?(actions, fn action -> match?({:ride_step, ["alice", "park"]}, action) end)
    end

    test "ride_taxi fails when person not in taxi", %{state: state} do
      assert {:error, :not_in_taxi} = Domain.ride_taxi(state, ["alice", "park"])
    end
  end

  describe "task methods" do
    setup do
      domain = AriaSimpleTravel.create_domain()
      {:ok, state} = AriaSimpleTravel.setup_scenario()
      {:ok, domain: domain, state: state}
    end

    test "travel chooses walking for short distances", %{state: state} do
      # Bob at home_b, park is 2 units away (walkable)
      {:ok, todos} = Domain.travel(state, ["bob", "park"])

      # Should get 2 walk_step actions for distance=2
      expected = [
        {:walk_step, ["bob", "home_b", "park"]},
        {:walk_step, ["bob", "home_b", "park"]}
      ]
      assert todos == expected
    end

    test "travel chooses taxi for long distances", %{state: state} do
      # Alice at home_a, park is 8 units away (requires taxi)
      {:ok, todos} = Domain.travel(state, ["alice", "park"])

      # Should get call_taxi, 8 ride_step actions, and pay_driver
      expected = [
        {:call_taxi, ["alice", "taxi1"]}
      ] ++ List.duplicate({:ride_step, ["alice", "park"]}, 8) ++ [
        {:pay_driver, ["alice", "park"]}
      ]
      assert todos == expected
    end

    test "travel returns empty list when already at destination", %{state: state} do
      {:ok, todos} = Domain.travel(state, ["alice", "home_a"])

      assert todos == []
    end

    test "travel fails when no viable transportation", %{state: state} do
      # Set Alice's cash to 0, so she can't afford taxi for long distance
      state = AriaState.set_fact(state, "cash", "alice", 0)

      assert {:error, :no_viable_transportation} = Domain.travel(state, ["alice", "park"])
    end
  end

  describe "unigoal methods" do
    setup do
      domain = AriaSimpleTravel.create_domain()
      {:ok, state} = AriaSimpleTravel.setup_scenario()
      {:ok, domain: domain, state: state}
    end

    test "achieve_location delegates to travel task", %{state: state} do
      {:ok, todos} = Domain.achieve_location(state, {"alice", "park"})

      assert todos == [{:travel, ["alice", "park"]}]
    end
  end

  describe "planning integration" do
    setup do
      domain = AriaSimpleTravel.create_domain()
      {:ok, state} = AriaSimpleTravel.setup_scenario()
      {:ok, domain: domain, state: state}
    end

    test "plans simple walking scenario", %{domain: domain, state: state} do
      goals = [{"location", "bob", "park"}]

      {:ok, _solution_tree} = AriaHybridPlanner.plan(domain, state, goals)
    end

    test "plans taxi scenario", %{domain: domain, state: state} do
      goals = [{"location", "alice", "park"}]

      {:ok, _solution_tree} = AriaHybridPlanner.plan(domain, state, goals)
    end

    test "executes plan with run_lazy", %{domain: domain, state: state} do
      goals = [{"location", "bob", "park"}]

      {:ok, {_solution_tree, final_state}} = AriaHybridPlanner.run_lazy(domain, state, goals)

      # Bob should be at park
      assert AriaState.get_fact(final_state, "location", "bob") == "park"
    end

    test "executes pre-made solution tree", %{domain: domain, state: state} do
      goals = [{"location", "bob", "park"}]
      {:ok, plan_result} = AriaHybridPlanner.plan(domain, state, goals)

      # Extract the solution tree from the plan result
      solution_tree = plan_result.solution_tree

      {:ok, {_, final_state}} = AriaHybridPlanner.run_lazy_tree(domain, state, solution_tree)

      # Bob should be at park
      assert AriaState.get_fact(final_state, "location", "bob") == "park"
    end
  end

  describe "example scenarios" do
    test "gets example scenarios" do
      scenarios = AriaSimpleTravel.get_example_scenarios()

      assert Map.has_key?(scenarios, :alice_to_park)
      assert Map.has_key?(scenarios, :bob_short_walk)
      assert Map.has_key?(scenarios, :alice_taxi_ride)
      assert Map.has_key?(scenarios, :multi_person)

      alice_scenario = scenarios.alice_to_park
      assert alice_scenario.goals == [{"location", "alice", "park"}]
      assert alice_scenario.expected_actions == [:call_taxi, :ride_taxi, :pay_driver]
    end

    test "runs alice_to_park example" do
      {:ok, {final_state, solution_tree, scenario}} = AriaSimpleTravel.run_example(:alice_to_park)
      # Alice should be at park
      assert AriaState.get_fact(final_state, "location", "alice") == "park"
      # Alice should have less cash (paid taxi fare)
      assert AriaState.get_fact(final_state, "cash", "alice") < 20.0
      # Alice should owe nothing
      assert AriaState.get_fact(final_state, "owe", "alice") == 0
      assert scenario.description =~ "Alice travels from home_a to park"
      Logger.debug("Solution tree: #{inspect(AriaEngineCore.Plan.get_primitive_actions_dfs(solution_tree))}")
    end

    test "runs bob_short_walk example" do
      {:ok, {final_state, _plan, scenario}} = AriaSimpleTravel.run_example(:bob_short_walk)
      # Bob should be at park
      assert AriaState.get_fact(final_state, "location", "bob") == "park"
      # Bob should still have same cash (walking is free)
      assert AriaState.get_fact(final_state, "cash", "bob") == 15.0
      assert scenario.description =~ "Bob walks from home_b to park"
    end

    test "runs multi_person example" do
      {:ok, {final_state, _solution_tree, scenario}} = AriaSimpleTravel.run_example(:multi_person)
      # Both people should reach their destinations
      assert AriaState.get_fact(final_state, "location", "alice") == "park"
      assert AriaState.get_fact(final_state, "location", "bob") == "downtown"
      assert scenario.description =~ "Both Alice and Bob travel"
    end

    test "fails for unknown scenario" do
      assert {:error, :unknown_scenario} = AriaSimpleTravel.run_example(:nonexistent)
    end
  end

  describe "helper functions" do
    setup do
      {:ok, state} = AriaSimpleTravel.setup_scenario()
      {:ok, state: state}
    end

    test "distance calculation works correctly", %{state: state} do
      # Test symmetric distance lookup
      assert AriaState.get_fact(state, "distance", {"home_a", "park"}) == 8
      assert AriaState.get_fact(state, "distance", {"park", "home_a"}) == 8
      assert AriaState.get_fact(state, "distance", {"home_b", "park"}) == 2
    end

    test "taxi fare calculation", %{state: state} do
      # Set up taxi scenario
      state = state
      |> AriaState.set_fact("location", "taxi1", "home_a")
      |> AriaState.set_fact("location", "alice", "taxi1")

      {:ok, new_state} = Domain.ride_step(state, ["alice", "park"])

      # Fare should be 1.5 + 0.5 * 8 = 5.5
      assert AriaState.get_fact(new_state, "owe", "alice") == 5.5
    end

    test "entity type checking", %{state: state} do
      # Check entity types are properly set
      assert AriaState.get_fact(state, "type", "alice") == "person"
      assert AriaState.get_fact(state, "type", "taxi1") == "taxi"
      assert AriaState.get_fact(state, "type", "park") == "location"
    end

    test "capability checking", %{state: state} do
      # Check capabilities are properly set
      alice_caps = AriaState.get_fact(state, "capabilities", "alice")
      assert :walking in alice_caps
      assert :taxi_calling in alice_caps
      assert :taxi_riding in alice_caps
      assert :payment in alice_caps

      taxi_caps = AriaState.get_fact(state, "capabilities", "taxi1")
      assert :transportation in taxi_caps
      assert :route_planning in taxi_caps
    end
  end
end
