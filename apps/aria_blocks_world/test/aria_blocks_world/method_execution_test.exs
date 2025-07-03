# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.MethodExecutionTest do
  @moduledoc """
  Test suite for comprehensive method execution validation.

  This test suite validates the execution behavior of task methods, unigoal methods,
  and multigoal methods under various state conditions and scenarios.
  """

  use ExUnit.Case, async: true

  alias AriaBlocksWorld.Domain
  alias AriaHybridPlanner
  alias AriaEngineCore.Multigoal

  describe "task method execution scenarios" do
    setup do
      # Complex state with multiple blocks in various configurations
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("pos", "c", "b")
      |> AriaHybridPlanner.set_fact("pos", "d", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", false)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("clear", "d", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "take_method handles various block positions", %{state: state} do
      # Test taking from top of stack (clear block on another block)
      assert {:ok, actions} = Domain.take_method(state, ["c"])
      assert actions == [{:unstack, ["c", "b"]}]

      # Test taking from table (clear block on table)
      assert {:ok, actions} = Domain.take_method(state, ["d"])
      assert actions == [{:pickup, ["d"]}]

      # Test taking blocked block (should fail)
      assert {:error, :block_not_clear} = Domain.take_method(state, ["b"])
      assert {:error, :block_not_clear} = Domain.take_method(state, ["a"])
    end

    test "put_method handles various destinations", %{state: state} do
      # Set up state with block in hand
      state_holding_c = AriaHybridPlanner.set_fact(state, "holding", "hand", "c")
      |> AriaHybridPlanner.set_fact("pos", "c", "hand")
      |> AriaHybridPlanner.set_fact("clear", "b", true)  # c is no longer on b

      # Test putting on table
      assert {:ok, actions} = Domain.put_method(state_holding_c, ["c", "table"])
      assert actions == [{:putdown, ["c"]}]

      # Test stacking on clear block
      assert {:ok, actions} = Domain.put_method(state_holding_c, ["c", "d"])
      assert actions == [{:stack, ["c", "d"]}]

      # Test stacking on another clear block
      assert {:ok, actions} = Domain.put_method(state_holding_c, ["c", "b"])
      assert actions == [{:stack, ["c", "b"]}]

      # Test error when not holding the block
      assert {:error, :not_holding_block} = Domain.put_method(state, ["c", "table"])
    end

    test "move_block decomposes complex movements", %{state: state} do
      # Test all four movement patterns

      # From table to table (pickup + putdown)
      assert {:ok, actions} = Domain.move_block(state, ["d", "table"])
      assert actions == [{:pickup, ["d"]}, {:putdown, ["d"]}]

      # From table to block (pickup + stack)
      assert {:ok, actions} = Domain.move_block(state, ["d", "a"])
      assert actions == [{:pickup, ["d"]}, {:stack, ["d", "a"]}]

      # From block to table (unstack + putdown)
      assert {:ok, actions} = Domain.move_block(state, ["c", "table"])
      assert actions == [{:unstack, ["c", "b"]}, {:putdown, ["c"]}]

      # From block to block (unstack + stack)
      assert {:ok, actions} = Domain.move_block(state, ["c", "d"])
      assert actions == [{:unstack, ["c", "b"]}, {:stack, ["c", "d"]}]
    end

    test "validate_move_preconditions task method", %{state: state} do
      # Test validation decomposition
      assert {:ok, goals} = Domain.validate_move_preconditions(state, ["c", "table"])

      expected_goals = [
        {"accessible", "c", true},
        {"destination_available", "table", true},
        {"no_cyclic_dependency", {"c", "table"}, true}
      ]

      assert goals == expected_goals
    end

    test "validate_move always succeeds for now", %{state: state} do
      # Current implementation always returns empty (no validation)
      assert {:ok, []} = Domain.validate_move(state, ["c", "table"])
      assert {:ok, []} = Domain.validate_move(state, ["d", "a"])
      assert {:ok, []} = Domain.validate_move(state, ["nonexistent", "nowhere"])
    end
  end

  describe "unigoal method execution scenarios" do
    setup do
      # State with tower: c on b on a on table, d separate on table
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("pos", "c", "b")
      |> AriaHybridPlanner.set_fact("pos", "d", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", false)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("clear", "d", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "achieve_position handles satisfied goals", %{state: state} do
      # Test goals that are already satisfied
      assert {:ok, []} = Domain.achieve_position(state, {"a", "table"})
      assert {:ok, []} = Domain.achieve_position(state, {"b", "a"})
      assert {:ok, []} = Domain.achieve_position(state, {"c", "b"})
      assert {:ok, []} = Domain.achieve_position(state, {"d", "table"})
    end

    test "achieve_position handles unsatisfied goals", %{state: state} do
      # Test goals that require action
      assert {:ok, actions} = Domain.achieve_position(state, {"c", "table"})
      assert actions == [
        {:validate_move, ["c", "table"]},
        {:move_block, ["c", "table"]}
      ]

      assert {:ok, actions} = Domain.achieve_position(state, {"b", "d"})
      assert actions == [
        {:validate_move, ["b", "d"]},
        {:move_block, ["b", "d"]}
      ]

      assert {:ok, actions} = Domain.achieve_position(state, {"a", "d"})
      assert actions == [
        {:validate_move, ["a", "d"]},
        {:move_block, ["a", "d"]}
      ]
    end

    test "achieve_clear handles already clear blocks", %{state: state} do
      # Test blocks that are already clear
      assert {:ok, []} = Domain.achieve_clear(state, {"c", true})
      assert {:ok, []} = Domain.achieve_clear(state, {"d", true})
    end

    test "achieve_clear handles blocked blocks", %{state: state} do
      # Test clearing block b (c is on top)
      assert {:ok, actions} = Domain.achieve_clear(state, {"b", true})
      assert actions == [
        {:validate_move, ["c", "table"]},
        {:move_block, ["c", "table"]}
      ]

      # Test clearing block a (b is on top, but b has c on top)
      assert {:ok, actions} = Domain.achieve_clear(state, {"a", true})
      assert actions == [
        {:validate_move, ["b", "table"]},
        {:move_block, ["b", "table"]}
      ]
    end

    test "achieve_clear false returns empty", %{state: state} do
      # Cannot directly make blocks not clear
      assert {:ok, []} = Domain.achieve_clear(state, {"c", false})
      assert {:ok, []} = Domain.achieve_clear(state, {"d", false})
    end
  end

  describe "multigoal method execution scenarios" do
    setup do
      # Simple initial state for multigoal testing
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("pos", "c", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("clear", "c", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "split_multigoal handles satisfied multigoals", %{state: state} do
      # Create multigoal that's already satisfied
      satisfied_multigoal = Multigoal.new([
        {"pos", "a", "table"},
        {"pos", "b", "table"},
        {"clear", "a", true}
      ])

      assert {:ok, []} = Domain.split_multigoal(state, satisfied_multigoal)
    end

    test "split_multigoal handles unsatisfied multigoals", %{state: state} do
      # Create multigoal with some unsatisfied goals
      unsatisfied_multigoal = Multigoal.new([
        {"pos", "a", "table"},      # satisfied
        {"pos", "b", "a"},          # unsatisfied
        {"pos", "c", "b"},          # unsatisfied
        {"clear", "c", true}        # satisfied
      ])

      assert {:ok, todo_list} = Domain.split_multigoal(state, unsatisfied_multigoal)

      # Should return unsatisfied goals plus original multigoal
      expected_unsatisfied = [
        {"pos", "b", "a"},
        {"pos", "c", "b"}
      ]

      # Extract just the unigoals (not the final multigoal)
      unigoals = Enum.take(todo_list, length(todo_list) - 1)
      final_multigoal = List.last(todo_list)

      assert unigoals == expected_unsatisfied
      assert final_multigoal == unsatisfied_multigoal
    end

    test "split_multigoal handles completely unsatisfied multigoals", %{state: state} do
      # Create multigoal where nothing is satisfied
      unsatisfied_multigoal = Multigoal.new([
        {"pos", "a", "b"},
        {"pos", "b", "c"},
        {"pos", "c", "a"}  # Circular - interesting test case
      ])

      assert {:ok, todo_list} = Domain.split_multigoal(state, unsatisfied_multigoal)

      # All goals should be unsatisfied
      expected_unsatisfied = [
        {"pos", "a", "b"},
        {"pos", "b", "c"},
        {"pos", "c", "a"}
      ]

      unigoals = Enum.take(todo_list, length(todo_list) - 1)
      final_multigoal = List.last(todo_list)

      assert unigoals == expected_unsatisfied
      assert final_multigoal == unsatisfied_multigoal
    end
  end

  describe "method chaining and composition" do
    setup do
      # State for testing method interactions
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "a")
      |> AriaHybridPlanner.set_fact("clear", "a", false)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      {:ok, state: state}
    end

    test "achieve_position chains with move_block", %{state: state} do
      # Test that achieve_position properly chains to move_block
      assert {:ok, actions} = Domain.achieve_position(state, {"b", "table"})

      # Should decompose to validation + movement
      assert actions == [
        {:validate_move, ["b", "table"]},
        {:move_block, ["b", "table"]}
      ]

      # Test that move_block further decomposes
      assert {:ok, move_actions} = Domain.move_block(state, ["b", "table"])
      assert move_actions == [{:unstack, ["b", "a"]}, {:putdown, ["b"]}]
    end

    test "achieve_clear chains with move_block", %{state: state} do
      # Test that achieve_clear properly chains to move_block
      assert {:ok, actions} = Domain.achieve_clear(state, {"a", true})

      # Should decompose to validation + movement of blocking block
      assert actions == [
        {:validate_move, ["b", "table"]},
        {:move_block, ["b", "table"]}
      ]
    end

    test "complex goal decomposition", %{state: state} do
      # Test a complex scenario: move a to table (requires clearing a first)

      # First, achieve_clear for a
      assert {:ok, clear_actions} = Domain.achieve_clear(state, {"a", true})
      assert clear_actions == [
        {:validate_move, ["b", "table"]},
        {:move_block, ["b", "table"]}
      ]

      # Then, test moving a to a different destination (not table, since a is already on table)
      # Note: In actual planning, the state would be updated between these calls
      state_after_clear = state
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)

      # Move a to a different destination (block d) to test the full decomposition
      assert {:ok, move_actions} = Domain.achieve_position(state_after_clear, {"a", "d"})
      assert move_actions == [
        {:validate_move, ["a", "d"]},
        {:move_block, ["a", "d"]}
      ]

      # Also test that if a is already at the target, no actions are needed
      assert {:ok, no_actions} = Domain.achieve_position(state_after_clear, {"a", "table"})
      assert no_actions == []
    end
  end

  describe "edge cases and boundary conditions" do
    test "empty state handling" do
      empty_state = AriaHybridPlanner.new_state()

      # Methods should handle empty state gracefully
      assert {:error, _} = Domain.take_method(empty_state, ["nonexistent"])
      assert {:ok, _} = Domain.achieve_position(empty_state, {"a", "table"})
      assert {:ok, _} = Domain.move_block(empty_state, ["a", "table"])
    end

    test "invalid block names" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Methods should handle invalid block names
      assert {:error, _} = Domain.take_method(state, ["nonexistent"])
      assert {:ok, _} = Domain.achieve_position(state, {"nonexistent", "table"})
    end

    test "circular dependencies in goals" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "table")
      |> AriaHybridPlanner.set_fact("pos", "b", "table")
      |> AriaHybridPlanner.set_fact("clear", "a", true)
      |> AriaHybridPlanner.set_fact("clear", "b", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Test circular multigoal
      circular_multigoal = Multigoal.new([
        {"pos", "a", "b"},
        {"pos", "b", "a"}
      ])

      # Should still decompose (planner will handle the impossibility)
      assert {:ok, todo_list} = Domain.split_multigoal(state, circular_multigoal)
      assert length(todo_list) == 3  # 2 unigoals + 1 multigoal
    end

    test "hand state consistency" do
      # Test with inconsistent hand state
      inconsistent_state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "a", "hand")
      |> AriaHybridPlanner.set_fact("holding", "hand", false)  # Inconsistent!

      # put_method should fail due to inconsistency
      assert {:error, :not_holding_block} = Domain.put_method(inconsistent_state, ["a", "table"])
    end
  end
end
