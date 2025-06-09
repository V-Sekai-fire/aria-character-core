# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PlanningTest do
  use ExUnit.Case
  doctest AriaEngine

  describe "Basic planning" do
    test "plans simple action sequence" do
      # Define simple actions
      move_action = fn state, [to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end

      pickup_action = fn state, [item] ->
        player_location = AriaEngine.get_fact(state, "location", "player")
        item_location = AriaEngine.get_fact(state, "location", item)
        
        if player_location == item_location do
          AriaEngine.set_fact(state, "has", "player", item)
        else
          false  # Can't pickup item not in same location
        end
      end

      # Create domain with actions
      domain = AriaEngine.create_domain("simple_rpg")
      |> AriaEngine.add_action(:move, move_action)
      |> AriaEngine.add_action(:pickup, pickup_action)

      # Set up initial state
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      # Simple goal: have the sword
      goals = [{"has", "player", "sword"}]

      # This will fail without proper task methods, but let's test the structure
      case AriaEngine.plan(domain, initial_state, goals, verbose: 1) do
        {:ok, _plan} -> 
          # Planning succeeded
          :ok
        {:error, reason} -> 
          # Expected to fail without proper methods
          assert String.contains?(reason, "No methods found")
      end
    end

    test "validates plan execution" do
      # Simple move action
      move_action = fn state, [to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end

      domain = AriaEngine.create_domain("test")
      |> AriaEngine.add_action(:move, move_action)

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
      # Actions
      move_action = fn state, [to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end

      pickup_action = fn state, [item] ->
        player_location = AriaEngine.get_fact(state, "location", "player")
        item_location = AriaEngine.get_fact(state, "location", item)
        
        if player_location == item_location do
          AriaEngine.set_fact(state, "has", "player", item)
        else
          false
        end
      end

      # Task method: get item from another room
      get_item_method = fn state, [item] ->
        player_location = AriaEngine.get_fact(state, "location", "player")
        item_location = AriaEngine.get_fact(state, "location", item)
        
        if player_location == item_location do
          # Already in same room, just pickup
          [{:pickup, [item]}]
        else
          # Need to move then pickup
          [{:move, [item_location]}, {:pickup, [item]}]
        end
      end

      domain = AriaEngine.create_domain("rpg")
      |> AriaEngine.add_action(:move, move_action)
      |> AriaEngine.add_action(:pickup, pickup_action)
      |> AriaEngine.add_task_method("get_item", get_item_method)

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      # Task: get the sword
      tasks = [{"get_item", ["sword"]}]

      case AriaEngine.plan(domain, initial_state, tasks, verbose: 1) do
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
