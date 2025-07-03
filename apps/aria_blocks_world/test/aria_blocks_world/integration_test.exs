# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.IntegrationTest do
  @moduledoc """
  Test suite for integration scenarios and component interactions.

  This test suite validates that the AriaBlocksWorld domain integrates properly
  with the planning system and that complex multi-step scenarios work correctly.
  """

  use ExUnit.Case, async: true

  alias AriaBlocksWorld.Domain
  alias AriaHybridPlanner
  alias AriaEngineCore.Multigoal

  describe "domain and planner integration" do
    test "domain creation integrates with planner" do
      domain = Domain.create()
      state = AriaHybridPlanner.new_state()

      # Verify domain can be used with planner state
      assert is_struct(domain)
      assert is_struct(state)

      # Test that domain actions work with planner state
      state_with_block = state
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      assert {:ok, _new_state} = Domain.pickup(state_with_block, ["a"])
    end

    test "entity registration integrates with state management" do
      state = AriaHybridPlanner.new_state()

      # Test entity setup action
      assert {:ok, new_state} = Domain.setup_blocks_scenario(state, [])

      # Verify entities are properly registered in state
      assert AriaHybridPlanner.get_fact(new_state, "type", "hand") == "agent"
      assert AriaHybridPlanner.get_fact(new_state, "type", "table") == "surface"
      assert AriaHybridPlanner.get_fact(new_state, "capabilities", "hand") == [:manipulation]
      assert AriaHybridPlanner.get_fact(new_state, "capabilities", "table") == [:support]
    end

    test "action execution preserves state consistency" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Execute unstack action
      assert {:ok, state1} = Domain.unstack(state, ["b", "a"])

      # Verify state consistency after action
      assert AriaHybridPlanner.get_fact(state1, "pos", "b") == "hand"
      assert AriaHybridPlanner.get_fact(state1, "clear", "b") == false
      assert AriaHybridPlanner.get_fact(state1, "holding", "hand") == "b"
      assert AriaHybridPlanner.get_fact(state1, "clear", "a") == true

      # Execute putdown action
      assert {:ok, state2} = Domain.putdown(state1, ["b"])

      # Verify final state consistency
      assert AriaHybridPlanner.get_fact(state2, "pos", "b") == "table"
      assert AriaHybridPlanner.get_fact(state2, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(state2, "holding", "hand") == false
    end
  end

  describe "complex multi-step scenarios" do
    setup do
      # Complex initial state: tower of 4 blocks
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("pos", "c", "b")
      |> AriaHybridPlanner.set_fact("pos", "d", "c")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", false)
      |> AriaHybridPlanner.set_fact("clear", "c", false)
      |> AriaHybridPlanner.set_fact("clear", "d", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "dismantling a tower step by step", %{state: state} do
      # Step 1: Remove d from c
      assert {:ok, state1} = Domain.unstack(state, ["d", "c"])
      assert AriaHybridPlanner.get_fact(state1, "pos", "d") == "hand"
      assert AriaHybridPlanner.get_fact(state1, "clear", "c") == true
      assert AriaHybridPlanner.get_fact(state1, "holding", "hand") == "d"

      # Step 2: Put d on table
      assert {:ok, state2} = Domain.putdown(state1, ["d"])
      assert AriaHybridPlanner.get_fact(state2, "pos", "d") == "table"
      assert AriaHybridPlanner.get_fact(state2, "clear", "d") == true
      assert AriaHybridPlanner.get_fact(state2, "holding", "hand") == false

      # Step 3: Remove c from b
      assert {:ok, state3} = Domain.unstack(state2, ["c", "b"])
      assert AriaHybridPlanner.get_fact(state3, "pos", "c") == "hand"
      assert AriaHybridPlanner.get_fact(state3, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(state3, "holding", "hand") == "c"

      # Step 4: Put c on table
      assert {:ok, state4} = Domain.putdown(state3, ["c"])
      assert AriaHybridPlanner.get_fact(state4, "pos", "c") == "table"
      assert AriaHybridPlanner.get_fact(state4, "clear", "c") == true
      assert AriaHybridPlanner.get_fact(state4, "holding", "hand") == false

      # Step 5: Remove b from a
      assert {:ok, state5} = Domain.unstack(state4, ["b", "a"])
      assert AriaHybridPlanner.get_fact(state5, "pos", "b") == "hand"
      assert AriaHybridPlanner.get_fact(state5, "clear", "a") == true
      assert AriaHybridPlanner.get_fact(state5, "holding", "hand") == "b"

      # Step 6: Put b on table
      assert {:ok, final_state} = Domain.putdown(state5, ["b"])
      assert AriaHybridPlanner.get_fact(final_state, "pos", "b") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(final_state, "holding", "hand") == false

      # Verify all blocks are on table and clear
      assert AriaHybridPlanner.get_fact(final_state, "pos", "a") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "pos", "b") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "pos", "c") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "pos", "d") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "clear", "a") == true
      assert AriaHybridPlanner.get_fact(final_state, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(final_state, "clear", "c") == true
      assert AriaHybridPlanner.get_fact(final_state, "clear", "d") == true
    end

    test "building a new tower from dismantled blocks" do
      # Start with all blocks on table
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("pos", "c", "table")
      |> AriaHybridPlanner.set_fact("pos", "d", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("clear", "d", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Build tower: d on c on b on a
      # Step 1: Pick up d
      assert {:ok, state1} = Domain.pickup(state, ["d"])
      assert AriaHybridPlanner.get_fact(state1, "holding", "hand") == "d"

      # Step 2: Stack d on c
      assert {:ok, state2} = Domain.stack(state1, ["d", "c"])
      assert AriaHybridPlanner.get_fact(state2, "pos", "d") == "c"
      assert AriaHybridPlanner.get_fact(state2, "clear", "c") == false
      assert AriaHybridPlanner.get_fact(state2, "clear", "d") == true

      # Step 3: Pick up c (with d on top)
      assert {:ok, state3} = Domain.unstack(state2, ["d", "c"])
      assert {:ok, state3b} = Domain.putdown(state3, ["d"])
      assert {:ok, state3c} = Domain.pickup(state3b, ["c"])
      assert AriaHybridPlanner.get_fact(state3c, "holding", "hand") == "c"

      # Step 4: Stack c on b
      assert {:ok, state4} = Domain.stack(state3c, ["c", "b"])
      assert AriaHybridPlanner.get_fact(state4, "pos", "c") == "b"
      assert AriaHybridPlanner.get_fact(state4, "clear", "b") == false

      # Step 5: Pick up b (with c on top) - need to clear first
      assert {:ok, state5} = Domain.pickup(state4, ["d"])
      assert {:ok, state5b} = Domain.stack(state5, ["d", "c"])
      assert {:ok, state5c} = Domain.unstack(state5b, ["d", "c"])
      assert {:ok, state5d} = Domain.putdown(state5c, ["d"])
      assert {:ok, state5e} = Domain.unstack(state5d, ["c", "b"])
      assert {:ok, state5f} = Domain.putdown(state5e, ["c"])
      assert {:ok, state5g} = Domain.pickup(state5f, ["b"])
      assert AriaHybridPlanner.get_fact(state5g, "holding", "hand") == "b"

      # Step 6: Stack b on a
      assert {:ok, final_state} = Domain.stack(state5g, ["b", "a"])
      assert AriaHybridPlanner.get_fact(final_state, "pos", "b") == "a"
      assert AriaHybridPlanner.get_fact(final_state, "clear", "a") == false
      assert AriaHybridPlanner.get_fact(final_state, "clear", "b") == true
    end
  end

  describe "method integration scenarios" do
    setup do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("pos", "c", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "task method decomposition and execution", %{state: state} do
      # Test move_block method decomposition
      assert {:ok, actions} = Domain.move_block(state, ["b", "c"])
      assert actions == [{:unstack, ["b", "a"]}, {:stack, ["b", "c"]}]

      # Execute the decomposed actions
      assert {:ok, state1} = Domain.unstack(state, ["b", "a"])
      assert {:ok, final_state} = Domain.stack(state1, ["b", "c"])

      # Verify final state
      assert AriaHybridPlanner.get_fact(final_state, "pos", "b") == "c"
      assert AriaHybridPlanner.get_fact(final_state, "clear", "a") == true
      assert AriaHybridPlanner.get_fact(final_state, "clear", "c") == false
      assert AriaHybridPlanner.get_fact(final_state, "clear", "b") == true
    end

    test "unigoal method goal achievement", %{state: state} do
      # Test achieve_position method
      assert {:ok, actions} = Domain.achieve_position(state, {"b", "c"})
      assert actions == [{:unstack, ["b", "a"]}, {:stack, ["b", "c"]}]

      # Test achieve_clear method
      assert {:ok, clear_actions} = Domain.achieve_clear(state, {"a", true})
      assert clear_actions == [
        {:move_block, ["b", "table"]}
      ]
    end

    test "multigoal method decomposition", %{state: state} do
      # Create multigoal with mixed satisfied/unsatisfied goals
      multigoal = Multigoal.new([
        {"pos", "a", "table"},    # satisfied
        {"pos", "b", "c"},        # unsatisfied
        {"clear", "c", true}      # satisfied
      ])

      assert {:ok, todo_list} = Domain.split_multigoal(state, multigoal)

      # Should return unsatisfied goals plus original multigoal
      expected_unsatisfied = [{"pos", "b", "c"}]
      unigoals = Enum.take(todo_list, length(todo_list) - 1)
      final_multigoal = List.last(todo_list)

      assert unigoals == expected_unsatisfied
      assert final_multigoal == multigoal
    end
  end

  describe "state consistency across operations" do
    test "complex state transitions maintain consistency" do
      # Start with simple state
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Perform sequence: pickup a, stack a on b, unstack a from b, putdown a
      assert {:ok, state1} = Domain.pickup(state, ["a"])

      # Verify intermediate state
      assert AriaHybridPlanner.get_fact(state1, "pos", "a") == "hand"
      assert AriaHybridPlanner.get_fact(state1, "clear", "a") == false
      assert AriaHybridPlanner.get_fact(state1, "holding", "hand") == "a"

      assert {:ok, state2} = Domain.stack(state1, ["a", "b"])

      # Verify intermediate state
      assert AriaHybridPlanner.get_fact(state2, "pos", "a") == "b"
      assert AriaHybridPlanner.get_fact(state2, "clear", "a") == true
      assert AriaHybridPlanner.get_fact(state2, "clear", "b") == false
      assert AriaHybridPlanner.get_fact(state2, "holding", "hand") == false

      assert {:ok, state3} = Domain.unstack(state2, ["a", "b"])

      # Verify intermediate state
      assert AriaHybridPlanner.get_fact(state3, "pos", "a") == "hand"
      assert AriaHybridPlanner.get_fact(state3, "clear", "a") == false
      assert AriaHybridPlanner.get_fact(state3, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(state3, "holding", "hand") == "a"

      assert {:ok, final_state} = Domain.putdown(state3, ["a"])

      # Verify final state matches initial state
      assert AriaHybridPlanner.get_fact(final_state, "pos", "a") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "pos", "b") == "table"
      assert AriaHybridPlanner.get_fact(final_state, "clear", "a") == true
      assert AriaHybridPlanner.get_fact(final_state, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(final_state, "holding", "hand") == false
    end

    test "concurrent block operations maintain independence" do
      # State with multiple independent blocks
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("pos", "c", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Operation on block a should not affect blocks b and c
      assert {:ok, state1} = Domain.pickup(state, ["a"])

      # Verify b and c are unchanged
      assert AriaHybridPlanner.get_fact(state1, "pos", "b") == "table"
      assert AriaHybridPlanner.get_fact(state1, "pos", "c") == "table"
      assert AriaHybridPlanner.get_fact(state1, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(state1, "clear", "c") == true

      # Stack a on b should affect both a and b but not c
      assert {:ok, state2} = Domain.stack(state1, ["a", "b"])

      # Verify c is still unchanged
      assert AriaHybridPlanner.get_fact(state2, "pos", "c") == "table"
      assert AriaHybridPlanner.get_fact(state2, "clear", "c") == true

      # Verify a and b are correctly updated
      assert AriaHybridPlanner.get_fact(state2, "pos", "a") == "b"
      assert AriaHybridPlanner.get_fact(state2, "clear", "b") == false
    end
  end

  describe "performance and scalability" do
    test "handles large number of blocks efficiently" do
      # Create state with many blocks
      num_blocks = 50
      block_names = for i <- 1..num_blocks, do: "block_#{i}"

      state = Enum.reduce(block_names, AriaHybridPlanner.new_state(), fn block, acc ->
        acc
        |> AriaHybridPlanner.set_fact("pos", block, "table")
        |> AriaHybridPlanner.set_fact("clear", block, true)
      end)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Test that operations work with many blocks
      first_block = "block_1"
      second_block = "block_2"

      assert {:ok, state1} = Domain.pickup(state, [first_block])
      assert {:ok, state2} = Domain.stack(state1, [first_block, second_block])

      # Verify operation succeeded
      assert AriaHybridPlanner.get_fact(state2, "pos", first_block) == second_block
      assert AriaHybridPlanner.get_fact(state2, "clear", second_block) == false

      # Verify other blocks are unaffected
      for i <- 3..num_blocks do
        block = "block_#{i}"
        assert AriaHybridPlanner.get_fact(state2, "pos", block) == "table"
        assert AriaHybridPlanner.get_fact(state2, "clear", block) == true
      end
    end

    test "handles deep tower efficiently" do
      # Create a deep tower (20 blocks high)
      num_blocks = 20
      block_names = for i <- 1..num_blocks, do: "block_#{i}"

      # Build tower: block_1 on table, block_2 on block_1, etc.
      state = Enum.reduce(Enum.with_index(block_names), AriaHybridPlanner.new_state(), fn {block, index}, acc ->
        pos = if index == 0, do: "table", else: "block_#{index}"
        clear = index == num_blocks - 1  # Only top block is clear

        acc
        |> AriaHybridPlanner.set_fact("pos", block, pos)
        |> AriaHybridPlanner.set_fact("clear", block, clear)
      end)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Test operations on deep tower
      top_block = "block_#{num_blocks}"

      # Should be able to unstack from top
      assert {:ok, state1} = Domain.unstack(state, [top_block, "block_#{num_blocks - 1}"])
      assert AriaHybridPlanner.get_fact(state1, "pos", top_block) == "hand"
      assert AriaHybridPlanner.get_fact(state1, "clear", "block_#{num_blocks - 1}") == true

      # Should be able to put it back
      assert {:ok, state2} = Domain.stack(state1, [top_block, "block_#{num_blocks - 1}"])
      assert AriaHybridPlanner.get_fact(state2, "pos", top_block) == "block_#{num_blocks - 1}"
      assert AriaHybridPlanner.get_fact(state2, "clear", "block_#{num_blocks - 1}") == false
    end
  end

  describe "error recovery and robustness" do
    test "recovers from failed operations gracefully" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Attempt invalid operation
      assert {:error, :block_not_clear} = Domain.pickup(state, ["a"])

      # State should be unchanged after failed operation
      assert AriaHybridPlanner.get_fact(state, "pos", "a") == "table"
      assert AriaHybridPlanner.get_fact(state, "pos", "b") == "a"
      assert AriaHybridPlanner.get_fact(state, "clear", "a") == false
      assert AriaHybridPlanner.get_fact(state, "clear", "b") == true
      assert AriaHybridPlanner.get_fact(state, "holding", "hand") == false

      # Valid operation should still work
      assert {:ok, new_state} = Domain.unstack(state, ["b", "a"])
      assert AriaHybridPlanner.get_fact(new_state, "pos", "b") == "hand"
      assert AriaHybridPlanner.get_fact(new_state, "clear", "a") == true
    end

    test "handles mixed valid and invalid operations" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Valid operation
      assert {:ok, state1} = Domain.pickup(state, ["a"])

      # Invalid operation (hand not empty)
      assert {:error, :hand_not_empty} = Domain.pickup(state1, ["b"])

      # State should reflect only the valid operation
      assert AriaHybridPlanner.get_fact(state1, "pos", "a") == "hand"
      assert AriaHybridPlanner.get_fact(state1, "pos", "b") == "table"
      assert AriaHybridPlanner.get_fact(state1, "holding", "hand") == "a"

      # Another valid operation should work
      assert {:ok, state2} = Domain.stack(state1, ["a", "b"])
      assert AriaHybridPlanner.get_fact(state2, "pos", "a") == "b"
      assert AriaHybridPlanner.get_fact(state2, "clear", "b") == false
    end
  end
end
