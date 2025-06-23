# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule BacktrackingTest do
  use ExUnit.Case
  require Logger
  import AriaEngine
  alias {TestDomains}
  @moduletag timeout: 120_000
  describe("Backtracking HTN domain") do
    test "domain creation" do
      domain = TestDomains.build_backtracking_domain()
      summary = domain_summary(domain)
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
      assert get_fact(initial_state, "flag", "system") == -1
      {:ok, state1} = Domain.execute_action(domain, initial_state, :putv, [0])
      assert get_fact(state1, "flag", "system") == 0
      {:ok, state2} = Domain.execute_action(domain, state1, :getv, [0])
      assert state2 != false
      assert get_fact(state2, "flag", "system") == 0
      state3 = Domain.execute_action(domain, state1, :getv, [1])
      assert state3 == false
    end

    test "backtracking through put_it methods for need0" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [{"put_it", []}, {"need0", []}]

      case plan(domain, state, goals, verbose: 3) do
        {:ok, plan} ->
          expected = [{"putv", [0]}, {"getv", [0]}, {"getv", [0]}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "backtracking through put_it methods for need1" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [{"put_it", []}, {"need1", []}]

      case plan(domain, state, goals, verbose: 3) do
        {:ok, plan} ->
          expected = [{"putv", [1]}, {"getv", [1]}, {"getv", [1]}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "backtracking through put_it and need01 methods" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [{"put_it", []}, {"need01", []}]

      case plan(domain, state, goals, verbose: 0) do
        {:ok, plan} ->
          expected = [{"putv", [0]}, {"getv", [0]}, {"getv", [0]}]
          Logger.info("Got plan: #{inspect(plan)}")
          Logger.info("Expected: #{inspect(expected)}")
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "backtracking through put_it and need10 methods" do
      domain = TestDomains.build_backtracking_domain()
      state = TestDomains.create_backtracking_state()
      goals = [{"put_it", []}, {"need10", []}]

      case plan(domain, state, goals, verbose: 3) do
        {:ok, plan} ->
          expected = [{"putv", [0]}, {"getv", [0]}, {"getv", [0]}]
          assert plan == expected

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end
  end
end