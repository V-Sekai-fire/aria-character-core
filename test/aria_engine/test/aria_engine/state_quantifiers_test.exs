defmodule StateQuantifiersTest do
  @moduledoc "Tests for quantifier support (existential and universal) in State.\n\nThese tests verify the implementation of Phase 1 from ADR-085: Quantifiers Support.\n"
  use ExUnit.Case, async: true
  alias AriaEngine.State

  describe("existential quantifier (exists?)") do
    test "finds existing subjects matching predicate and value" do
      state =
        State.new()
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "occupied")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("chair1", "type", "furniture")

      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(state, chair_filter, "status", "available") == true
      table_filter = &String.contains?(&1, "table")
      assert State.exists?(state, table_filter, "status", "occupied") == false
      assert State.exists?(state, nil, "type", "furniture") == true
    end

    test "returns false when no subjects match" do
      state =
        State.new()
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "locked")

      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(state, chair_filter, "status", "available") == false
      door_filter = &String.contains?(&1, "door")
      assert State.exists?(state, door_filter, "status", "unlocked") == false
    end

    test "works without subject filter" do
      state =
        State.new()
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("table1", "status", "available")

      assert State.exists?(state, nil, "status", "available") == true
      assert State.exists?(state, nil, "status", "missing") == false
    end

    test "handles edge cases gracefully" do
      empty_state = State.new()
      assert State.exists?(empty_state, nil, "status", "available") == false
      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(empty_state, chair_filter, "status", "available") == false
    end
  end

  describe("universal quantifier (forall?)") do
    test "returns true when all matching subjects have required property" do
      state =
        State.new()
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "locked")
        |> State.set_fact("door3", "status", "locked")
        |> State.set_fact("chair1", "status", "available")

      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, door_filter, "status", "locked") == true
      chair_filter = &String.contains?(&1, "chair")
      assert State.forall?(state, chair_filter, "status", "available") == true
    end

    test "returns false when some subjects don't have required property" do
      state =
        State.new()
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "unlocked")
        |> State.set_fact("door3", "status", "locked")

      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, door_filter, "status", "locked") == false
    end

    test "returns true for vacuous truth when no subjects match filter" do
      state =
        State.new()
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("table1", "status", "available")

      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, door_filter, "status", "locked") == true
    end

    test "handles missing predicates correctly" do
      state =
        State.new()
        |> State.set_fact("door1", "location", "room1")
        |> State.set_fact("door2", "location", "room2")

      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, door_filter, "status", "locked") == false
    end
  end

  describe("evaluate_condition/2") do
    test "handles existential quantifier conditions" do
      state =
        State.new()
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "occupied")
        |> State.set_fact("table1", "status", "available")

      chair_filter = &String.contains?(&1, "chair")
      exists_condition = {:exists, chair_filter, "status", "available"}
      assert State.evaluate_condition(state, exists_condition) == true
      desk_filter = &String.contains?(&1, "desk")
      no_exists_condition = {:exists, desk_filter, "status", "available"}
      assert State.evaluate_condition(state, no_exists_condition) == false
    end

    test "handles universal quantifier conditions" do
      state =
        State.new()
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "locked")
        |> State.set_fact("chair1", "status", "available")

      door_filter = &String.contains?(&1, "door")
      forall_condition = {:forall, door_filter, "status", "locked"}
      assert State.evaluate_condition(state, forall_condition) == true
      chair_filter = &String.contains?(&1, "chair")
      false_forall_condition = {:forall, chair_filter, "status", "locked"}
      assert State.evaluate_condition(state, false_forall_condition) == false
    end

    test "handles regular conditions (backward compatibility)" do
      state =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("door1", "status", "locked")

      regular_condition = {"player", "location", "room1"}
      assert State.evaluate_condition(state, regular_condition) == true
      false_condition = {"player", "location", "room2"}
      assert State.evaluate_condition(state, false_condition) == false
    end

    test "handles unknown condition formats gracefully" do
      state = State.new()
      unknown_condition = {:unknown, "some", "data"}
      assert State.evaluate_condition(state, unknown_condition) == false
    end
  end

  describe("helper functions") do
    test "get_subjects_with_fact/3" do
      state =
        State.new()
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "occupied")
        |> State.set_fact("table1", "status", "available")
        |> State.set_fact("chair1", "location", "room1")

      available_subjects = State.get_subjects_with_fact(state, "status", "available")
      assert Enum.sort(available_subjects) == ["chair1", "table1"]
      occupied_subjects = State.get_subjects_with_fact(state, "status", "occupied")
      assert occupied_subjects == ["chair2"]
      missing_subjects = State.get_subjects_with_fact(state, "status", "missing")
      assert missing_subjects == []
    end

    test "get_subjects_with_predicate/2" do
      state =
        State.new()
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "occupied")
        |> State.set_fact("chair1", "location", "room1")
        |> State.set_fact("player", "location", "room1")

      status_subjects = State.get_subjects_with_predicate(state, "status")
      assert Enum.sort(status_subjects) == ["chair1", "chair2"]
      location_subjects = State.get_subjects_with_predicate(state, "location")
      assert Enum.sort(location_subjects) == ["chair1", "player"]
      type_subjects = State.get_subjects_with_predicate(state, "type")
      assert type_subjects == []
    end
  end

  describe("complex NPC reasoning scenarios") do
    test "NPC can find any available seating" do
      state =
        State.new()
        |> State.set_fact("chair1", "type", "seating")
        |> State.set_fact("chair2", "type", "seating")
        |> State.set_fact("bench1", "type", "seating")
        |> State.set_fact("table1", "type", "furniture")
        |> State.set_fact("chair1", "status", "occupied")
        |> State.set_fact("chair2", "status", "available")
        |> State.set_fact("bench1", "status", "available")
        |> State.set_fact("table1", "status", "available")

      seating_subjects = State.get_subjects_with_fact(state, "type", "seating")

      available_seating =
        Enum.any?(seating_subjects, fn subject ->
          State.matches_exactly?(state, subject, "status", "available")
        end)

      assert available_seating == true
      seating_filter = fn subject -> State.matches_exactly?(state, subject, "type", "seating") end
      assert State.exists?(state, seating_filter, "status", "available") == true
    end

    test "NPC can verify all doors in area are secured" do
      state =
        State.new()
        |> State.set_fact("door1", "type", "door")
        |> State.set_fact("door2", "type", "door")
        |> State.set_fact("door3", "type", "door")
        |> State.set_fact("window1", "type", "window")
        |> State.set_fact("door1", "location", "west_wing")
        |> State.set_fact("door2", "location", "west_wing")
        |> State.set_fact("door3", "location", "east_wing")
        |> State.set_fact("window1", "location", "west_wing")
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "locked")
        |> State.set_fact("door3", "status", "unlocked")
        |> State.set_fact("window1", "status", "closed")

      west_wing_doors_filter = fn subject ->
        State.matches_exactly?(state, subject, "type", "door") and
          State.matches_exactly?(state, subject, "location", "west_wing")
      end

      assert State.forall?(state, west_wing_doors_filter, "status", "locked") == true
      all_doors_filter = fn subject -> State.matches_exactly?(state, subject, "type", "door") end
      assert State.forall?(state, all_doors_filter, "status", "locked") == false
    end

    test "NPC can check resource availability patterns" do
      state =
        State.new()
        |> State.set_fact("wood1", "type", "material")
        |> State.set_fact("wood2", "type", "material")
        |> State.set_fact("iron1", "type", "material")
        |> State.set_fact("iron2", "type", "material")
        |> State.set_fact("wood1", "subtype", "wood")
        |> State.set_fact("wood2", "subtype", "wood")
        |> State.set_fact("iron1", "subtype", "iron")
        |> State.set_fact("iron2", "subtype", "iron")
        |> State.set_fact("wood1", "status", "available")
        |> State.set_fact("wood2", "status", "reserved")
        |> State.set_fact("iron1", "status", "available")
        |> State.set_fact("iron2", "status", "available")

      wood_filter = fn subject -> State.matches_exactly?(state, subject, "subtype", "wood") end
      assert State.exists?(state, wood_filter, "status", "available") == true
      iron_filter = fn subject -> State.matches_exactly?(state, subject, "subtype", "iron") end
      assert State.forall?(state, iron_filter, "status", "available") == true
      assert State.forall?(state, wood_filter, "status", "available") == false
    end
  end
end