# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.ObjectStateTest do
  use ExUnit.Case
  doctest AriaState.ObjectState

  alias AriaState.ObjectState

  describe "basic operations" do
    test "creates new empty state" do
      state = ObjectState.new()
      assert %ObjectState{data: %{}} = state
    end

    test "sets and gets facts" do
      state = ObjectState.new()
      |> ObjectState.set_fact("chef_1", "status", "cooking")
      |> ObjectState.set_fact("chef_1", "location", "kitchen")

      assert ObjectState.get_fact(state, "chef_1", "status") == "cooking"
      assert ObjectState.get_fact(state, "chef_1", "location") == "kitchen"
      assert ObjectState.get_fact(state, "chef_1", "nonexistent") == nil
    end

    test "pipe-friendly API" do
      state = ObjectState.new()
      |> ObjectState.set_fact("chef_1", "status", "cooking")
      |> ObjectState.set_fact("meal_001", "status", "in_progress")
      |> ObjectState.set_fact("oven_1", "temperature", 375)

      assert ObjectState.get_fact(state, "chef_1", "status") == "cooking"
      assert ObjectState.get_fact(state, "meal_001", "status") == "in_progress"
      assert ObjectState.get_fact(state, "oven_1", "temperature") == 375
    end
  end

  describe "entity queries" do
    setup do
      state = ObjectState.new()
      |> ObjectState.set_fact("chef_1", "status", "available")
      |> ObjectState.set_fact("chef_2", "status", "cooking")
      |> ObjectState.set_fact("chef_3", "status", "available")
      |> ObjectState.set_fact("oven_1", "status", "available")

      {:ok, state: state}
    end

    test "gets subjects with specific fact", %{state: state} do
      available_entities = ObjectState.get_subjects_with_fact(state, "status", "available")
      assert "chef_1" in available_entities
      assert "chef_3" in available_entities
      assert "oven_1" in available_entities
      refute "chef_2" in available_entities
    end

    test "gets subjects with predicate", %{state: state} do
      entities_with_status = ObjectState.get_subjects_with_predicate(state, "status")
      assert "chef_1" in entities_with_status
      assert "chef_2" in entities_with_status
      assert "chef_3" in entities_with_status
      assert "oven_1" in entities_with_status
    end
  end

  describe "condition evaluation" do
    setup do
      state = ObjectState.new()
      |> ObjectState.set_fact("chef_1", "status", "available")
      |> ObjectState.set_fact("chair_1", "status", "available")
      |> ObjectState.set_fact("door_1", "status", "locked")
      |> ObjectState.set_fact("door_2", "status", "locked")

      {:ok, state: state}
    end

    test "evaluates exact matches", %{state: state} do
      assert ObjectState.evaluate_condition(state, {"chef_1", "status", "available"})
      refute ObjectState.evaluate_condition(state, {"chef_1", "status", "cooking"})
    end

    test "evaluates existential conditions", %{state: state} do
      condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
      assert ObjectState.evaluate_condition(state, condition)

      condition = {:exists, &String.contains?(&1, "table"), "status", "available"}
      refute ObjectState.evaluate_condition(state, condition)
    end

    test "evaluates universal conditions", %{state: state} do
      condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
      assert ObjectState.evaluate_condition(state, condition)

      # Add a chef that's not available to make the universal condition false
      state_with_busy_chef = ObjectState.set_fact(state, "chef_2", "status", "cooking")
      condition = {:forall, &String.contains?(&1, "chef"), "status", "available"}
      refute ObjectState.evaluate_condition(state_with_busy_chef, condition)
    end
  end
end
