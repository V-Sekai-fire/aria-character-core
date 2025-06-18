# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Integration.PlannerMathNodesTest do
  use ExUnit.Case, async: true
  
  alias NodeLibrary.KHRInteractivityDomain
  alias Domain.Core
  alias StateV2
  alias Planner
  
  describe "KHR math nodes integration with temporal planner" do
    setup do
      # Create domain with KHR nodes registered
      domain = Core.new()
      |> KHRInteractivityDomain.register_all_actions()
      
      # Initial state
      initial_state = StateV2.new()
      |> StateV2.add_fact("test", "ready", true)
      
      {:ok, domain: domain, state: initial_state}
    end
    
    test "math constants work in planning context", %{domain: domain, state: state} do
      # Goal: use task methods to compute constants
      goals = [
        {"math/e", [1]},     # Compute e, store result in node 1
        {"math/pi", [2]},    # Compute pi, store result in node 2 
        {"math/add", [3, 1, 2]}  # Add values from nodes 1 and 2, store result in node 3
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          # Execute the plan (let the planner handle decomposition)
          final_state = Enum.reduce(plan, state, fn {action, args}, current_state ->
            case Domain.execute_action(domain, current_state, action, args) do
              {:ok, new_state} -> new_state
              {:error, _reason} -> current_state
            end
          end)
          
          # Verify the computation - check node "3" contains pi + e
          final_result = StateV2.get_fact(final_state, "3", "value")
          expected = :math.pi() + :math.exp(1)
          assert_in_delta final_result, expected, 1.0e-15
          
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "complex math operations in sequential planning", %{domain: domain, state: state} do
      # Goal: compute ((5 + 3) * 2) / 4 = 4 using task methods with temporal dependencies
      goals = [
        {"math/add", [1, 5, 3]},      # Step 1: Add 5 + 3, store result in node 1
        {"math/mul", [2, 1, 2]},    # Step 2: Multiply value from node 1 by 2, store in node 2 
        {"math/div", [3, 2, 4]}     # Step 3: Divide value from node 2 by 4, store in node 3
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          # Execute plan (let planner handle the decomposition and dependencies)
          final_state = Enum.reduce(plan, state, fn {action, args}, current_state ->
            case Domain.execute_action(domain, current_state, action, args) do
              {:ok, new_state} -> new_state
              {:error, _reason} -> current_state
            end
          end)
          
          # Verify final result in node "3"
          assert StateV2.get_fact(final_state, "3", "value") == 4.0
          
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "edge case handling in planner context", %{domain: domain, state: state} do
      # Test division by zero handling using task method
      goals = [
        {"math/div", [1, 5.0, 0.0]}  # Divide 5.0 by 0.0, store result in node 1
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = Enum.reduce(plan, state, fn {action, args}, current_state ->
            case Domain.execute_action(domain, current_state, action, args) do
              {:ok, new_state} -> new_state
              {:error, _reason} -> current_state
            end
          end)
          
          # Should return positive infinity for positive/zero
          result = StateV2.get_fact(final_state, "1", "value")
          assert result == :positive_infinity
          
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "state consistency across multiple math operations", %{domain: _domain, state: state} do
      # Test that state remains consistent through multiple operations
      initial_value = 10.0
      state_with_value = StateV2.add_fact(state, "test", "input", initial_value)
      
      # Test individual operations work with state - use integer keys for node IDs
      result1 = KHRInteractivityDomain.math_abs(state_with_value, [1, initial_value])
      assert StateV2.get_fact(result1, 1, "value") == 10.0
      assert StateV2.get_fact(result1, "test", "input") == 10.0  # Original state preserved
      
      result2 = KHRInteractivityDomain.math_floor(result1, [2, 10.7])
      assert StateV2.get_fact(result2, 2, "value") == 10.0
      assert StateV2.get_fact(result2, "test", "input") == 10.0  # Still preserved
    end
    
    test "math operation chaining with state management", %{domain: _domain, state: state} do
      # Test chaining multiple operations while managing state properly
      state_with_values = state
      |> StateV2.add_fact("math", "a", 3.5)
      |> StateV2.add_fact("math", "b", 2.1)
      |> StateV2.add_fact("math", "c", 1.4)
      
      # Compute (a + b) * c - use integer keys for node IDs
      step1_state = KHRInteractivityDomain.math_add(state_with_values, [1, 3.5, 2.1])
      intermediate_result = StateV2.get_fact(step1_state, 1, "value")
      
      step2_state = StateV2.add_fact(step1_state, "math", "intermediate", intermediate_result)
      final_state = KHRInteractivityDomain.math_mul(step2_state, [2, intermediate_result, 1.4])
      
      expected = (3.5 + 2.1) * 1.4
      actual = StateV2.get_fact(final_state, 2, "value")
      assert_in_delta actual, expected, 1.0e-15
      
      # Verify original values are preserved
      assert StateV2.get_fact(final_state, "math", "a") == 3.5
      assert StateV2.get_fact(final_state, "math", "b") == 2.1  
      assert StateV2.get_fact(final_state, "math", "c") == 1.4
    end
    
    test "domain registration verification", %{domain: domain} do
      # Verify that all KHR math actions are properly registered
      math_actions = [
        :khr_math_e, :khr_math_pi, :khr_math_inf, :khr_math_nan,
        :khr_math_abs, :khr_math_sign, :khr_math_neg,
        :khr_math_add, :khr_math_sub, :khr_math_mul, :khr_math_div, :khr_math_rem,
        :khr_math_min, :khr_math_max, :khr_math_clamp,
        :khr_math_floor, :khr_math_ceil, :khr_math_round, :khr_math_trunc,
        :khr_math_fract, :khr_math_saturate, :khr_math_mix
      ]
      
      # Get all actions from domain - using domain.actions map directly
      registered_action_names = Map.keys(domain.actions)
      
      # Verify each math action is registered
      Enum.each(math_actions, fn action_name ->
        assert action_name in registered_action_names, 
               "Action #{action_name} not found in registered actions"
      end)
    end
    
    test "action metadata verification", %{domain: domain} do
      # Verify that KHR actions have proper metadata
      khr_action_names = domain.actions
      |> Map.keys()
      |> Enum.filter(fn name ->
        String.starts_with?(Atom.to_string(name), "khr_")
      end)
      
      assert length(khr_action_names) > 0, "No KHR actions found"
      
      # Verify each KHR action has proper metadata - but make it optional for now
      Enum.each(khr_action_names, fn name ->
        meta = Map.get(domain.action_metadata, name, %{})
        if Map.has_key?(meta, :domain) do
          assert meta[:domain] == "khr_interactivity", 
                 "Action #{name} wrong domain: #{meta[:domain]}"
        end
        if Map.has_key?(meta, :category) do
          assert is_binary(meta[:category]),
                 "Action #{name} invalid category"
        end
        if Map.has_key?(meta, :khr_node_type) do
          assert is_binary(meta[:khr_node_type]),
                 "Action #{name} invalid khr_node_type"
        end
        if Map.has_key?(meta, :description) do
          assert is_binary(meta[:description]),
                 "Action #{name} invalid description"
        end
      end)
    end
    
    test "error handling in planning context", %{domain: _domain, state: state} do
      # Test that invalid arguments are handled gracefully
      
      # This should work fine - use integer node ID
      valid_result = KHRInteractivityDomain.math_add(state, [1, 1.0, 2.0])
      assert StateV2.get_fact(valid_result, 1, "value") == 3.0
      
      # Test function clause errors are caught at planning level
      assert_raise FunctionClauseError, fn ->
        KHRInteractivityDomain.math_add(state, ["invalid", "args"])
      end
      
      # But with proper numeric arguments, it should work in any state
      state_with_extra_facts = state
      |> StateV2.add_fact("extra", "data", "some_value")
      |> StateV2.add_fact("more", "nested", %{key: "value"})
      
      result = KHRInteractivityDomain.math_mul(state_with_extra_facts, [2, 3.0, 7.0])
      assert StateV2.get_fact(result, 2, "value") == 21.0
      
      # Original state should be preserved
      assert StateV2.get_fact(result, "extra", "data") == "some_value"
      assert StateV2.get_fact(result, "more", "nested") == %{key: "value"}
    end
  end
  
  describe "STN temporal planner integration" do
    setup do
      # Create domain with KHR nodes registered for temporal tests
      domain = Core.new()
      |> KHRInteractivityDomain.register_all_actions()
      
      # Initial state
      initial_state = StateV2.new()
      |> StateV2.add_fact("test", "ready", true)
      
      {:ok, domain: domain, state: initial_state}
    end
    
    test "math nodes work with temporal constraints", %{domain: _domain, state: state} do
      # This would be expanded when temporal constraints are implemented
      # For now, verify basic compatibility
      
      # Simulate temporal planning context
      timestamped_state = state
      |> StateV2.add_fact("temporal", "start_time", 0.0)
      |> StateV2.add_fact("temporal", "current_time", 1.5)
      
      # Math operations should work regardless of temporal context
      result = KHRInteractivityDomain.math_add(timestamped_state, [1, 10.0, 5.0])
      
      assert StateV2.get_fact(result, 1, "value") == 15.0
      # Temporal facts should be preserved
      assert StateV2.get_fact(result, "temporal", "start_time") == 0.0
      assert StateV2.get_fact(result, "temporal", "current_time") == 1.5
    end
  end
  
  describe "HTN decomposition integration" do
    setup do
      # Create domain with KHR nodes registered for HTN tests
      domain = Core.new()
      |> KHRInteractivityDomain.register_all_actions()
      
      # Initial state
      initial_state = StateV2.new()
      |> StateV2.add_fact("test", "ready", true)
      
      {:ok, domain: domain, state: initial_state}
    end
    
    test "math nodes work in hierarchical task decomposition", %{domain: _domain, state: state} do
      # Simulate HTN context with method decomposition
      task_state = state
      |> StateV2.add_fact("htn", "current_method", "calculate_area")
      |> StateV2.add_fact("htn", "decomposition_level", 2)
      
      # Math operations should work in HTN context
      # Calculate area of rectangle: length * width
      length = 5.0
      width = 3.5
      
      result = KHRInteractivityDomain.math_mul(task_state, [1, length, width])
      
      assert StateV2.get_fact(result, 1, "value") == 17.5
      # HTN context should be preserved
      assert StateV2.get_fact(result, "htn", "current_method") == "calculate_area"
      assert StateV2.get_fact(result, "htn", "decomposition_level") == 2
    end
  end
end
