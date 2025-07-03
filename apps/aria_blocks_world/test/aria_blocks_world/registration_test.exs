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

    test "provides complete domain information" do
      info = Domain.info()

      assert info.name == "Blocks World Domain"
      assert is_binary(info.description)
      assert is_list(info.actions)
      assert is_list(info.task_methods)
      assert is_list(info.multigoal_methods)
      assert is_list(info.predicates)
      assert is_list(info.entities)
      assert is_list(info.capabilities)

      # Verify key components are present
      assert :pickup in info.actions
      assert :unstack in info.actions
      assert :putdown in info.actions
      assert :stack in info.actions
      assert :take in info.actions

      assert "move_block" in info.task_methods
      assert "take" in info.task_methods
      assert "put" in info.task_methods

      assert "split_multigoal" in info.multigoal_methods

      assert "pos" in info.predicates
      assert "clear" in info.predicates
      assert "holding" in info.predicates
    end

    test "registers actions through attribute system" do
      domain = Domain.create()
      actions = AriaCore.list_actions_in_domain(domain)

      # Verify all expected actions are registered
      expected_actions = [:pickup, :unstack, :putdown, :stack, :take, :setup_blocks_scenario]

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

    test "task method execution works through registration", %{state: state} do
      # Test take_method for block 'c' (should work since c is clear and on block 'a')
      assert {:ok, actions} = Domain.take_method(state, ["c"])
      assert actions == [{:unstack, ["c", "a"]}]

      # Test take_method for block 'a' (should fail since a is not clear)
      assert {:error, :block_not_clear} = Domain.take_method(state, ["a"])

      # Test take_method for block 'b' (should work since b is clear and on table)
      assert {:ok, actions} = Domain.take_method(state, ["b"])
      assert actions == [{:pickup, ["b"]}]
    end

    test "task method error handling works through registration", %{state: state} do
      # Test take_method for block that's not clear
      state_with_blocked = AriaHybridPlanner.set_fact(state, "clear", "a", false)
      assert {:error, :block_not_clear} = Domain.take_method(state_with_blocked, ["a"])

      # Test put_method when hand is empty (should fail)
      assert {:error, :not_holding_block} = Domain.put_method(state, ["c", "table"])
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

    test "validate_move task method", %{state: state} do
      # For now, validate_move always succeeds (returns empty action list)
      assert {:ok, []} = Domain.validate_move(state, ["c", "table"])
      assert {:ok, []} = Domain.validate_move(state, ["b", "a"])
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
      assert actions == [
        {:validate_move, ["b", "table"]},
        {:move_block, ["b", "table"]}
      ]
    end

    test "achieve_clear unigoal method works", %{state: state} do
      # Test when block is already clear
      assert {:ok, []} = Domain.achieve_clear(state, {"b", true})

      # Test when block needs to be cleared
      assert {:ok, actions} = Domain.achieve_clear(state, {"a", true})
      assert actions == [
        {:validate_move, ["b", "table"]},
        {:move_block, ["b", "table"]}
      ]

      # Test achieve_clear false (should return empty - cannot directly make not clear)
      assert {:ok, []} = Domain.achieve_clear(state, {"b", false})
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

    test "domain info matches actual registration" do
      domain = Domain.create()
      info = Domain.info()

      # Get actual registered actions
      registered_actions = AriaCore.list_actions_in_domain(domain)

      # Verify info actions are subset of registered actions
      for action <- info.actions do
        assert action in registered_actions,
               "Info action #{action} should be in registered actions"
      end
    end
  end
end
