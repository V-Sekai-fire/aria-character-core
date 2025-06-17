# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StateQuantifiersTest do
  @moduledoc """
  Tests for quantifier support (existential and universal) in AriaEngine.State.
  
  These tests verify the implementation of Phase 1 from ADR-085: Quantifiers Support.
  """
  
  use ExUnit.Case, async: true
  alias AriaEngine.State

  describe "existential quantifier (exists?)" do
    test "finds existing subjects matching predicate and value" do
      state = State.new()
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "chair2", "occupied")
      |> State.set_fact("status", "table1", "available")
      |> State.set_fact("type", "chair1", "furniture")

      # Check if any chair is available
      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(state, "status", "available", chair_filter) == true

      # Check if any table is occupied  
      table_filter = &String.contains?(&1, "table")
      assert State.exists?(state, "status", "occupied", table_filter) == false

      # Check if any furniture exists (without predicate constraint)
      assert State.exists?(state, "type", "furniture") == true
    end

    test "returns false when no subjects match" do
      state = State.new()
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "locked")

      # Check if any chair is available (no chairs exist)
      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(state, "status", "available", chair_filter) == false

      # Check if any door is unlocked
      door_filter = &String.contains?(&1, "door")
      assert State.exists?(state, "status", "unlocked", door_filter) == false
    end

    test "works without subject filter" do
      state = State.new()
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "table1", "available")

      # Check if anything has status "available"
      assert State.exists?(state, "status", "available") == true
      assert State.exists?(state, "status", "missing") == false
    end

    test "handles edge cases gracefully" do
      empty_state = State.new()
      
      # Empty state should return false for any exists check
      assert State.exists?(empty_state, "status", "available") == false
      
      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(empty_state, "status", "available", chair_filter) == false
    end
  end

  describe "universal quantifier (forall?)" do
    test "returns true when all matching subjects have required property" do
      state = State.new()
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "locked")
      |> State.set_fact("status", "door3", "locked")
      |> State.set_fact("status", "chair1", "available")

      # Check if all doors are locked
      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, "status", "locked", door_filter) == true

      # Check if all chairs are available
      chair_filter = &String.contains?(&1, "chair")
      assert State.forall?(state, "status", "available", chair_filter) == true
    end

    test "returns false when some subjects don't have required property" do
      state = State.new()
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "unlocked")
      |> State.set_fact("status", "door3", "locked")

      # Check if all doors are locked (door2 is unlocked)
      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, "status", "locked", door_filter) == false
    end

    test "returns true for vacuous truth when no subjects match filter" do
      state = State.new()
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "table1", "available")

      # Check if all doors are locked (no doors exist, so vacuously true)
      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, "status", "locked", door_filter) == true
    end

    test "handles missing predicates correctly" do
      state = State.new()
      |> State.set_fact("location", "door1", "room1")
      |> State.set_fact("location", "door2", "room2")

      # Check if all doors are locked (doors exist but no status predicate)
      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, "status", "locked", door_filter) == false
    end
  end

  describe "evaluate_condition/2" do
    test "handles existential quantifier conditions" do
      state = State.new()
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "chair2", "occupied")
      |> State.set_fact("status", "table1", "available")

      # Existential: any chair is available
      chair_filter = &String.contains?(&1, "chair")
      exists_condition = {:exists, "status", "available", chair_filter}
      assert State.evaluate_condition(state, exists_condition) == true

      # Existential: any desk is available (no desks exist)
      desk_filter = &String.contains?(&1, "desk")
      no_exists_condition = {:exists, "status", "available", desk_filter}
      assert State.evaluate_condition(state, no_exists_condition) == false
    end

    test "handles universal quantifier conditions" do
      state = State.new()
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "locked")
      |> State.set_fact("status", "chair1", "available")

      # Universal: all doors are locked
      door_filter = &String.contains?(&1, "door")
      forall_condition = {:forall, "status", "locked", door_filter}
      assert State.evaluate_condition(state, forall_condition) == true

      # Universal: all chairs are locked (chair1 is available, not locked)
      chair_filter = &String.contains?(&1, "chair")
      false_forall_condition = {:forall, "status", "locked", chair_filter}
      assert State.evaluate_condition(state, false_forall_condition) == false
    end

    test "handles regular conditions (backward compatibility)" do
      state = State.new()
      |> State.set_fact("location", "player", "room1")
      |> State.set_fact("status", "door1", "locked")

      # Regular condition check
      regular_condition = {"location", "player", "room1"}
      assert State.evaluate_condition(state, regular_condition) == true

      false_condition = {"location", "player", "room2"}
      assert State.evaluate_condition(state, false_condition) == false
    end

    test "handles unknown condition formats gracefully" do
      state = State.new()
      
      # Unknown condition format should return false and log warning
      unknown_condition = {:unknown, "some", "data"}
      assert State.evaluate_condition(state, unknown_condition) == false
    end
  end

  describe "helper functions" do
    test "get_subjects_with_fact/3" do
      state = State.new()
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "chair2", "occupied")
      |> State.set_fact("status", "table1", "available")
      |> State.set_fact("location", "chair1", "room1")

      # Get all subjects with status "available"
      available_subjects = State.get_subjects_with_fact(state, "status", "available")
      assert Enum.sort(available_subjects) == ["chair1", "table1"]

      # Get all subjects with status "occupied"
      occupied_subjects = State.get_subjects_with_fact(state, "status", "occupied")
      assert occupied_subjects == ["chair2"]

      # Get all subjects with status "missing" (none)
      missing_subjects = State.get_subjects_with_fact(state, "status", "missing")
      assert missing_subjects == []
    end

    test "get_subjects_with_predicate/2" do
      state = State.new()
      |> State.set_fact("status", "chair1", "available")
      |> State.set_fact("status", "chair2", "occupied")
      |> State.set_fact("location", "chair1", "room1")
      |> State.set_fact("location", "player", "room1")

      # Get all subjects with "status" predicate
      status_subjects = State.get_subjects_with_predicate(state, "status")
      assert Enum.sort(status_subjects) == ["chair1", "chair2"]

      # Get all subjects with "location" predicate
      location_subjects = State.get_subjects_with_predicate(state, "location")
      assert Enum.sort(location_subjects) == ["chair1", "player"]

      # Get all subjects with "type" predicate (none)
      type_subjects = State.get_subjects_with_predicate(state, "type")
      assert type_subjects == []
    end
  end

  describe "complex NPC reasoning scenarios" do
    test "NPC can find any available seating" do
      # Scenario: NPC needs to find any chair or bench that's available
      state = State.new()
      |> State.set_fact("type", "chair1", "seating")
      |> State.set_fact("type", "chair2", "seating")
      |> State.set_fact("type", "bench1", "seating")
      |> State.set_fact("type", "table1", "furniture")
      |> State.set_fact("status", "chair1", "occupied")
      |> State.set_fact("status", "chair2", "available")
      |> State.set_fact("status", "bench1", "available")
      |> State.set_fact("status", "table1", "available")

      # Find any seating that's available
      seating_subjects = State.get_subjects_with_fact(state, "type", "seating")
      available_seating = Enum.any?(seating_subjects, fn subject ->
        State.matches?(state, "status", subject, "available")
      end)
      
      assert available_seating == true

      # Using quantifier: exists available seating
      seating_filter = fn subject ->
        State.matches?(state, "type", subject, "seating")
      end
      assert State.exists?(state, "status", "available", seating_filter) == true
    end

    test "NPC can verify all doors in area are secured" do
      # Scenario: Security NPC needs to ensure all doors in a building wing are locked
      state = State.new()
      |> State.set_fact("type", "door1", "door")
      |> State.set_fact("type", "door2", "door")
      |> State.set_fact("type", "door3", "door")
      |> State.set_fact("type", "window1", "window")
      |> State.set_fact("location", "door1", "west_wing")
      |> State.set_fact("location", "door2", "west_wing")
      |> State.set_fact("location", "door3", "east_wing")
      |> State.set_fact("location", "window1", "west_wing")
      |> State.set_fact("status", "door1", "locked")
      |> State.set_fact("status", "door2", "locked")
      |> State.set_fact("status", "door3", "unlocked")
      |> State.set_fact("status", "window1", "closed")

      # Check if all doors in west wing are locked
      west_wing_doors_filter = fn subject ->
        State.matches?(state, "type", subject, "door") and
        State.matches?(state, "location", subject, "west_wing")
      end

      assert State.forall?(state, "status", "locked", west_wing_doors_filter) == true

      # Check if all doors in the building are locked (should be false due to door3)
      all_doors_filter = fn subject ->
        State.matches?(state, "type", subject, "door")
      end

      assert State.forall?(state, "status", "locked", all_doors_filter) == false
    end

    test "NPC can check resource availability patterns" do
      # Scenario: Crafting NPC needs to find available materials
      state = State.new()
      |> State.set_fact("type", "wood1", "material")
      |> State.set_fact("type", "wood2", "material")
      |> State.set_fact("type", "iron1", "material")
      |> State.set_fact("type", "iron2", "material")
      |> State.set_fact("subtype", "wood1", "wood")
      |> State.set_fact("subtype", "wood2", "wood")
      |> State.set_fact("subtype", "iron1", "iron")
      |> State.set_fact("subtype", "iron2", "iron")
      |> State.set_fact("status", "wood1", "available")
      |> State.set_fact("status", "wood2", "reserved")
      |> State.set_fact("status", "iron1", "available")
      |> State.set_fact("status", "iron2", "available")

      # Check if any wood is available
      wood_filter = fn subject ->
        State.matches?(state, "subtype", subject, "wood")
      end
      assert State.exists?(state, "status", "available", wood_filter) == true

      # Check if all iron is available
      iron_filter = fn subject ->
        State.matches?(state, "subtype", subject, "iron")
      end
      assert State.forall?(state, "status", "available", iron_filter) == true

      # Check if all wood is available (should be false due to wood2 being reserved)
      assert State.forall?(state, "status", "available", wood_filter) == false
    end
  end
end
