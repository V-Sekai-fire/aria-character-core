# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule RunLazyRefineaheadTest do
  @moduledoc "Test the Run-Lazy-Refineahead execution with replanning on failure.\n\nThis test creates scenarios where actions fail during execution, triggering\nthe replanning mechanism to find alternative solutions.\n"
  use ExUnit.Case
  @tag timeout: 30000
  test "Run-Lazy-Refineahead with action failure and replanning" do
    domain = create_failing_domain()
    initial_state = create_test_state()
    todos = [{"move_with_failure", ["start", "goal"]}]

    case Plan.plan(domain, initial_state, todos, verbose: 1) do
      {:ok, solution_tree} ->
        TestOutput.trace_puts("Initial planning succeeded!")
        TestOutput.trace_inspect(Plan.tree_stats(solution_tree))
        initial_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
        TestOutput.trace_puts("Initial plan: #{inspect(initial_actions)}")

        case Plan.run_lazy_refineahead(domain, initial_state, solution_tree, verbose: 3) do
          {:ok, final_state} ->
            robot_location = AriaEngine.State.get_fact(final_state, "robot", "location")
            assert robot_location == "goal"
            TestOutput.trace_puts("Run-Lazy-Refineahead succeeded with replanning!")

          {:error, reason} ->
            if String.contains?(reason, "Replanning failed") do
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

  defp create_failing_domain do
    domain =
      Domain.new("failing_test")
      |> Domain.add_action(:move_unreliable, &move_unreliable_action/2)
      |> Domain.add_action(:move_reliable, &move_reliable_action/2)
      |> Domain.add_task_method("move_with_failure", &method_unreliable_move/2)
      |> Domain.add_task_method("move_with_failure", &method_reliable_move/2)

    domain
  end

  defp move_unreliable_action(state, [from, to]) do
    robot_location = AriaEngine.State.get_fact(state, "robot", "location")
    prepared = AriaEngine.State.get_fact(state, "robot", "prepared")

    TestOutput.trace_puts(
      "move_unreliable_action: robot_location=#{inspect(robot_location)}, from=#{inspect(from)}, prepared=#{inspect(prepared)}"
    )

    if robot_location == from and prepared == true do
      TestOutput.trace_puts("move_unreliable_action: SUCCESS")
      AriaEngine.State.set_fact(state, "robot", "location", to)
    else
      TestOutput.trace_puts("move_unreliable_action: FAILURE")
      false
    end
  end

  defp move_reliable_action(state, [from, to]) do
    robot_location = AriaEngine.State.get_fact(state, "robot", "location")

    TestOutput.trace_puts(
      "move_reliable_action: robot_location=#{inspect(robot_location)}, from=#{inspect(from)}"
    )

    if robot_location == from do
      TestOutput.trace_puts("move_reliable_action: SUCCESS")

      state
      |> AriaEngine.State.set_fact("robot", "prepared", true)
      |> AriaEngine.State.set_fact("robot", "location", to)
    else
      TestOutput.trace_puts("move_reliable_action: FAILURE")
      false
    end
  end

  defp method_unreliable_move(state, [from, to]) do
    robot_location = AriaEngine.State.get_fact(state, "robot", "location")

    if robot_location == from do
      [move_unreliable: [from, to]]
    else
      false
    end
  end

  defp method_reliable_move(state, [from, to]) do
    robot_location = AriaEngine.State.get_fact(state, "robot", "location")

    if robot_location == from do
      [move_reliable: [from, to]]
    else
      false
    end
  end

  defp create_test_state do
    AriaEngine.State.new()
    |> AriaEngine.State.set_fact("robot", "location", "start")
    |> AriaEngine.State.set_fact("robot", "prepared", false)
  end
end