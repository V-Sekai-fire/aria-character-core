# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.RegistrationTest do
  @moduledoc """
  Test suite for domain registration and attribute-based functionality.

  This test suite validates that the AriaBlocksWorld domain properly registers
  actions, task methods, and unigoal methods using the attribute-based system.
  """

  use ExUnit.Case, async: true
  doctest AriaBlocksWorld.Domain

  alias AriaBlocksWorld.Domain
  alias AriaHybridPlanner

  describe "domain creation and registration" do
    test "creates domain successfully with proper structure" do
      domain = Domain.create()

      assert is_struct(domain)
      assert domain.name == :blocks_world
    end

    test "registers actions through attribute system" do
      domain = Domain.create()
      actions = AriaCore.list_actions_in_domain(domain)

      # Verify all expected actions are registered
      expected_actions = [:pickup, :unstack, :putdown, :stack, :setup_blocks_scenario]

      for action <- expected_actions do
        assert action in actions, "Action #{action} should be registered"
      end
    end

    test "registers task methods through attribute system" do
      domain = Domain.create()
      method_counts = AriaCore.get_method_counts_from_domain(domain)

      # Verify task methods are registered (check count > 0)
      assert method_counts.task_methods > 0
      assert method_counts.multigoal_methods > 0
      assert method_counts.unigoal_methods > 0
    end
  end

  describe "attribute-based registration validation" do
    setup do
      # Create a standard test state
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("pos", "c", "a")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "task method execution with valid holding state", %{state: state} do
      # Test put_method with block in hand
      state_with_block = AriaHybridPlanner.set_fact(state, "holding", "hand", "c")

      # Should work for putting on table
      assert {:ok, actions} = Domain.put_method(state_with_block, ["c", "table"])
      assert actions == [{:putdown, ["c"]}]

      # Should work for stacking on another block
      assert {:ok, actions} = Domain.put_method(state_with_block, ["c", "b"])
      assert actions == [{:stack, ["c", "b"]}]
    end

    test "move_block task method decomposition", %{state: state} do
      # Test moving from table to table
      assert {:ok, actions} = Domain.move_block(state, ["b", "table"])
      assert actions == [{:pickup, ["b"]}, {:putdown, ["b"]}]

      # Test moving from table to block
      assert {:ok, actions} = Domain.move_block(state, ["b", "a"])
      assert actions == [{:pickup, ["b"]}, {:stack, ["b", "a"]}]

      # Test moving from block to table
      assert {:ok, actions} = Domain.move_block(state, ["c", "table"])
      assert actions == [{:unstack, ["c", "a"]}, {:putdown, ["c"]}]

      # Test moving from block to block
      assert {:ok, actions} = Domain.move_block(state, ["c", "b"])
      assert actions == [{:unstack, ["c", "a"]}, {:stack, ["c", "b"]}]
    end
  end

  describe "unigoal method registration" do
    setup do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "achieve_position unigoal method works", %{state: state} do
      # Test when goal is already satisfied
      assert {:ok, []} = Domain.achieve_position(state, {"a", "table"})

      # Test when goal requires action
      assert {:ok, actions} = Domain.achieve_position(state, {"b", "table"})
      assert actions == [{:unstack, ["b", "a"]}, {:putdown, ["b"]}]
    end
  end

  describe "entity registration" do
    test "setup_blocks_scenario registers entities" do
      state = AriaHybridPlanner.new_state()

      assert {:ok, new_state} = Domain.setup_blocks_scenario(state, [])

      # Verify hand entity is registered
      assert AriaHybridPlanner.get_fact(new_state, "type", "hand") == "agent"
      assert AriaHybridPlanner.get_fact(new_state, "capabilities", "hand") == [:manipulation]
      assert AriaHybridPlanner.get_fact(new_state, "status", "hand") == "available"

      # Verify table entity is registered
      assert AriaHybridPlanner.get_fact(new_state, "type", "table") == "surface"
      assert AriaHybridPlanner.get_fact(new_state, "capabilities", "table") == [:support]
      assert AriaHybridPlanner.get_fact(new_state, "status", "table") == "available"
    end
  end

  describe "domain consistency" do
    test "all registered actions are callable" do
      domain = Domain.create()
      actions = AriaCore.list_actions_in_domain(domain)
      _state = AriaHybridPlanner.new_state()

      # Verify each action function exists and is callable
      for action <- actions do
        assert function_exported?(Domain, action, 2),
               "Action #{action} should be exported with arity 2"
      end
    end
  end
end
