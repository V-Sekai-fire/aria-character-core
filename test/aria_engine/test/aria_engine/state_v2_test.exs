# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule StateV2Test do
  use ExUnit.Case, async: true
  doctest AriaEngine.State
  alias AriaEngine.State

  describe("new/0 and new/1") do
    test "creates empty state" do
      state = State.new()
      assert state.data == %{}
    end

    test "creates state from map" do
      data = %{{"player", "location"} => "room1"}
      state = State.new(data)
      assert state.data == data
    end
  end

  describe("entity-first API") do
    test "set_fact/4 and get_fact/3 work with entity-first order" do
      state =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("player", "has", "sword")
        |> State.set_fact("npc1", "location", "room2")

      assert State.get_fact(state, "player", "location") == "room1"
      assert State.get_fact(state, "player", "has") == "sword"
      assert State.get_fact(state, "npc1", "location") == "room2"
      assert State.get_fact(state, "player", "unknown") == nil
    end

    test "remove_fact/3 works with entity-first order" do
      state =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("player", "has", "sword")
        |> State.remove_fact("player", "location")

      assert State.get_fact(state, "player", "location") == nil
      assert State.get_fact(state, "player", "has") == "sword"
    end

    test "has_predicate?/3 checks entity-first" do
      state = State.new() |> State.set_fact("player", "location", "room1")
      assert State.has_predicate?(state, "player", "location") == true
      assert State.has_predicate?(state, "player", "unknown") == false
      assert State.has_predicate?(state, "unknown", "location") == false
    end
  end

  describe("entity-centric queries") do
    setup do
      state =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("player", "has", "sword")
        |> State.set_fact("player", "health", 100)
        |> State.set_fact("npc1", "location", "room2")
        |> State.set_fact("chair1", "type", "furniture")
        |> State.set_fact("chair1", "status", "available")

      {:ok, state: state}
    end

    test("has_subject?/2 checks if entity exists", %{state: state}) do
      assert State.has_subject?(state, "player") == true
      assert State.has_subject?(state, "npc1") == true
      assert State.has_subject?(state, "unknown") == false
    end

    test("get_subjects/1 returns all entity IDs", %{state: state}) do
      subjects = State.get_subjects(state)
      assert "player" in subjects
      assert "npc1" in subjects
      assert "chair1" in subjects
      assert length(subjects) == 3
    end

    test("get_predicates/2 returns all properties for entity", %{state: state}) do
      player_predicates = State.get_predicates(state, "player")
      assert "location" in player_predicates
      assert "has" in player_predicates
      assert "health" in player_predicates
      assert length(player_predicates) == 3
      chair_predicates = State.get_predicates(state, "chair1")
      assert "type" in chair_predicates
      assert "status" in chair_predicates
      assert length(chair_predicates) == 2
    end

    test("get_properties/2 returns entity properties as map", %{state: state}) do
      player_props = State.get_properties(state, "player")
      assert player_props == %{"location" => "room1", "has" => "sword", "health" => 100}
      chair_props = State.get_properties(state, "chair1")
      assert chair_props == %{"type" => "furniture", "status" => "available"}
      empty_props = State.get_properties(state, "unknown")
      assert empty_props == %{}
    end
  end

  describe("triples conversion") do
    test "to_triples/1 and from_triples/1 work correctly" do
      original_triples = [
        {"player", "location", "room1"},
        {"player", "has", "sword"},
        {"npc1", "location", "room2"}
      ]

      state = State.from_triples(original_triples)
      converted_triples = State.to_triples(state)
      assert Enum.sort(converted_triples) == Enum.sort(original_triples)
    end
  end

  describe("state operations") do
    test "merge/2 combines states with second taking precedence" do
      state1 = State.from_triples([{"player", "location", "room1"}, {"player", "health", 100}])
      state2 = State.from_triples([{"player", "location", "room2"}, {"player", "has", "sword"}])
      merged = State.merge(state1, state2)
      assert State.get_fact(merged, "player", "location") == "room2"
      assert State.get_fact(merged, "player", "health") == 100
      assert State.get_fact(merged, "player", "has") == "sword"
    end

    test "copy/1 creates independent copy" do
      original = State.new() |> State.set_fact("player", "location", "room1")
      copied = State.copy(original)
      modified = State.set_fact(copied, "player", "location", "room2")
      assert State.get_fact(original, "player", "location") == "room1"
      assert State.get_fact(modified, "player", "location") == "room2"
    end
  end

  describe("pattern matching and conditions") do
    setup do
      state =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("chair1", "status", "available")
        |> State.set_fact("chair2", "status", "available")
        |> State.set_fact("table1", "status", "occupied")
        |> State.set_fact("door1", "status", "locked")
        |> State.set_fact("door2", "status", "locked")

      {:ok, state: state}
    end

    test("matches?/4 checks exact entity-predicate-value match", %{state: state}) do
      assert State.matches_exactly?(state, "player", "location", "room1") == true
      assert State.matches_exactly?(state, "player", "location", "room2") == false
      assert State.matches_exactly?(state, "unknown", "location", "room1") == false
    end

    test("get_subjects_with_fact/3 finds entities by predicate-value", %{state: state}) do
      available_subjects = State.get_subjects_with_fact(state, "status", "available")
      assert "chair1" in available_subjects
      assert "chair2" in available_subjects
      assert length(available_subjects) == 2
      locked_subjects = State.get_subjects_with_fact(state, "status", "locked")
      assert "door1" in locked_subjects
      assert "door2" in locked_subjects
      assert length(locked_subjects) == 2
    end

    test("get_subjects_with_predicate/2 finds entities by predicate", %{state: state}) do
      subjects_with_status = State.get_subjects_with_predicate(state, "status")
      assert "chair1" in subjects_with_status
      assert "door1" in subjects_with_status
      assert "player" not in subjects_with_status
      assert length(subjects_with_status) == 5
    end

    test("exists?/4 checks existential quantifier with entity-first pattern", %{state: state}) do
      chair_filter = &String.contains?(&1, "chair")
      assert State.exists?(state, chair_filter, "status", "available") == true
      assert State.exists?(state, chair_filter, "status", "locked") == false
      assert State.exists?(state, nil, "location", "room1") == true
      assert State.exists?(state, nil, "location", "room999") == false
    end

    test("forall?/4 checks universal quantifier with entity-first pattern", %{state: state}) do
      door_filter = &String.contains?(&1, "door")
      assert State.forall?(state, door_filter, "status", "locked") == true
      assert State.forall?(state, door_filter, "status", "available") == false
      chair_filter = &String.contains?(&1, "chair")
      assert State.forall?(state, chair_filter, "status", "available") == true
      assert State.forall?(state, chair_filter, "status", "locked") == false
      none_filter = &String.contains?(&1, "nonexistent")
      assert State.forall?(state, none_filter, "status", "anything") == true
    end

    test("evaluate_condition/2 handles different condition formats", %{state: state}) do
      assert State.evaluate_condition(state, {"player", "location", "room1"}) == true
      assert State.evaluate_condition(state, {"player", "location", "room2"}) == false
      chair_filter = &String.contains?(&1, "chair")
      exists_condition = {:exists, chair_filter, "status", "available"}
      assert State.evaluate_condition(state, exists_condition) == true
      door_filter = &String.contains?(&1, "door")
      forall_condition = {:forall, door_filter, "status", "locked"}
      assert State.evaluate_condition(state, forall_condition) == true
      assert State.evaluate_condition(state, {:unknown, "format"}) == false
    end
  end

  describe("legacy conversion") do
    test "from_legacy_state/1 converts old format to new" do
      legacy_data = %{
        {"location", "player"} => "room1",
        {"has", "player"} => "sword",
        {"status", "chair1"} => "available"
      }

      legacy_state = %AriaEngine.State{data: legacy_data}
      state_v2 = State.from_legacy_state(legacy_state)
      assert State.get_fact(state_v2, "player", "location") == "room1"
      assert State.get_fact(state_v2, "player", "has") == "sword"
      assert State.get_fact(state_v2, "chair1", "status") == "available"
    end

    test "to_legacy_state/1 converts new format to old" do
      state_v2 =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("player", "has", "sword")

      legacy_state = State.to_legacy_state(state_v2)
      assert AriaEngine.State.get_fact(legacy_state, "location", "player") == "room1"
      assert AriaEngine.State.get_fact(legacy_state, "has", "player") == "sword"
    end

    test "round-trip conversion preserves data" do
      original =
        State.new()
        |> State.set_fact("player", "location", "room1")
        |> State.set_fact("chair1", "status", "available")

      legacy = State.to_legacy_state(original)
      restored = State.from_legacy_state(legacy)
      assert State.get_fact(restored, "player", "location") == "room1"
      assert State.get_fact(restored, "chair1", "status") == "available"
      assert restored.data == original.data
    end
  end
end