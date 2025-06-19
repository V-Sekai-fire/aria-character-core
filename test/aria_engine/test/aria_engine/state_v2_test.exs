# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule StateV2Test do
  use ExUnit.Case, async: true
  doctest AriaEngine.StateV2

  alias AriaEngine.StateV2

  describe "new/0 and new/1" do
    test "creates empty state" do
      state = StateV2.new()
      assert state.data == %{}
    end

    test "creates state from map" do
      data = %{{"player", "location"} => "room1"}
      state = StateV2.new(data)
      assert state.data == data
    end
  end

  describe "entity-first API" do
    test "set_fact/4 and get_fact/3 work with entity-first order" do
      state = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")
      |> StateV2.set_fact("player", "has", "sword")
      |> StateV2.set_fact("npc1", "location", "room2")

      assert StateV2.get_fact(state, "player", "location") == "room1"
      assert StateV2.get_fact(state, "player", "has") == "sword"
      assert StateV2.get_fact(state, "npc1", "location") == "room2"
      assert StateV2.get_fact(state, "player", "unknown") == nil
    end

    test "remove_fact/3 works with entity-first order" do
      state = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")
      |> StateV2.set_fact("player", "has", "sword")
      |> StateV2.remove_fact("player", "location")

      assert StateV2.get_fact(state, "player", "location") == nil
      assert StateV2.get_fact(state, "player", "has") == "sword"
    end

    test "has_predicate?/3 checks entity-first" do
      state = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")

      assert StateV2.has_predicate?(state, "player", "location") == true
      assert StateV2.has_predicate?(state, "player", "unknown") == false
      assert StateV2.has_predicate?(state, "unknown", "location") == false
    end
  end

  describe "entity-centric queries" do
    setup do
      state = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")
      |> StateV2.set_fact("player", "has", "sword")
      |> StateV2.set_fact("player", "health", 100)
      |> StateV2.set_fact("npc1", "location", "room2")
      |> StateV2.set_fact("chair1", "type", "furniture")
      |> StateV2.set_fact("chair1", "status", "available")

      {:ok, state: state}
    end

    test "has_subject?/2 checks if entity exists", %{state: state} do
      assert StateV2.has_subject?(state, "player") == true
      assert StateV2.has_subject?(state, "npc1") == true
      assert StateV2.has_subject?(state, "unknown") == false
    end

    test "get_subjects/1 returns all entity IDs", %{state: state} do
      subjects = StateV2.get_subjects(state)
      assert "player" in subjects
      assert "npc1" in subjects
      assert "chair1" in subjects
      assert length(subjects) == 3
    end

    test "get_predicates/2 returns all properties for entity", %{state: state} do
      player_predicates = StateV2.get_predicates(state, "player")
      assert "location" in player_predicates
      assert "has" in player_predicates
      assert "health" in player_predicates
      assert length(player_predicates) == 3

      chair_predicates = StateV2.get_predicates(state, "chair1")
      assert "type" in chair_predicates
      assert "status" in chair_predicates
      assert length(chair_predicates) == 2
    end

    test "get_properties/2 returns entity properties as map", %{state: state} do
      player_props = StateV2.get_properties(state, "player")
      assert player_props == %{
        "location" => "room1",
        "has" => "sword", 
        "health" => 100
      }

      chair_props = StateV2.get_properties(state, "chair1")
      assert chair_props == %{
        "type" => "furniture",
        "status" => "available"
      }

      empty_props = StateV2.get_properties(state, "unknown")
      assert empty_props == %{}
    end
  end

  describe "triples conversion" do
    test "to_triples/1 and from_triples/1 work correctly" do
      original_triples = [
        {"player", "location", "room1"},
        {"player", "has", "sword"},
        {"npc1", "location", "room2"}
      ]

      state = StateV2.from_triples(original_triples)
      converted_triples = StateV2.to_triples(state)

      # Sort for comparison since order may vary
      assert Enum.sort(converted_triples) == Enum.sort(original_triples)
    end
  end

  describe "state operations" do
    test "merge/2 combines states with second taking precedence" do
      state1 = StateV2.from_triples([
        {"player", "location", "room1"},
        {"player", "health", 100}
      ])

      state2 = StateV2.from_triples([
        {"player", "location", "room2"},  # conflicts with state1
        {"player", "has", "sword"}        # new fact
      ])

      merged = StateV2.merge(state1, state2)

      assert StateV2.get_fact(merged, "player", "location") == "room2"  # state2 wins
      assert StateV2.get_fact(merged, "player", "health") == 100        # from state1
      assert StateV2.get_fact(merged, "player", "has") == "sword"       # from state2
    end

    test "copy/1 creates independent copy" do
      original = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")

      copied = StateV2.copy(original)
      modified = StateV2.set_fact(copied, "player", "location", "room2")

      assert StateV2.get_fact(original, "player", "location") == "room1"
      assert StateV2.get_fact(modified, "player", "location") == "room2"
    end
  end

  describe "pattern matching and conditions" do
    setup do
      state = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")
      |> StateV2.set_fact("chair1", "status", "available")
      |> StateV2.set_fact("chair2", "status", "available")
      |> StateV2.set_fact("table1", "status", "occupied")
      |> StateV2.set_fact("door1", "status", "locked")
      |> StateV2.set_fact("door2", "status", "locked")

      {:ok, state: state}
    end

    test "matches?/4 checks exact entity-predicate-value match", %{state: state} do
      assert StateV2.matches?(state, "player", "location", "room1") == true
      assert StateV2.matches?(state, "player", "location", "room2") == false
      assert StateV2.matches?(state, "unknown", "location", "room1") == false
    end

    test "get_subjects_with_fact/3 finds entities by predicate-value", %{state: state} do
      available_subjects = StateV2.get_subjects_with_fact(state, "status", "available")
      assert "chair1" in available_subjects
      assert "chair2" in available_subjects
      assert length(available_subjects) == 2

      locked_subjects = StateV2.get_subjects_with_fact(state, "status", "locked")
      assert "door1" in locked_subjects
      assert "door2" in locked_subjects
      assert length(locked_subjects) == 2
    end

    test "get_subjects_with_predicate/2 finds entities by predicate", %{state: state} do
      subjects_with_status = StateV2.get_subjects_with_predicate(state, "status")
      assert "chair1" in subjects_with_status
      assert "door1" in subjects_with_status
      assert "player" not in subjects_with_status  # has location, not status
      assert length(subjects_with_status) == 5
    end

    test "exists?/4 checks existential quantifier with entity-first pattern", %{state: state} do
      # Check if any chair is available
      chair_filter = &String.contains?(&1, "chair")
      assert StateV2.exists?(state, chair_filter, "status", "available") == true
      assert StateV2.exists?(state, chair_filter, "status", "locked") == false

      # Check if any entity has location
      assert StateV2.exists?(state, nil, "location", "room1") == true
      assert StateV2.exists?(state, nil, "location", "room999") == false
    end

    test "forall?/4 checks universal quantifier with entity-first pattern", %{state: state} do
      # Check if all doors are locked
      door_filter = &String.contains?(&1, "door")
      assert StateV2.forall?(state, door_filter, "status", "locked") == true
      assert StateV2.forall?(state, door_filter, "status", "available") == false

      # Check if all chairs are available
      chair_filter = &String.contains?(&1, "chair")
      assert StateV2.forall?(state, chair_filter, "status", "available") == true
      assert StateV2.forall?(state, chair_filter, "status", "locked") == false

      # Vacuous truth: no entities match filter
      none_filter = &String.contains?(&1, "nonexistent")
      assert StateV2.forall?(state, none_filter, "status", "anything") == true
    end

    test "evaluate_condition/2 handles different condition formats", %{state: state} do
      # Regular condition (entity-first)
      assert StateV2.evaluate_condition(state, {"player", "location", "room1"}) == true
      assert StateV2.evaluate_condition(state, {"player", "location", "room2"}) == false

      # Existential quantifier
      chair_filter = &String.contains?(&1, "chair")
      exists_condition = {:exists, chair_filter, "status", "available"}
      assert StateV2.evaluate_condition(state, exists_condition) == true

      # Universal quantifier
      door_filter = &String.contains?(&1, "door")
      forall_condition = {:forall, door_filter, "status", "locked"}
      assert StateV2.evaluate_condition(state, forall_condition) == true

      # Unknown condition format
      assert StateV2.evaluate_condition(state, {:unknown, "format"}) == false
    end
  end

  describe "legacy conversion" do
    test "from_legacy_state/1 converts old format to new" do
      # Create legacy state manually (predicate, subject) format
      legacy_data = %{
        {"location", "player"} => "room1",
        {"has", "player"} => "sword",
        {"status", "chair1"} => "available"
      }
      legacy_state = %AriaEngine.StateV2{data: legacy_data}

      # Convert to StateV2
      state_v2 = StateV2.from_legacy_state(legacy_state)

      # Verify entity-first access works
      assert StateV2.get_fact(state_v2, "player", "location") == "room1"
      assert StateV2.get_fact(state_v2, "player", "has") == "sword"
      assert StateV2.get_fact(state_v2, "chair1", "status") == "available"
    end

    test "to_legacy_state/1 converts new format to old" do
      # Create StateV2
      state_v2 = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")
      |> StateV2.set_fact("player", "has", "sword")

      # Convert to legacy
      legacy_state = StateV2.to_legacy_state(state_v2)

      # Verify legacy access works
      assert AriaEngine.StateV2.get_fact(legacy_state, "location", "player") == "room1"
      assert AriaEngine.StateV2.get_fact(legacy_state, "has", "player") == "sword"
    end

    test "round-trip conversion preserves data" do
      # Start with StateV2
      original = StateV2.new()
      |> StateV2.set_fact("player", "location", "room1")
      |> StateV2.set_fact("chair1", "status", "available")

      # Convert to legacy and back
      legacy = StateV2.to_legacy_state(original)
      restored = StateV2.from_legacy_state(legacy)

      # Should be identical
      assert StateV2.get_fact(restored, "player", "location") == "room1"
      assert StateV2.get_fact(restored, "chair1", "status") == "available"
      assert restored.data == original.data
    end
  end
end
