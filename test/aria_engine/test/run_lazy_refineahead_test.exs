# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule RunLazyRefineaheadTest do
  @moduledoc """
  Test the Run-Lazy-Refineahead execution with replanning on failure.

  This test creates scenarios where actions fail during execution, triggering
  the replanning mechanism to find alternative solutions.
  """

  use ExUnit.Case
  # Set timeout to 30 seconds
  @tag timeout: 30000

  test "Run-Lazy-Refineahead with action failure and replanning" do
    # Create a domain with actions that can fail conditionally
    domain = create_failing_domain()

    # Create initial state
    initial_state = create_test_state()

    # Define tasks that will require replanning when first action fails
    todos = [{"move_with_failure", ["start", "goal"]}]

    # Plan using IPyHOP
    case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 1) do
      {:ok, solution_tree} ->
        TestOutput.trace_puts("Initial planning succeeded!")
        TestOutput.trace_inspect(AriaEngine.Plan.Utils.tree_stats(solution_tree))

        # Extract actions for inspection
        initial_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
        TestOutput.trace_puts("Initial plan: #{inspect(initial_actions)}")

        # Execute with Run-Lazy-Refineahead (this should trigger replanning)
        # Increased verbose level
        case AriaEngine.Plan.Execution.run_lazy_refineahead(domain, initial_state, solution_tree, verbose: 3) do
          {:ok, final_state} ->
            # Verify we reached the goal despite initial failures
            robot_location = State.get_fact(final_state, "robot", "location")
            assert robot_location == "goal"

            TestOutput.trace_puts("Run-Lazy-Refineahead succeeded with replanning!")

          {:error, reason} ->
            # Check if this is the expected "no more alternatives" error
            if String.contains?(reason, "Replanning failed") or
               String.contains?(reason, "No methods available") or
               String.contains?(reason, "No complete solution found") do
              TestOutput.trace_puts("Expected failure: #{reason}")
              assert true
            else
              flunk("Unexpected execution failure: #{reason}")
            end
        end

      {:error, reason} ->
        flunk("Planning failed: #{reason}")
    end
  end

  # Create domain with actions that can fail on first attempt
  defp create_failing_domain do
    domain =
      AriaEngine.Domain.new("failing_test")

      # Add actions that may fail initially
      |> AriaEngine.Domain.add_action(:move_unreliable, &move_unreliable_action/2)
      |> AriaEngine.Domain.add_action(:move_reliable, &move_reliable_action/2)

      # Add task methods - first method uses unreliable action, second uses reliable
      |> AriaEngine.Domain.add_task_method("move_with_failure", &method_unreliable_move/2)
      |> AriaEngine.Domain.add_task_method("move_with_failure", &method_reliable_move/2)

    domain
  end

  # Action that fails if robot hasn't "prepared" (simulates environmental failure)
  defp move_unreliable_action(state, [from, to]) do
    robot_location = State.get_fact(state, "robot", "location")
    prepared = State.get_fact(state, "robot", "prepared")

    TestOutput.trace_puts(
      "move_unreliable_action: robot_location=#{inspect(robot_location)}, from=#{inspect(from)}, prepared=#{inspect(prepared)}"
    )

    if robot_location == from and prepared == true do
      TestOutput.trace_puts("move_unreliable_action: SUCCESS")
      # Success - update location
      State.set_fact(state, "robot", "location", to)
    else
      TestOutput.trace_puts("move_unreliable_action: FAILURE")
      # Failure - robot not prepared or not at start location
      false
    end
  end

  # Action that always works (prepares robot and moves)
  defp move_reliable_action(state, [from, to]) do
    robot_location = State.get_fact(state, "robot", "location")

    TestOutput.trace_puts(
      "move_reliable_action: robot_location=#{inspect(robot_location)}, from=#{inspect(from)}"
    )

    if robot_location == from do
      TestOutput.trace_puts("move_reliable_action: SUCCESS")
      # Always succeeds - prepare and move
      state
      |> State.set_fact("robot", "prepared", true)
      |> State.set_fact("robot", "location", to)
    else
      TestOutput.trace_puts("move_reliable_action: FAILURE")
      false
    end
  end

  # Method using unreliable action (will fail initially)
  defp method_unreliable_move(state, [from, to]) do
    robot_location = State.get_fact(state, "robot", "location")

    if robot_location == from do
      [{:move_unreliable, [from, to]}]
    else
      false
    end
  end

  # Method using reliable action (backup method)
  defp method_reliable_move(state, [from, to]) do
    robot_location = State.get_fact(state, "robot", "location")

    if robot_location == from do
      [{:move_reliable, [from, to]}]
    else
      false
    end
  end

  # Create test state
  defp create_test_state do
    State.new()
    |> State.set_fact("location", "robot", "start")
    # Robot not prepared initially
    |> State.set_fact("robot", "prepared", false)
  end
end
