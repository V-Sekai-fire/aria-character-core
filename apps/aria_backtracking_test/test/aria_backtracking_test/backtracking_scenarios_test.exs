# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBacktrackingTest.BacktrackingScenariosTest do
  use ExUnit.Case, async: true
  doctest AriaBacktrackingTest

  alias AriaBacktrackingTest.State

  describe "GTPyhop backtracking_htn.py test scenarios" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "single backtrack: put_it + need0", %{state: state} do
      # This should backtrack from m_err to m0
      # Expected: [("putv", 0), ("getv", 0), ("getv", 0)]
      goals = [{"put_it", []}, {"need0", []}]

      assert {:ok, {final_state, _plan}} = AriaBacktrackingTest.solve_problem(state, goals)
      assert State.get_flag(final_state) == 0
    end

    test "method choice: put_it + need01", %{state: state} do
      # Should backtrack from m_err to m0 (since need01 can use either m_need0 or m_need1)
      # Expected: [("putv", 0), ("getv", 0), ("getv", 0)]
      goals = [{"put_it", []}, {"need01", []}]

      assert {:ok, {final_state, _plan}} = AriaBacktrackingTest.solve_problem(state, goals)
      assert State.get_flag(final_state) == 0
    end

    test "double backtrack: put_it + need10", %{state: state} do
      # Should backtrack on both put_it and need10
      # Expected: [("putv", 0), ("getv", 0), ("getv", 0)]
      goals = [{"put_it", []}, {"need10", []}]

      assert {:ok, {final_state, _plan}} = AriaBacktrackingTest.solve_problem(state, goals)
      assert State.get_flag(final_state) == 0
    end

    test "complex backtrack: put_it + need1", %{state: state} do
      # Should try m_err (fails), then m0 (fails need1), then m1 (succeeds)
      # Expected: [("putv", 1), ("getv", 1), ("getv", 1)]
      goals = [{"put_it", []}, {"need1", []}]

      assert {:ok, {final_state, _plan}} = AriaBacktrackingTest.solve_problem(state, goals)
      assert State.get_flag(final_state) == 1
    end
  end

  describe "individual action tests" do
    test "putv action sets flag correctly" do
      state = State.new()
      domain = AriaBacktrackingTest.Domain.create_domain()

      # Test putv with value 5
      assert {:ok, new_state} = AriaBacktrackingTest.Domain.putv(state, 5)
      assert State.get_flag(new_state) == 5

      # Test putv with value 0
      assert {:ok, new_state} = AriaBacktrackingTest.Domain.putv(state, 0)
      assert State.get_flag(new_state) == 0
    end

    test "getv action succeeds when flag matches" do
      state = State.new(42)

      # Should succeed when flag matches
      assert {:ok, ^state} = AriaBacktrackingTest.Domain.getv(state, 42)

      # Should fail when flag doesn't match
      assert {:error, _reason} = AriaBacktrackingTest.Domain.getv(state, 99)
    end
  end

  describe "method decomposition tests" do
    test "m_err method returns broken decomposition" do
      state = State.new()
      expected = [{"putv", [0]}, {"getv", [1]}]
      assert AriaBacktrackingTest.Domain.m_err(state) == expected
    end

    test "m0 method returns working decomposition for flag 0" do
      state = State.new()
      expected = [{"putv", [0]}, {"getv", [0]}]
      assert AriaBacktrackingTest.Domain.m0(state) == expected
    end

    test "m1 method returns working decomposition for flag 1" do
      state = State.new()
      expected = [{"putv", [1]}, {"getv", [1]}]
      assert AriaBacktrackingTest.Domain.m1(state) == expected
    end

    test "need methods return correct decompositions" do
      state = State.new()

      assert AriaBacktrackingTest.Domain.m_need0(state) == [{"getv", [0]}]
      assert AriaBacktrackingTest.Domain.m_need1(state) == [{"getv", [1]}]
    end
  end

  describe "state conversion tests" do
    test "state converts to and from relational state correctly" do
      original_state = State.new(123)

      relational_state = State.to_relational_state(original_state)
      converted_back = State.from_relational_state(relational_state)

      assert State.get_flag(converted_back) == 123
      assert converted_back == original_state
    end
  end

  describe "run_examples function" do
    test "run_examples completes without errors" do
      # This tests the main example runner function
      assert :ok = AriaBacktrackingTest.run_examples(false)
    end

    test "run_examples with verbose mode" do
      # Test verbose mode (should still succeed)
      assert :ok = AriaBacktrackingTest.run_examples(true)
    end
  end
end
