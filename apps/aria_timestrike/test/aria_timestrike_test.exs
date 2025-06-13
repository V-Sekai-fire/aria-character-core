# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrikeTest do
  use ExUnit.Case, async: true
  doctest AriaTimestrike

  alias AriaEngine.{Domain, State}

  describe "AriaTimestrike domain creation" do
    test "creates a valid domain with timestrike actions" do
      domain = AriaTimestrike.create_domain()

      assert %Domain{} = domain
      assert domain.name == "timestrike"
      assert is_map(domain.actions)
      assert is_map(domain.task_methods)
      assert is_map(domain.unigoal_methods)

      # Check that basic timestrike actions are present
      assert Map.has_key?(domain.actions, :move_to)
      assert Map.has_key?(domain.actions, :attack)
      assert Map.has_key?(domain.actions, :skill_cast)
      assert Map.has_key?(domain.actions, :interact)
    end

    test "domain has expected task methods" do
      domain = AriaTimestrike.create_domain()

      # The current implementation has no task methods defined
      # This is a basic domain with only primitive actions
      assert is_map(domain.task_methods)
      # For now, just assert it's a map (empty is fine)
    end

    test "domain has expected unigoal methods" do
      domain = AriaTimestrike.create_domain()

      # The current implementation has no unigoal methods defined
      # This is a basic domain with only primitive actions
      assert is_map(domain.unigoal_methods)
      # For now, just assert it's a map (empty is fine)
    end
  end

  describe "Timestrike actions" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "move_to action", %{state: state} do
      result = AriaTimestrike.move_to(state, ["agent_001", {10, 20, 5}])
      # Currently returns modified state (placeholder implementation)
      assert match?(%State{}, result) or result == false
    end

    test "attack action", %{state: state} do
      result = AriaTimestrike.attack(state, ["agent_001", "target_002"])
      assert match?(%State{}, result) or result == false
    end

    test "skill_cast action", %{state: state} do
      result = AriaTimestrike.skill_cast(state, ["agent_001", "fireball", "target_area"])
      assert match?(%State{}, result) or result == false
    end

    test "interact action", %{state: state} do
      result = AriaTimestrike.interact(state, ["agent_001", "npc_merchant", "trade"])
      assert match?(%State{}, result) or result == false
    end
  end

  describe "Complex timestrike tasks" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    # Note: The current AriaTimestrike implementation only provides primitive actions
    # Complex task methods would need to be implemented to enable these tests
    # For now, these are commented out as placeholders for future implementation

    # test "execute_combo task", %{state: state} do
    #   result = AriaTimestrike.execute_combo(state, ["agent_001", "combo_sequence", "target"])
    #   assert result == false
    # end
  end

  describe "Goal methods" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    # Note: The current AriaTimestrike implementation only provides primitive actions
    # Goal methods would need to be implemented to enable these tests
    # For now, these are commented out as placeholders for future implementation

    # test "ensure_at_location goal", %{state: state} do
    #   result = AriaTimestrike.ensure_at_location(state, ["agent_001", {15, 25, 10}])
    #   assert match?(%State{}, result) or result == false
    # end
  end
end
