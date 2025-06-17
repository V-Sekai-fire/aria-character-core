# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StateTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.State

  alias AriaEngine.State

  describe "basic state operations" do
    test "creates empty state" do
      state = State.new()
      assert state.data == %{}
    end

    test "creates state with initial data" do
      initial_data = %{{"location", "player"} => "room1", {"health", "player"} => 100}
      state = State.new(initial_data)
      assert state.data == initial_data
    end

    test "sets and gets objects" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)

      assert State.get_object(state, "location", "player") == "room1"
      assert State.get_object(state, "health", "player") == 100
      assert State.get_object(state, "nonexistent", "player") == nil
    end

    test "removes objects" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.remove_object("location", "player")

      assert State.get_object(state, "location", "player") == nil
    end

    test "checks if subject has predicate" do
      state = State.new()
      |> State.set_object("location", "player", "room1")

      assert State.has_subject?(state, "location", "player")
      refute State.has_subject?(state, "health", "player")
    end

    test "checks if subject variable exists" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)
      |> State.set_object("location", "npc", "room2")

      assert State.has_subject_variable?(state, "player")
      assert State.has_subject_variable?(state, "npc")
      refute State.has_subject_variable?(state, "monster")
    end

    test "gets all subjects" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)
      |> State.set_object("location", "npc", "room2")

      subjects = State.get_subjects(state)
      assert Enum.sort(subjects) == ["npc", "player"]
    end

    test "gets all predicates for a given subject" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)
      |> State.set_object("inventory", "player", "sword")

      predicates = State.get_subject_properties(state, "player")
      assert Enum.sort(predicates) == ["health", "inventory", "location"]
    end
  end

  describe "triple conversion" do
    test "converts state to triples" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)

      triples = State.to_triples(state)
      assert length(triples) == 2
      assert {"location", "player", "room1"} in triples
      assert {"health", "player", 100} in triples
    end

    test "creates state from triples" do
      triples = [
        {"location", "player", "room1"},
        {"health", "player", 100}
      ]
      state = State.from_triples(triples)

      assert State.get_object(state, "location", "player") == "room1"
      assert State.get_object(state, "health", "player") == 100
    end
  end

  describe "state merging" do
    test "merges two states" do
      state1 = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)

      state2 = State.new()
      |> State.set_object("location", "player", "room2") # Overwrites
      |> State.set_object("mana", "player", 50)

      merged_state = State.merge(state1, state2)

      assert State.get_object(merged_state, "location", "player") == "room2"
      assert State.get_object(merged_state, "health", "player") == 100
      assert State.get_object(merged_state, "mana", "player") == 50
    end
  end

  describe "state copying" do
    test "creates a copy of the state" do
      original_state = State.new()
      |> State.set_object("location", "player", "room1")

      copied_state = State.copy(original_state)

      assert copied_state.data == original_state.data
      # The next test "modifying copy does not affect original" already verifies immutability.
      # refute copied_state == original_state # This assertion can be overly strict for struct equality in Elixir
    end

    test "modifying copy does not affect original" do
      original_state = State.new()
      |> State.set_object("location", "player", "room1")

      copied_state = State.copy(original_state)
      copied_state = State.set_object(copied_state, "location", "player", "room2")

      assert State.get_object(original_state, "location", "player") == "room1"
      assert State.get_object(copied_state, "location", "player") == "room2"
    end
  end

  describe "matching" do
    test "matches? returns true for matching triple" do
      state = State.new()
      |> State.set_object("location", "player", "room1")

      assert State.matches?(state, "location", "player", "room1")
    end

    test "matches? returns false for non-matching object" do
      state = State.new()
      |> State.set_object("location", "player", "room1")

      refute State.matches?(state, "location", "player", "room2")
    end

    test "matches? returns false for non-matching predicate" do
      state = State.new()
      |> State.set_object("location", "player", "room1")

      refute State.matches?(state, "has", "player", "room1")
    end

    test "matches? returns false for non-matching subject" do
      state = State.new()
      |> State.set_object("location", "player", "room1")

      refute State.matches?(state, "location", "npc", "room1")
    end

    test "matches? returns false for nonexistent triple" do
      state = State.new()

      refute State.matches?(state, "location", "player", "room1")
    end
  end
end
