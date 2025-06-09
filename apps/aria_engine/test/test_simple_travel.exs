# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SimpleTravelTest do
  use ExUnit.Case

  import AriaEngine
  alias AriaEngine.{State, TestDomains}

  @moduletag timeout: 120_000

  describe "Simple Travel domain" do
    test "domain creation and basic functionality" do
      domain = TestDomains.build_simple_travel_domain()
      summary = AriaEngine.domain_summary(domain)

      assert summary.name == "simple_travel"
      assert :walk in summary.actions
      assert :call_taxi in summary.actions
      assert :ride_taxi in summary.actions
      assert :pay_driver in summary.actions
      assert "travel" in summary.task_methods
      assert "loc" in summary.unigoal_methods
    end

    test "walk action works correctly" do
      domain = TestDomains.build_simple_travel_domain()

      # Alice starts at home_a
      state = TestDomains.create_simple_travel_state()
      assert get_fact(state, "loc", "alice") == "home_a"

      # Alice walks to station (distance <= 2)
      new_state = AriaEngine.Domain.execute_action(domain, state, :walk, ["alice", "home_a", "station"])
      assert get_fact(new_state, "loc", "alice") == "station"
    end

    test "taxi sequence works correctly" do
      domain = TestDomains.build_simple_travel_domain()
      state = TestDomains.create_simple_travel_state()

      # Call taxi
      state = AriaEngine.Domain.execute_action(domain, state, :call_taxi, ["alice", "home_a"])
      assert get_fact(state, "loc", "taxi1") == "home_a"
      assert get_fact(state, "loc", "alice") == "taxi1"

      # Ride taxi to park
      state = AriaEngine.Domain.execute_action(domain, state, :ride_taxi, ["alice", "park"])
      assert get_fact(state, "loc", "taxi1") == "park"
      assert get_fact(state, "owe", "alice") == 5.5  # 1.5 + 0.5 * 8

      # Pay driver and exit
      state = AriaEngine.Domain.execute_action(domain, state, :pay_driver, ["alice", "park"])
      assert get_fact(state, "loc", "alice") == "park"
      assert get_fact(state, "cash", "alice") == 14.5  # 20 - 5.5
      assert get_fact(state, "owe", "alice") == 0
    end

    test "planning alice to park by taxi" do
      domain = TestDomains.build_simple_travel_domain()
      state = TestDomains.create_simple_travel_state()
      goals = [["travel", "alice", "park"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          expected = [
            {"call_taxi", "alice", "home_a"},
            {"ride_taxi", "alice", "park"},
            {"pay_driver", "alice", "park"}
          ]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "planning bob to park by walking" do
      domain = TestDomains.build_simple_travel_domain()
      state = TestDomains.create_simple_travel_state()
      goals = [["travel", "bob", "park"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          expected = [{"walk", "bob", "home_b", "park"}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "planning with unigoals" do
      domain = TestDomains.build_simple_travel_domain()
      state = TestDomains.create_simple_travel_state()
      goals = [{"loc", "alice", "park"}]  # Unigoal format

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          # Should produce a plan to get Alice to the park
          assert length(plan) > 0

        {:error, reason} ->
          flunk("Planning with unigoals failed: #{reason}")
      end
    end

    test "multiple travelers" do
      domain = TestDomains.build_simple_travel_domain()
      state = TestDomains.create_simple_travel_state()
      goals = [["travel", "alice", "park"], ["travel", "bob", "park"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          # Should produce a plan for both Alice and Bob
          assert length(plan) > 0

        {:error, reason} ->
          flunk("Multi-traveler planning failed: #{reason}")
      end
    end
  end
end
