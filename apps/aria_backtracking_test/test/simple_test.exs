# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBacktrackingTest.SimpleTest do
  use ExUnit.Case

  test "basic state creation and flag manipulation" do
    # Test state creation
    state = AriaBacktrackingTest.State.new()
    assert AriaBacktrackingTest.State.get_flag(state) == -1

    # Test state with specific flag
    state2 = AriaBacktrackingTest.State.new(42)
    assert AriaBacktrackingTest.State.get_flag(state2) == 42

    # Test flag setting
    state3 = AriaBacktrackingTest.State.set_flag(state, 99)
    assert AriaBacktrackingTest.State.get_flag(state3) == 99
  end

  test "domain actions work correctly" do
    # Create initial state using relational state
    relational_state = AriaState.RelationalState.new()
    |> AriaState.RelationalState.set_fact("system", "flag", -1)

    # Test putv action
    {:ok, new_state} = AriaBacktrackingTest.Domain.putv(relational_state, [42])
    flag_value = AriaState.RelationalState.get_fact(new_state, "system", "flag")
    assert flag_value == 42

    # Test getv action - should succeed
    {:ok, _} = AriaBacktrackingTest.Domain.getv(new_state, [42])

    # Test getv action - should fail
    {:error, _} = AriaBacktrackingTest.Domain.getv(new_state, [99])
  end

  test "domain methods return correct task lists" do
    state = AriaState.RelationalState.new()

    # Test m_err method (broken method)
    {:ok, tasks} = AriaBacktrackingTest.Domain.m_err(state, [])
    assert tasks == [{:putv, [0]}, {:getv, [1]}]

    # Test m0 method (working method)
    {:ok, tasks} = AriaBacktrackingTest.Domain.m0(state, [])
    assert tasks == [{:putv, [0]}, {:getv, [0]}]

    # Test m1 method (working method)
    {:ok, tasks} = AriaBacktrackingTest.Domain.m1(state, [])
    assert tasks == [{:putv, [1]}, {:getv, [1]}]
  end

  test "domain info is correct" do
    info = AriaBacktrackingTest.Domain.info()
    assert info.name == "Backtracking Test Domain"
    assert :putv in info.actions
    assert :getv in info.actions
    assert :put_it in info.tasks
  end
end
