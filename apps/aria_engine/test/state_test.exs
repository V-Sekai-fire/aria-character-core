# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StateTest do
  use ExUnit.Case
  doctest AriaEngine.State

  alias AriaEngine.State

  describe "State management" do
    test "creates and manages state with predicate-subject-object triples" do
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("has", "player", "sword")
      |> AriaEngine.set_fact("health", "player", 100)

      assert AriaEngine.get_fact(state, "location", "player") == "room1"
      assert AriaEngine.get_fact(state, "has", "player") == "sword"
      assert AriaEngine.get_fact(state, "health", "player") == 100
      assert AriaEngine.get_fact(state, "missing", "player") == nil
    end

    test "converts state to and from triples" do
      original_triples = [
        {"location", "player", "room1"},
        {"has", "player", "sword"},
        {"health", "player", 100}
      ]

      state = AriaEngine.state_from_triples(original_triples)
      converted_triples = AriaEngine.state_to_triples(state)

      # Sort both lists for comparison since order might differ
      assert Enum.sort(converted_triples) == Enum.sort(original_triples)
    end

    test "merges states correctly" do
      state1 = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("has", "player", "sword")

      state2 = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room2")  # Conflict - should take precedence
      |> AriaEngine.set_fact("health", "player", 100)       # New fact

      merged = AriaEngine.merge_states(state1, state2)

      assert AriaEngine.get_fact(merged, "location", "player") == "room2"  # From state2
      assert AriaEngine.get_fact(merged, "has", "player") == "sword"       # From state1
      assert AriaEngine.get_fact(merged, "health", "player") == 100        # From state2
    end

    test "direct State module interface" do
      state = State.new()
      |> State.set_object("position", "robot", "kitchen")
      |> State.set_object("battery", "robot", 85)

      assert State.get_object(state, "position", "robot") == "kitchen"
      assert State.get_object(state, "battery", "robot") == 85
      assert State.get_object(state, "missing", "robot") == nil
    end
  end
end
