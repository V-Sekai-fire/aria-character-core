# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule DurativeActionsQuantifiersTest do
  @moduledoc "Integration tests for durative actions with quantifier support.\n\nTests verify that durative actions can use existential and universal quantifiers\nin their preconditions, enabling more sophisticated NPC reasoning patterns.\n"
  use ExUnit.Case, async: true
  alias AriaEngine.State
  alias Domain.{Core, DurativeAction, Actions}

  describe("durative actions with existential quantifiers") do
    test "NPC can find any available seating" do
      domain = Core.new("seating_domain")

      find_seating_action = %DurativeAction{
        name: :find_seating,
        duration: {:fixed, 5000},
        conditions: %{
          at_start: [{:exists, &String.contains?(&1, "chair"), "status", "available"}],
          over_all: [],
          at_end: []
        },
        effects: %{at_start: [], at_end: [{"npc", "activity", "sitting"}]},
        action_fn: fn state, _args ->
          available_chairs =
            State.get_subjects_with_fact(state, "status", "available")
            |> Enum.filter(&String.contains?(&1, "chair"))

          case available_chairs do
            [chair | _] ->
              state
              |> State.set_fact("npc", "activity", "sitting")
              |> State.set_fact(chair, "status", "occupied")
              |> State.set_fact("npc", "location", chair)

            [] ->
              false
          end
        end
      }

      domain = Domain.add_action(domain, :find_seating, find_seating_action)

      state_with_chairs =
        State.new()
        |> State.set_fact("chair1", "type", "furniture")
        |> State.set_fact("chair2", "type", "furniture")
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "occupied")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("npc", "activity", "standing")

      result = Actions.execute_action(domain, state_with_chairs, :find_seating, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "npc", "activity") == "sitting"
      assert State.get_fact(new_state, "chair1", "status") == "occupied"

      state_no_chairs =
        State.new()
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("table2", "type", "furniture")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("table2", "status", "available")

      result = Actions.execute_action(domain, state_no_chairs, :find_seating, [])
      assert result == false
    end

    test "NPC can craft when any required material is available" do
      domain = Core.new("crafting_domain")

      craft_simple_action = %DurativeAction{
        name: :craft_simple,
        duration: {:fixed, 5000},
        conditions: %{
          at_start: [{:exists, &String.contains?(&1, "wood"), "status", "available"}],
          over_all: [],
          at_end: []
        },
        effects: %{at_start: [], at_end: [{"npc", "inventory", "item"}]},
        action_fn: fn state, _args -> State.set_fact(state, "npc", "inventory", "item") end
      }

      domain = Domain.add_action(domain, :craft_simple, craft_simple_action)

      state_simple =
        State.new()
        |> State.set_fact("wood1", "status", "available")
        |> State.set_fact("iron1", "status", "unavailable")

      result = Actions.execute_action(domain, state_simple, :craft_simple, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "npc", "inventory") == "item"
    end
  end

  describe("durative actions with universal quantifiers") do
    test "security NPC can verify all doors are locked" do
      domain = Core.new("security_domain")

      security_patrol_action = %DurativeAction{
        name: :security_patrol,
        duration: {:fixed, 30000},
        conditions: %{
          at_start: [{:forall, &String.contains?(&1, "door"), "status", "locked"}],
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

      domain = Domain.add_action(domain, :security_patrol, security_patrol_action)

      secure_state =
        State.new()
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

      insecure_state =
        State.new()
        |> State.set_fact("door1", "type", "entrance")
        |> State.set_fact("door2", "type", "entrance")
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "unlocked")

      result = Actions.execute_action(domain, insecure_state, :security_patrol, [])
      assert result == false

      no_doors_state =
        State.new()
        |> State.set_fact("window1", "type", "opening")
        |> State.set_fact("window1", "status", "closed")

      result = Actions.execute_action(domain, no_doors_state, :security_patrol, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "building", "security_status") == "secure"
    end

    test "maintenance NPC can verify all equipment is operational" do
      domain = Core.new("maintenance_domain")

      maintenance_check_action = %DurativeAction{
        name: :maintenance_check,
        duration: {:fixed, 15000},
        conditions: %{
          at_start: [{:forall, &String.contains?(&1, "equipment"), "status", "operational"}],
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

      domain = Domain.add_action(domain, :maintenance_check, maintenance_check_action)

      operational_state =
        State.new()
        |> State.set_fact("equipment1", "type", "machinery")
        |> State.set_fact("equipment2", "type", "machinery")
        |> State.set_fact("equipment1", "status", "operational")
        |> State.set_fact("equipment2", "status", "operational")

      result = Actions.execute_action(domain, operational_state, :maintenance_check, [])
      assert {:ok, new_state} = result
      assert State.get_fact(new_state, "facility", "maintenance_status") == "checked"

      broken_state =
        State.new()
        |> State.set_fact("equipment1", "type", "machinery")
        |> State.set_fact("equipment2", "type", "machinery")
        |> State.set_fact("equipment1", "status", "operational")
        |> State.set_fact("equipment2", "status", "broken")

      result = Actions.execute_action(domain, broken_state, :maintenance_check, [])
      assert result == false
    end
  end

  describe("complex quantifier combinations") do
    test "restaurant NPC can serve when tables available and all ingredients ready" do
      domain = Core.new("restaurant_domain")

      serve_meal_action = %DurativeAction{
        name: :serve_meal,
        duration: {:fixed, 10000},
        conditions: %{
          at_start: [
            {:exists, &String.contains?(&1, "table"), "status", "available"},
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
          available_tables =
            State.get_subjects_with_fact(state, "status", "available")
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

      domain = Domain.add_action(domain, :serve_meal, serve_meal_action)

      ready_state =
        State.new()
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

      not_ready_state =
        State.new()
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("ingredient1", "type", "food")
        |> State.set_fact("ingredient2", "type", "food")
        |> State.set_fact("ingredient1", "status", "ready")
        |> State.set_fact("ingredient2", "status", "preparing")

      result = Actions.execute_action(domain, not_ready_state, :serve_meal, [])
      assert result == false

      no_table_state =
        State.new()
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