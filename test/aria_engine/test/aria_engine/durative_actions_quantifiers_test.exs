# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule DurativeActionsQuantifiersTest do
  @moduledoc """
  Integration tests for durative actions with quantifier support.

  Tests verify that durative actions can use existential and universal quantifiers
  in their preconditions, enabling more sophisticated NPC reasoning patterns.
  """

  use ExUnit.Case, async: true
  alias AriaEngine.StateV2
  alias AriaEngine.Domain.{Core, Actions}

  # FIXME: Suspect this is a bug in the test suite because of integer durations that aren't ISO String

  describe "durative actions with existential quantifiers" do
    test "NPC can find any available seating" do
      # Create domain with seating-finding action
      domain = Core.new("seating_domain")

      # Define a durative action that requires ANY chair to be available
      find_seating_action = %AriaEngine.Domain.DurativeAction{
        name: :find_seating,
        # 5 seconds
        duration: {:fixed, 5000},
        conditions: %{
          at_start: [
            # Existential condition: any chair must be available
            {:exists, &String.contains?(&1, "chair"), "status", "available"}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"npc", "activity", "sitting"}
          ]
        },
        action_fn: fn state, _args ->
          # Find the first available chair
          available_chairs =
            StateV2.get_subjects_with_fact(state, "status", "available")
            |> Enum.filter(&String.contains?(&1, "chair"))

          case available_chairs do
            [chair | _] ->
              state
              |> State.set_fact("npc", "activity", "sitting")
              |> State.set_fact(chair, "status", "occupied")
              |> State.set_fact("npc", "location", chair)

            [] ->
              # Should not happen due to precondition
              false
          end
        end
      }

      domain = AriaEngine.Domain.add_action(domain, :find_seating, find_seating_action)

      # Test scenario 1: Chairs available
      state_with_chairs =
        StateV2.new()
        |> State.set_fact("chair1", "type", "furniture")
        |> State.set_fact("chair2", "type", "furniture")
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "occupied")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("npc", "activity", "standing")

      # Action should succeed because chair1 is available
      result = Actions.execute_action(domain, state_with_chairs, :find_seating, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "npc", "activity") == "sitting"
      assert State.get_fact(new_state, "chair1", "status") == "occupied"

      # Test scenario 2: No chairs available
      state_no_chairs =
        StateV2.new()
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("table2", "type", "furniture")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("table2", "status", "available")

      # Action should fail because no chairs exist
      result = Actions.execute_action(domain, state_no_chairs, :find_seating, [])
      assert result == false
    end

    test "NPC can craft when any required material is available" do
      domain = Core.new("crafting_domain")

      # Simple crafting action that requires ANY wood to be available
      craft_simple_action = %AriaEngine.Domain.DurativeAction{
        name: :craft_simple,
        # 5 seconds
        duration: {:fixed, 5000},
        conditions: %{
          at_start: [
            # Simple existential: any wood is available
            {:exists, &String.contains?(&1, "wood"), "status", "available"}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [{"npc", "inventory", "item"}]
        },
        action_fn: fn state, _args ->
          State.set_fact(state, "npc", "inventory", "item")
        end
      }

      domain = AriaEngine.Domain.add_action(domain, :craft_simple, craft_simple_action)

      state_simple =
        StateV2.new()
        |> State.set_fact("wood1", "status", "available")
        |> State.set_fact("iron1", "status", "unavailable")

      result = Actions.execute_action(domain, state_simple, :craft_simple, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "npc", "inventory") == "item"
    end
  end

  describe "durative actions with universal quantifiers" do
    test "security NPC can verify all doors are locked" do
      domain = Core.new("security_domain")

      # Security patrol action that requires ALL doors to be locked
      security_patrol_action = %AriaEngine.Domain.DurativeAction{
        name: :security_patrol,
        # 30 seconds
        duration: {:fixed, 30000},
        conditions: %{
          at_start: [
            # Universal condition: all doors must be locked
            {:forall, &String.contains?(&1, "door"), "status", "locked"}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"security_npc", "activity", "patrol_complete"},
            {"building", "security_status", "secure"}
          ]
        },
        action_fn: fn state, _args ->
          state
          |> State.set_fact("security_npc", "activity", "patrol_complete")
          |> State.set_fact("building", "security_status", "secure")
        end
      }

      domain = AriaEngine.Domain.add_action(domain, :security_patrol, security_patrol_action)

      # Test scenario 1: All doors locked (should succeed)
      secure_state =
        StateV2.new()
        |> State.set_fact("door1", "type", "entrance")
        |> State.set_fact("door2", "type", "entrance")
        |> State.set_fact("door3", "type", "entrance")
        |> State.set_fact("window1", "type", "opening")
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "locked")
        |> State.set_fact("door3", "status", "locked")
        |> State.set_fact("window1", "status", "closed")

      result = Actions.execute_action(domain, secure_state, :security_patrol, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "building", "security_status") == "secure"

      # Test scenario 2: One door unlocked (should fail)
      insecure_state =
        StateV2.new()
        |> State.set_fact("door1", "type", "entrance")
        |> State.set_fact("door2", "type", "entrance")
        |> State.set_fact("door1", "status", "locked")
        # This breaks the universal condition
        |> State.set_fact("door2", "status", "unlocked")

      result = Actions.execute_action(domain, insecure_state, :security_patrol, [])
      assert result == false

      # Test scenario 3: No doors exist (vacuous truth, should succeed)
      no_doors_state =
        StateV2.new()
        |> State.set_fact("window1", "type", "opening")
        |> State.set_fact("window1", "status", "closed")

      result = Actions.execute_action(domain, no_doors_state, :security_patrol, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "building", "security_status") == "secure"
    end

    test "maintenance NPC can verify all equipment is operational" do
      domain = Core.new("maintenance_domain")

      # Maintenance check that requires all equipment to be operational
      maintenance_check_action = %AriaEngine.Domain.DurativeAction{
        name: :maintenance_check,
        # 15 seconds
        duration: {:fixed, 15000},
        conditions: %{
          at_start: [
            # All equipment must be operational
            {:forall, &String.contains?(&1, "equipment"), "status", "operational"}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"facility", "maintenance_status", "checked"},
            {"facility", "last_check", "today"}
          ]
        },
        action_fn: fn state, _args ->
          state
          |> State.set_fact("facility", "maintenance_status", "checked")
          |> State.set_fact("facility", "last_check", "today")
        end
      }

      domain = AriaEngine.Domain.add_action(domain, :maintenance_check, maintenance_check_action)

      # All equipment operational
      operational_state =
        StateV2.new()
        |> State.set_fact("equipment1", "type", "machinery")
        |> State.set_fact("equipment2", "type", "machinery")
        |> State.set_fact("equipment1", "status", "operational")
        |> State.set_fact("equipment2", "status", "operational")

      result = Actions.execute_action(domain, operational_state, :maintenance_check, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "facility", "maintenance_status") == "checked"

      # One equipment broken
      broken_state =
        StateV2.new()
        |> State.set_fact("equipment1", "type", "machinery")
        |> State.set_fact("equipment2", "type", "machinery")
        |> State.set_fact("equipment1", "status", "operational")
        |> State.set_fact("equipment2", "status", "broken")

      result = Actions.execute_action(domain, broken_state, :maintenance_check, [])
      assert result == false
    end
  end

  describe "complex quantifier combinations" do
    test "restaurant NPC can serve when tables available and all ingredients ready" do
      domain = Core.new("restaurant_domain")

      # Service action with both existential and universal conditions
      serve_meal_action = %AriaEngine.Domain.DurativeAction{
        name: :serve_meal,
        # 10 seconds
        duration: {:fixed, 10000},
        conditions: %{
          at_start: [
            # EXISTS: at least one table is available
            {:exists, &String.contains?(&1, "table"), "status", "available"},
            # FORALL: all required ingredients are ready
            {:forall, &String.contains?(&1, "ingredient"), "status", "ready"}
          ],
          over_all: [],
          at_end: []
        },
        effects: %{
          at_start: [],
          at_end: [
            {"chef", "activity", "meal_served"},
            {"restaurant", "customer_status", "satisfied"}
          ]
        },
        action_fn: fn state, _args ->
          # Find available table and use it
          available_tables =
            StateV2.get_subjects_with_fact(state, "status", "available")
            |> Enum.filter(&String.contains?(&1, "table"))

          case available_tables do
            [table | _] ->
              state
              |> State.set_fact("chef", "activity", "meal_served")
              |> State.set_fact("status", table, "occupied")
              |> State.set_fact("restaurant", "customer_status", "satisfied")

            [] ->
              false
          end
        end
      }

      domain = AriaEngine.Domain.add_action(domain, :serve_meal, serve_meal_action)

      # Test: Table available and all ingredients ready (should succeed)
      ready_state =
        StateV2.new()
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("table2", "type", "furniture")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("table2", "status", "occupied")
        |> State.set_fact("ingredient1", "type", "food")
        |> State.set_fact("ingredient2", "type", "food")
        |> State.set_fact("ingredient1", "status", "ready")
        |> State.set_fact("ingredient2", "status", "ready")

      result = Actions.execute_action(domain, ready_state, :serve_meal, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "restaurant", "customer_status") == "satisfied"

      # Test: Table available but one ingredient not ready (should fail)
      not_ready_state =
        StateV2.new()
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("ingredient1", "type", "food")
        |> State.set_fact("ingredient2", "type", "food")
        |> State.set_fact("ingredient1", "status", "ready")
        # Not ready
        |> State.set_fact("ingredient2", "status", "preparing")

      result = Actions.execute_action(domain, not_ready_state, :serve_meal, [])
      assert result == false

      # Test: All ingredients ready but no table available (should fail)
      no_table_state =
        StateV2.new()
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("table2", "type", "furniture")
        |> State.set_fact("table1", "status", "occupied")
        |> State.set_fact("table2", "status", "occupied")
        |> State.set_fact("ingredient1", "type", "food")
        |> State.set_fact("ingredient1", "status", "ready")

      result = Actions.execute_action(domain, no_table_state, :serve_meal, [])
      assert result == false
    end
  end
end
