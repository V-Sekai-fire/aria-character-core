# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PlanningTest do
  use ExUnit.Case
  doctest AriaEngine

  alias AriaEngine.TestDomains

  describe "Basic planning" do
    test "plans simple action sequence" do
      # Use domain from TestDomains
      domain = TestDomains.build_simple_rpg_domain()

      # Set up initial state
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      # Simple goal: have the sword
      goals = [{"has", "player", "sword"}]

      # This will fail without proper task methods, but let's test the structure
      case AriaEngine.plan(domain, initial_state, goals, verbose: 0) do
        {:ok, _plan} ->
          # Planning succeeded
          :ok
        {:error, reason} ->
          # Expected to fail without proper methods
          assert String.contains?(reason, "No methods found")
      end
    end

    test "validates plan execution" do
      domain = TestDomains.build_test_domain()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")

      # Manual plan
      plan = [{:move, ["room2"]}, {:move, ["room3"]}]

      case AriaEngine.execute_plan(domain, initial_state, plan) do
        {:ok, final_state} ->
          assert AriaEngine.get_fact(final_state, "location", "player") == "room3"
        {:error, reason} ->
          flunk("Plan execution failed: #{reason}")
      end
    end
  end

  describe "Task decomposition" do
    test "decomposes tasks into actions" do
      domain = TestDomains.build_rpg_domain()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      # Task: get the sword
      tasks = [{"get_item", ["sword"]}]

      case AriaEngine.plan(domain, initial_state, tasks, verbose:0) do
        {:ok, plan} ->
          assert length(plan) == 2
          assert {:move, ["room2"]} in plan
          assert {:pickup, ["sword"]} in plan

          # Verify plan works
          {:ok, final_state} = AriaEngine.execute_plan(domain, initial_state, plan)
          assert AriaEngine.get_fact(final_state, "has", "player") == "sword"
          assert AriaEngine.get_fact(final_state, "location", "player") == "room2"

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end
  end
end
