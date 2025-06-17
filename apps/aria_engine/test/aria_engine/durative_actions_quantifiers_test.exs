# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DurativeActionsQuantifiersTest do
  @moduledoc """
  Integration tests for durative actions with quantifier support.
  
  Tests verify that durative actions can use existential and universal quantifiers
  in their preconditions, enabling more sophisticated NPC reasoning patterns.
  """
  
  use ExUnit.Case, async: true
  alias AriaEngine.State
  alias AriaEngine.Domain.{Core, DurativeAction, Actions}

  describe "durative actions with existential quantifiers" do
    test "NPC can find any available seating" do
      # Create domain with seating-finding action
      domain = Core.new("seating_domain")
      
      # Define a durative action that requires ANY chair to be available
      find_seating_action = %DurativeAction{
        name: :find_seating,
        duration: {:fixed, 5000},  # 5 seconds
        conditions: %{
          at_start: [
            # Existential condition: any chair must be available
            {:exists, "status", "available", &String.contains?(&1, "chair")}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"activity", "npc", "sitting"}
          ]
        },
        action_fn: fn state, _args ->
          # Find the first available chair
          available_chairs = State.get_subjects_with_fact(state, "status", "available")
          |> Enum.filter(&String.contains?(&1, "chair"))
          
          case available_chairs do
            [chair | _] ->
              state
              |> State.set_fact("activity", "npc", "sitting")
              |> State.set_fact("status", chair, "occupied")
              |> State.set_fact("location", "npc", chair)
            [] ->
              false  # Should not happen due to precondition
          end
        end
      }
      
      domain = Core.add_durative_action(domain, :find_seating, find_seating_action)

      # Test scenario 1: Chairs available
      state_with_chairs = State.new()
      |> State.set_fact("type", "chair1", "furniture")
      |> State.set_fact("type", "chair2", "furniture")
      |> State.set_fact("type", "table1", "furniture")
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "chair2", "occupied")
      |> State.set_fact("status", "table1", "available")
      |> State.set_fact("activity", "npc", "standing")

      # Action should succeed because chair1 is available
      result = Actions.execute_action(domain, state_with_chairs, :find_seating, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "activity", "npc") == "sitting"
      assert State.get_fact(new_state, "status", "chair1") == "occupied"

      # Test scenario 2: No chairs available
      state_no_chairs = State.new()
      |> State.set_fact("type", "table1", "furniture")
      |> State.set_fact("type", "table2", "furniture")
      |> State.set_fact("status", "table1", "available")
      |> State.set_fact("status", "table2", "available")

      # Action should fail because no chairs exist
      result = Actions.execute_action(domain, state_no_chairs, :find_seating, [])
      assert result == false
    end

    test "NPC can craft when any required material is available" do
      domain = Core.new("crafting_domain")
      
      # Simple crafting action that requires ANY wood to be available
      craft_simple_action = %DurativeAction{
        name: :craft_simple,
        duration: {:fixed, 5000},  # 5 seconds
        conditions: %{
          at_start: [
            # Simple existential: any wood is available
            {:exists, "status", "available", &String.contains?(&1, "wood")}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [{"inventory", "npc", "item"}]
        },
        action_fn: fn state, _args ->
          State.set_fact(state, "inventory", "npc", "item")
        end
      }
      
      domain = Core.add_durative_action(domain, :craft_simple, craft_simple_action)
      
      state_simple = State.new()
      |> State.set_fact("status", "wood1", "available")
      |> State.set_fact("status", "iron1", "unavailable")

      result = Actions.execute_action(domain, state_simple, :craft_simple, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "inventory", "npc") == "item"
    end
  end

  describe "durative actions with universal quantifiers" do
    test "security NPC can verify all doors are locked" do
      domain = Core.new("security_domain")
      
      # Security patrol action that requires ALL doors to be locked
      security_patrol_action = %DurativeAction{
        name: :security_patrol,
        duration: {:fixed, 30000},  # 30 seconds
        conditions: %{
          at_start: [
            # Universal condition: all doors must be locked
            {:forall, "status", "locked", &String.contains?(&1, "door")}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"activity", "security_npc", "patrol_complete"},
            {"security_status", "building", "secure"}
          ]
        },
        action_fn: fn state, _args ->
          state
          |> State.set_fact("activity", "security_npc", "patrol_complete")
          |> State.set_fact("security_status", "building", "secure")
        end
      }
      
      domain = Core.add_durative_action(domain, :security_patrol, security_patrol_action)

      # Test scenario 1: All doors locked (should succeed)
      secure_state = State.new()
      |> State.set_fact("type", "door1", "entrance")
      |> State.set_fact("type", "door2", "entrance")
      |> State.set_fact("type", "door3", "entrance")
      |> State.set_fact("type", "window1", "opening")
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "locked")
      |> State.set_fact("status", "door3", "locked")
      |> State.set_fact("status", "window1", "closed")

      result = Actions.execute_action(domain, secure_state, :security_patrol, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "security_status", "building") == "secure"

      # Test scenario 2: One door unlocked (should fail)
      insecure_state = State.new()
      |> State.set_fact("type", "door1", "entrance")
      |> State.set_fact("type", "door2", "entrance")
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "unlocked")  # This breaks the universal condition

      result = Actions.execute_action(domain, insecure_state, :security_patrol, [])
      assert result == false

      # Test scenario 3: No doors exist (vacuous truth, should succeed)
      no_doors_state = State.new()
      |> State.set_fact("type", "window1", "opening")
      |> State.set_fact("status", "window1", "closed")

      result = Actions.execute_action(domain, no_doors_state, :security_patrol, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "security_status", "building") == "secure"
    end

    test "maintenance NPC can verify all equipment is operational" do
      domain = Core.new("maintenance_domain")
      
      # Maintenance check that requires all equipment to be operational
      maintenance_check_action = %DurativeAction{
        name: :maintenance_check,
        duration: {:fixed, 15000},  # 15 seconds
        conditions: %{
          at_start: [
            # All equipment must be operational
            {:forall, "status", "operational", &String.contains?(&1, "equipment")}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"maintenance_status", "facility", "checked"},
            {"last_check", "facility", "today"}
          ]
        },
        action_fn: fn state, _args ->
          state
          |> State.set_fact("maintenance_status", "facility", "checked")
          |> State.set_fact("last_check", "facility", "today")
        end
      }
      
      domain = Core.add_durative_action(domain, :maintenance_check, maintenance_check_action)

      # All equipment operational
      operational_state = State.new()
      |> State.set_fact("type", "equipment1", "machinery")
      |> State.set_fact("type", "equipment2", "machinery")
      |> State.set_fact("status", "equipment1", "operational")
      |> State.set_fact("status", "equipment2", "operational")

      result = Actions.execute_action(domain, operational_state, :maintenance_check, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "maintenance_status", "facility") == "checked"

      # One equipment broken
      broken_state = State.new()
      |> State.set_fact("type", "equipment1", "machinery")
      |> State.set_fact("type", "equipment2", "machinery")
      |> State.set_fact("status", "equipment1", "operational")
      |> State.set_fact("status", "equipment2", "broken")

      result = Actions.execute_action(domain, broken_state, :maintenance_check, [])
      assert result == false
    end
  end

  describe "complex quantifier combinations" do
    test "restaurant NPC can serve when tables available and all ingredients ready" do
      domain = Core.new("restaurant_domain")
      
      # Service action with both existential and universal conditions
      serve_meal_action = %DurativeAction{
        name: :serve_meal,
        duration: {:fixed, 10000},  # 10 seconds
        conditions: %{
          at_start: [
            # EXISTS: at least one table is available
            {:exists, "status", "available", &String.contains?(&1, "table")},
            # FORALL: all required ingredients are ready
            {:forall, "status", "ready", &String.contains?(&1, "ingredient")}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"activity", "chef", "meal_served"},
            {"customer_status", "restaurant", "satisfied"}
          ]
        },
        action_fn: fn state, _args ->
          # Find available table and use it
          available_tables = State.get_subjects_with_fact(state, "status", "available")
          |> Enum.filter(&String.contains?(&1, "table"))
          
          case available_tables do
            [table | _] ->
              state
              |> State.set_fact("activity", "chef", "meal_served")
              |> State.set_fact("status", table, "occupied")
              |> State.set_fact("customer_status", "restaurant", "satisfied")
            [] ->
              false
          end
        end
      }
      
      domain = Core.add_durative_action(domain, :serve_meal, serve_meal_action)

      # Test: Table available and all ingredients ready (should succeed)
      ready_state = State.new()
      |> State.set_fact("type", "table1", "furniture")
      |> State.set_fact("type", "table2", "furniture")
      |> State.set_fact("status", "table1", "available")
      |> State.set_fact("status", "table2", "occupied")
      |> State.set_fact("type", "ingredient1", "food")
      |> State.set_fact("type", "ingredient2", "food")
      |> State.set_fact("status", "ingredient1", "ready")
      |> State.set_fact("status", "ingredient2", "ready")

      result = Actions.execute_action(domain, ready_state, :serve_meal, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "customer_status", "restaurant") == "satisfied"

      # Test: Table available but one ingredient not ready (should fail)
      not_ready_state = State.new()
      |> State.set_fact("type", "table1", "furniture")
      |> State.set_fact("status", "table1", "available")
      |> State.set_fact("type", "ingredient1", "food")
      |> State.set_fact("type", "ingredient2", "food")
      |> State.set_fact("status", "ingredient1", "ready")
      |> State.set_fact("status", "ingredient2", "preparing")  # Not ready

      result = Actions.execute_action(domain, not_ready_state, :serve_meal, [])
      assert result == false

      # Test: All ingredients ready but no table available (should fail)
      no_table_state = State.new()
      |> State.set_fact("type", "table1", "furniture")
      |> State.set_fact("type", "table2", "furniture")
      |> State.set_fact("status", "table1", "occupied")
      |> State.set_fact("status", "table2", "occupied")
      |> State.set_fact("type", "ingredient1", "food")
      |> State.set_fact("status", "ingredient1", "ready")

      result = Actions.execute_action(domain, no_table_state, :serve_meal, [])
      assert result == false
    end
  end
end
