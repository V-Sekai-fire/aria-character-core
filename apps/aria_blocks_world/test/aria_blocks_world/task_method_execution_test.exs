# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.TaskMethodExecutionTest do
  @moduledoc """
  Test to debug task method execution pipeline issues.
  """

  use ExUnit.Case
  require Logger

  alias AriaBlocksWorld.Domain
  alias AriaHybridPlanner

  test "debug task method execution - validate_move and move_block" do
    # Create test state
    state = AriaHybridPlanner.new_state()
    |> AriaHybridPlanner.set_fact("pos", "b", "d")
    |> AriaHybridPlanner.set_fact("pos", "c", "table")
    |> AriaHybridPlanner.set_fact("clear", "b", true)
    |> AriaHybridPlanner.set_fact("clear", "c", true)
    |> AriaHybridPlanner.set_fact("holding", "hand", false)

    # Test validate_move task method directly
    Logger.debug("Testing validate_move task method...")
    validate_result = Domain.validate_move(state, ["b", "c"])
    Logger.debug("validate_move result: #{inspect(validate_result)}")

    # Test move_block task method directly
    Logger.debug("Testing move_block task method...")
    move_result = Domain.move_block(state, ["b", "c"])
    Logger.debug("move_block result: #{inspect(move_result)}")

    # Both should return {:ok, [list_of_actions]}
    assert {:ok, validate_actions} = validate_result
    assert {:ok, move_actions} = move_result

    Logger.debug("validate_move returns: #{inspect(validate_actions)}")
    Logger.debug("move_block returns: #{inspect(move_actions)}")

    # move_block should return primitive actions
    assert move_actions == [{:unstack, ["b", "d"]}, {:stack, ["b", "c"]}]

    # validate_move should return empty list (no validation needed for this simple case)
    assert validate_actions == []
  end

  test "debug primitive action execution" do
    # Create test state
    state = AriaHybridPlanner.new_state()
    |> AriaHybridPlanner.set_fact("pos", "b", "d")
    |> AriaHybridPlanner.set_fact("pos", "d", "table")
    |> AriaHybridPlanner.set_fact("clear", "b", true)
    |> AriaHybridPlanner.set_fact("clear", "d", false)
    |> AriaHybridPlanner.set_fact("holding", "hand", false)

    # Test primitive actions that move_block would generate
    Logger.debug("Testing primitive action: unstack")
    unstack_result = Domain.unstack(state, ["b", "d"])
    Logger.debug("unstack result: #{inspect(unstack_result)}")

    assert {:ok, state1} = unstack_result

    Logger.debug("Testing primitive action: stack")
    # First need to set up state for stack (c must be clear)
    state1 = AriaHybridPlanner.set_fact(state1, "clear", "c", true)
    stack_result = Domain.stack(state1, ["b", "c"])
    Logger.debug("stack result: #{inspect(stack_result)}")

    assert {:ok, _final_state} = stack_result
  end

  test "debug execution pipeline issue" do
    # The issue is likely that the planner is treating task methods as primitive actions
    # Let's see what happens when we try to execute a task method as if it were a primitive action

    state = AriaHybridPlanner.new_state()
    |> AriaHybridPlanner.set_fact("pos", "b", "d")
    |> AriaHybridPlanner.set_fact("clear", "b", true)
    |> AriaHybridPlanner.set_fact("holding", "hand", false)

    # This is what the planner is trying to do - execute task methods as actions
    # The execution engine should recognize these as task methods and decompose them further
    # instead of trying to execute them as primitive actions

    Logger.debug("Task methods should be decomposed, not executed as primitives")
    Logger.debug("validate_move should decompose to: #{inspect(Domain.validate_move(state, ["b", "c"]))}")
    Logger.debug("move_block should decompose to: #{inspect(Domain.move_block(state, ["b", "c"]))}")

    # The problem is in the execution engine - it's not recognizing that these are task methods
    # that need further decomposition, not primitive actions to execute directly
  end
end
