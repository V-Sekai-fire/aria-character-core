# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script for testing AriaEngine backtracking behavior
# This script includes the backtracking domain inline to avoid module loading issues

defmodule BacktrackingDebugSimplified do
  @moduledoc """
  Debug script for analyzing backtracking behavior in AriaEngine HTN planner.
  
  This version includes the backtracking domain inline to work around
  module loading issues when running with `mix run`.
  """

  alias AriaEngine.{Domain, State, Plan}

  # Inline backtracking domain definition
  def build_backtracking_domain do
    Domain.new("backtracking")
    |> Domain.add_action(:putv, &putv_action/2)
    |> Domain.add_action(:getv, &getv_action/2)
    |> Domain.add_task_method("put_it", &m_err/2)
    |> Domain.add_task_method("put_it", &m0/2)
    |> Domain.add_task_method("put_it", &m1/2)
    |> Domain.add_task_method("need0", &m_need0/2)
    |> Domain.add_task_method("need1", &m_need1/2)
    |> Domain.add_task_method("need01", &m_need0/2)
    |> Domain.add_task_method("need01", &m_need1/2)
    |> Domain.add_task_method("need10", &m_need1/2)
    |> Domain.add_task_method("need10", &m_need0/2)
  end

  # Action functions
  def putv_action(state, [flag_val]) do
    State.set_object(state, "flag", "system", flag_val)
  end

  def getv_action(state, [flag_val]) do
    current_flag = State.get_object(state, "flag", "system")
    if current_flag == flag_val do
      state
    else
      false
    end
  end

  # Method functions
  def m_err(_state, []) do
    [{"putv", [0]}, {"getv", [1]}]
  end

  def m0(_state, []) do
    [{"putv", [0]}, {"getv", [0]}]
  end

  def m1(_state, []) do
    [{"putv", [1]}, {"getv", [1]}]
  end

  def m_need0(_state, []) do
    [{"getv", [0]}]
  end

  def m_need1(_state, []) do
    [{"getv", [1]}]
  end

  def test_method_order do
    IO.puts("=== Testing method order ===")
    
    domain = build_backtracking_domain()
    
    # Check method ordering for task "put_it"
    methods = Domain.get_task_methods(domain, "put_it")
    IO.puts("Methods for 'put_it' task:")
    methods
    |> Enum.with_index()
    |> Enum.each(fn {method_func, index} ->
      IO.puts("  #{index}: #{inspect(method_func)}")
    end)
    
    # Test each method to see what subtasks they generate
    initial_state = State.new()
    |> State.set_object("flag", "system", :unset)
    
    IO.puts("\nTesting method outputs:")
    methods
    |> Enum.with_index()
    |> Enum.each(fn {method_func, index} ->
      try do
        result = method_func.(initial_state, [])
        IO.puts("  Method #{index}: #{inspect(result)}")
      rescue
        e ->
          IO.puts("  Method #{index}: ERROR - #{inspect(e)}")
      end
    end)
  end

  def test_single_task_planning do
    IO.puts("\n=== Testing single task planning ===")
    
    domain = build_backtracking_domain()
    initial_state = State.new()
    |> State.set_object("flag", "system", :unset)
    
    task_list = [{"put_it", []}]
    
    IO.puts("Planning for task: #{inspect(task_list)}")
    IO.puts("Initial state: flag = #{State.get_object(initial_state, "flag", "system")}")
    
    case Plan.plan(domain, initial_state, task_list, []) do
      {:ok, solution_tree} ->
        actions = Plan.get_primitive_actions_dfs(solution_tree)
        IO.puts("SUCCESS: Plan found: #{inspect(actions)}")
      {:error, reason} ->
        IO.puts("FAILURE: #{inspect(reason)}")
      other ->
        IO.puts("UNEXPECTED: #{inspect(other)}")
    end
  end

  def test_backtracking_scenario do
    IO.puts("\n=== Testing backtracking scenario ===")
    
    domain = build_backtracking_domain()
    initial_state = State.new()
    |> State.set_object("flag", "system", :unset)
    
    # Test the specific scenario that should require backtracking
    # This should fail with m_err (putv 0, getv 1) and succeed with m0 (putv 0, getv 0)
    task_list = [{"put_it", []}]
    
    IO.puts("Planning for backtracking scenario...")
    IO.puts("Expected: First method (m_err) should fail, then backtrack to second method (m0)")
    
    case Plan.plan(domain, initial_state, task_list, []) do
      {:ok, solution_tree} ->
        actions = Plan.get_primitive_actions_dfs(solution_tree)
        IO.puts("SUCCESS: Plan found: #{inspect(actions)}")
        
        # Verify the plan makes sense
        if actions == [{:putv, [0]}, {:getv, [0]}] do
          IO.puts("✓ Plan matches expected successful method (m0)")
        else
          IO.puts("⚠ Plan doesn't match expected method output")
        end
      {:error, reason} ->
        IO.puts("FAILURE: #{inspect(reason)}")
      other ->
        IO.puts("UNEXPECTED: #{inspect(other)}")
    end
  end

  def test_complex_backtracking do
    IO.puts("\n=== Testing complex backtracking ===")
    
    domain = build_backtracking_domain()
    initial_state = State.new()
    |> State.set_object("flag", "system", :unset)
    
    # Test with need01 which has two methods that should both be tried
    task_list = [{"need01", []}]
    
    IO.puts("Planning for need01 task...")
    IO.puts("This task should succeed with either m_need0 or m_need1 depending on current flag state")
    
    case Plan.plan(domain, initial_state, task_list, []) do
      {plan_result, final_state} when is_list(plan_result) ->
        IO.puts("SUCCESS: Plan found: #{inspect(plan_result)}")
        IO.puts("Final state: flag = #{State.get_object(final_state, "flag", "system")}")
      {:error, reason} ->
        IO.puts("FAILURE: #{inspect(reason)}")
      other ->
        IO.puts("UNEXPECTED: #{inspect(other)}")
    end
  end

  def test_state_simulation do
    IO.puts("\n=== Testing state simulation during planning ===")
    
    _domain = build_backtracking_domain()
    
    # Test putv action
    initial_state = State.new()
    |> State.set_object("flag", "system", :unset)
    
    IO.puts("Testing putv action...")
    IO.puts("Initial flag: #{State.get_object(initial_state, "flag", "system")}")
    
    putv_result = putv_action(initial_state, [0])
    if putv_result do
      IO.puts("After putv(0): #{State.get_object(putv_result, "flag", "system")}")
    else
      IO.puts("putv(0) failed")
    end
    
    # Test getv action with matching value
    IO.puts("\nTesting getv action with matching value...")
    getv_result = getv_action(putv_result, [0])
    if getv_result do
      IO.puts("getv(0) succeeded")
    else
      IO.puts("getv(0) failed")
    end
    
    # Test getv action with non-matching value
    IO.puts("\nTesting getv action with non-matching value...")
    getv_fail_result = getv_action(putv_result, [1])
    if getv_fail_result do
      IO.puts("getv(1) succeeded (unexpected)")
    else
      IO.puts("getv(1) failed (expected)")
    end
  end

  def run_all_tests do
    IO.puts("Starting backtracking debug analysis...")
    IO.puts("=" <> String.duplicate("=", 50))
    
    test_method_order()
    test_single_task_planning()
    test_backtracking_scenario()
    test_complex_backtracking()
    test_state_simulation()
    
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("Debug analysis complete.")
  end
end

# Run the tests
BacktrackingDebugSimplified.run_all_tests()
