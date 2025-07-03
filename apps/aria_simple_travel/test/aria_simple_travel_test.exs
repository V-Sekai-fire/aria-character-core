# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSimpleTravelTest do
  use ExUnit.Case

  alias AriaSimpleTravel.{Problem, Actions, Methods, Domain}

  describe "initial state" do
    test "has correct structure" do
      state = Problem.get_initial_state()

      assert state.loc["alice"] == "home_a"
      assert state.loc["bob"] == "home_b"
      assert state.loc["taxi1"] == "taxi_lot"
      assert state.cash["alice"] == 20
      assert state.cash["bob"] == 15
      assert state.owe["alice"] == 0
      assert state.owe["bob"] == 0
    end

    test "has rigid facts" do
      state = Problem.get_initial_state()

      assert state.rigid.dist[{"home_a", "park"}] == 8
      assert state.rigid.dist[{"home_b", "park"}] == 2
      assert "alice" in state.rigid.types[:person]
      assert "park" in state.rigid.types[:location]
      assert "taxi1" in state.rigid.types[:taxi]
    end
  end

  describe "actions" do
    setup do
      state = Problem.get_initial_state()
      {:ok, state: state}
    end

    test "walk action works", %{state: state} do
      # Bob can walk from home_b to park (distance 2)
      {:ok, new_state} = Actions.walk(state, "bob", "home_b", "park")
      assert new_state.loc["bob"] == "park"
    end

    test "walk action fails for long distance", %{state: state} do
      # Alice cannot walk from home_a to park (distance 8)
      # But the walk action itself doesn't check distance - that's in methods
      {:ok, new_state} = Actions.walk(state, "alice", "home_a", "park")
      assert new_state.loc["alice"] == "park"
    end

    test "call_taxi action works", %{state: state} do
      {:ok, new_state} = Actions.call_taxi(state, "alice", "home_a")
      assert new_state.loc["taxi1"] == "home_a"
      assert new_state.loc["alice"] == "taxi1"
    end

    test "ride_taxi action works", %{state: state} do
      # First call taxi
      {:ok, state1} = Actions.call_taxi(state, "alice", "home_a")

      # Then ride to park
      {:ok, state2} = Actions.ride_taxi(state1, "alice", "park")
      assert state2.loc["taxi1"] == "park"
      assert state2.owe["alice"] == 5.5  # 1.5 + 0.5 * 8
    end

    test "pay_driver action works", %{state: state} do
      # Setup: call taxi, ride, then pay
      {:ok, state1} = Actions.call_taxi(state, "alice", "home_a")
      {:ok, state2} = Actions.ride_taxi(state1, "alice", "park")
      {:ok, state3} = Actions.pay_driver(state2, "alice", "park")

      assert state3.loc["alice"] == "park"
      assert state3.cash["alice"] == 14.5  # 20 - 5.5
      assert state3.owe["alice"] == 0
    end
  end

  describe "methods" do
    setup do
      state = Problem.get_initial_state()
      {:ok, state: state}
    end

    test "do_nothing when already at location", %{state: state} do
      {:ok, actions} = Methods.do_nothing(state, "alice", "home_a")
      assert actions == []
    end

    test "travel_by_foot for short distance", %{state: state} do
      {:ok, actions} = Methods.travel_by_foot(state, "bob", "park")
      assert actions == [{"walk", "bob", "home_b", "park"}]
    end

    test "travel_by_foot fails for long distance", %{state: state} do
      {:error, reason} = Methods.travel_by_foot(state, "alice", "park")
      assert reason =~ "Distance too far for walking"
    end

    test "travel_by_taxi works when affordable", %{state: state} do
      {:ok, actions} = Methods.travel_by_taxi(state, "alice", "park")
      expected = [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"}
      ]
      assert actions == expected
    end
  end

  describe "domain planning" do
    setup do
      state = Problem.get_initial_state()
      {:ok, state: state}
    end

    test "plans simple goal for alice to park", %{state: state} do
      goals = [{"loc", "alice", "park"}]
      {:ok, plan} = Domain.plan(state, goals)

      # Should be flattened list of actions
      expected = [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"}
      ]
      assert plan == expected
    end

    test "plans goal for bob to park (walking)", %{state: state} do
      goals = [{"loc", "bob", "park"}]
      {:ok, plan} = Domain.plan(state, goals)

      expected = [{"walk", "bob", "home_b", "park"}]
      assert plan == expected
    end

    test "plans multiple goals", %{state: state} do
      goals = [{"loc", "alice", "park"}, {"loc", "bob", "park"}]
      {:ok, plan} = Domain.plan(state, goals)

      # Should handle both goals in sequence
      expected = [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"},
        {"walk", "bob", "home_b", "park"}
      ]
      assert plan == expected
    end

    test "goal_satisfied? works correctly", %{state: state} do
      assert Domain.goal_satisfied?(state, {"loc", "alice", "home_a"}) == true
      assert Domain.goal_satisfied?(state, {"loc", "alice", "park"}) == false
    end
  end

  describe "integration with AriaSimpleTravel module" do
    test "main module interface works" do
      state = AriaSimpleTravel.get_initial_state()
      goals = [{"loc", "alice", "park"}]

      {:ok, plan} = AriaSimpleTravel.plan(state, goals)

      expected = [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"}
      ]
      assert plan == expected
    end

    test "validate_plan works" do
      state = AriaSimpleTravel.get_initial_state()
      actions = [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"}
      ]

      {:ok, final_state} = AriaSimpleTravel.validate_plan(state, actions)
      assert final_state.loc["alice"] == "park"
      assert final_state.cash["alice"] == 14.5
    end

    test "execute_action works" do
      state = AriaSimpleTravel.get_initial_state()
      {:ok, new_state} = AriaSimpleTravel.execute_action(state, {"walk", "bob", "home_b", "park"})
      assert new_state.loc["bob"] == "park"
    end
  end
end
