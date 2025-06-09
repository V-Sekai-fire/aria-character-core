# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BacktrackingTest do
  use ExUnit.Case

  import AriaEngine
  alias AriaEngine.{State, TestDomains}

  @moduletag timeout: 120_000

  describe "Backtracking HTN domain" do
    test "domain creation" do
      domain = TestDomains.build_backtracking_domain()
      summary = AriaEngine.domain_summary(domain)

      assert summary.name == "backtracking"
      assert :putv in summary.actions
      assert :getv in summary.actions
      assert "put_it" in summary.task_methods
      assert "need0" in summary.task_methods
      assert "need1" in summary.task_methods
      assert "need01" in summary.task_methods
      assert "need10" in summary.task_methods
    end

    test "putv and getv actions work correctly" do
      domain = TestDomains.build_backtracking_domain()
      initial_state = TestDomains.create_backtracking_state()

      # Initial flag should be -1
      assert get_fact(initial_state, "flag", "system") == -1

      # Set flag to 0
      state1 = AriaEngine.Domain.execute_action(domain, initial_state, :putv, [0])
      assert get_fact(state1, "flag", "system") == 0

      # getv should succeed if flag matches
      state2 = AriaEngine.Domain.execute_action(domain, state1, :getv, [0])
      assert state2 != nil
      assert get_fact(state2, "flag", "system") == 0

      # getv should fail if flag doesn't match
      state3 = AriaEngine.Domain.execute_action(domain, state1, :getv, [1])
      assert state3 == nil
    end

    test "backtracking through put_it methods for need0" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [["put_it"], ["need0"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          # Should use m0 method: putv(0), getv(0), then getv(0) for need0
          expected = [{"putv", 0}, {"getv", 0}, {"getv", 0}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "backtracking through put_it methods for need1" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [["put_it"], ["need1"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          # Should use m1 method: putv(1), getv(1), then getv(1) for need1
          expected = [{"putv", 1}, {"getv", 1}, {"getv", 1}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "backtracking through put_it and need01 methods" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [["put_it"], ["need01"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          # Should backtrack to find compatible solution
          expected = [{"putv", 0}, {"getv", 0}, {"getv", 0}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "backtracking through put_it and need10 methods" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [["put_it"], ["need10"]]

      case AriaEngine.find_plan(domain, state, goals) do
        {:ok, plan} ->
          # Should try need1 first, backtrack when it fails, then try need0
          expected = [{"putv", 0}, {"getv", 0}, {"getv", 0}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end
  end
end
