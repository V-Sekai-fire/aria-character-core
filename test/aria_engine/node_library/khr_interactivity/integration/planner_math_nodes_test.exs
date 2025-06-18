# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivity.Integration.PlannerMathNodesTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.NodeLibrary.KHRInteractivityDomain
  alias AriaEngine.Domain.Core
  alias AriaEngine.Domain.Actions
  alias AriaEngine.StateV2
  alias AriaEngine.Planner
  
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
      # Goal: compute pi + e using KHR nodes
      goals = [
        {:khr_math_pi, []},
        {:khr_math_e, []},
        {:khr_math_add, ["pi_result", "e_result"]}
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          # Execute the plan
          final_state = Enum.reduce(plan, state, fn {action, args}, current_state ->
            case action do
              :khr_math_pi -> 
                result_state = KHRInteractivityDomain.math_pi(current_state, args)
                StateV2.add_fact(result_state, "test", "pi_result", StateV2.get_fact(result_state, "output", "value"))
              :khr_math_e ->
                result_state = KHRInteractivityDomain.math_e(current_state, args)
                StateV2.add_fact(result_state, "test", "e_result", StateV2.get_fact(result_state, "output", "value"))
              :khr_math_add ->
                pi_val = StateV2.get_fact(current_state, "test", "pi_result")
                e_val = StateV2.get_fact(current_state, "test", "e_result")
                result_state = KHRInteractivityDomain.math_add(current_state, [pi_val, e_val])
                StateV2.add_fact(result_state, "test", "final_result", StateV2.get_fact(result_state, "output", "value"))
              _ ->
                current_state
            end
          end)
          
          # Verify the computation
          final_result = StateV2.get_fact(final_state, "test", "final_result")
          expected = :math.pi() + :math.exp(1)
          assert_in_delta final_result, expected, 1.0e-15
          
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "complex math operations in sequential planning", %{domain: domain, state: state} do
      # Goal: compute ((5 + 3) * 2) / 4 = 4
      goals = [
        {:khr_math_add, [5, 3]},      # 8
        {:khr_math_mul, ["add_result", 2]},  # 16  
        {:khr_math_div, ["mul_result", 4]}   # 4
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          # Execute plan step by step
          final_state = Enum.reduce(plan, state, fn {action, args}, current_state ->
            case action do
              :khr_math_add ->
                result_state = KHRInteractivityDomain.math_add(current_state, args)
                StateV2.add_fact(result_state, "test", "add_result", StateV2.get_fact(result_state, "output", "value"))
              :khr_math_mul ->
                add_val = StateV2.get_fact(current_state, "test", "add_result")
                result_state = KHRInteractivityDomain.math_mul(current_state, [add_val, 2])
                StateV2.add_fact(result_state, "test", "mul_result", StateV2.get_fact(result_state, "output", "value"))
              :khr_math_div ->
                mul_val = StateV2.get_fact(current_state, "test", "mul_result")
                result_state = KHRInteractivityDomain.math_div(current_state, [mul_val, 4])
                StateV2.add_fact(result_state, "test", "final_result", StateV2.get_fact(result_state, "output", "value"))
              _ ->
                current_state
            end
          end)
          
          # Verify result
          assert StateV2.get_fact(final_state, "test", "final_result") == 4.0
          
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "edge case handling in planner context", %{domain: domain, state: state} do
      # Test division by zero handling
      goals = [
        {:khr_math_div, [5.0, 0.0]}
      ]
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          final_state = Enum.reduce(plan, state, fn {action, args}, current_state ->
            case action do
              :khr_math_div ->
                result_state = KHRInteractivityDomain.math_div(current_state, args)
                StateV2.add_fact(result_state, "test", "div_result", StateV2.get_fact(result_state, "output", "value"))
              _ ->
                current_state
            end
          end)
          
          # Should return positive infinity for positive/zero
          assert StateV2.get_fact(final_state, "test", "div_result") == :positive_infinity
          
        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
    
    test "state consistency across multiple math operations", %{domain: domain, state: state} do
      # Test that state remains consistent through multiple operations
      initial_value = 10.0
      state_with_value = StateV2.add_fact(state, "test", "input", initial_value)
      
      goals = [
        {:khr_math_abs, [initial_value]},
        {:khr_math_sqrt, [initial_value]},  # This will fail since not implemented yet
        {:khr_math_floor, [initial_value]}
      ]
      
      # Test individual operations work with state
      result1 = KHRInteractivityDomain.math_abs(state_with_value, [initial_value])
      assert StateV2.get_fact(result1, "output", "value") == 10.0
      assert StateV2.get_fact(result1, "test", "input") == 10.0  # Original state preserved
      
      result2 = KHRInteractivityDomain.math_floor(result1, [10.7])
      assert StateV2.get_fact(result2, "output", "value") == 10.0
      assert StateV2.get_fact(result2, "test", "input") == 10.0  # Still preserved
    end
    
    test "math operation chaining with state management", %{domain: domain, state: state} do
      # Test chaining multiple operations while managing state properly
      state_with_values = state
      |> StateV2.add_fact("math", "a", 3.5)
      |> StateV2.add_fact("math", "b", 2.1)
      |> StateV2.add_fact("math", "c", 1.4)
      
      # Compute (a + b) * c
      step1_state = KHRInteractivityDomain.math_add(state_with_values, [3.5, 2.1])
      intermediate_result = StateV2.get_fact(step1_state, "output", "value")
      
      step2_state = StateV2.add_fact(step1_state, "math", "intermediate", intermediate_result)
      final_state = KHRInteractivityDomain.math_mul(step2_state, [intermediate_result, 1.4])
      
      expected = (3.5 + 2.1) * 1.4
      actual = StateV2.get_fact(final_state, "output", "value")
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
      
      # Get all actions from domain
      registered_actions = Actions.list_actions(domain)
      registered_action_names = Enum.map(registered_actions, fn {name, _func, _meta} -> name end)
      
      # Verify each math action is registered
      Enum.each(math_actions, fn action_name ->
        assert action_name in registered_action_names, 
               "Action #{action_name} not found in registered actions"
      end)
    end
    
    test "action metadata verification", %{domain: domain} do
      # Verify that KHR actions have proper metadata
      registered_actions = Actions.list_actions(domain)
      
      khr_actions = Enum.filter(registered_actions, fn {name, _func, _meta} ->
        String.starts_with?(Atom.to_string(name), "khr_")
      end)
      
      assert length(khr_actions) > 0, "No KHR actions found"
      
      # Verify each KHR action has proper metadata
      Enum.each(khr_actions, fn {name, _func, meta} ->
        assert meta[:domain] == "khr_interactivity", 
               "Action #{name} missing khr_interactivity domain"
        assert is_binary(meta[:category]),
               "Action #{name} missing category"
        assert is_binary(meta[:khr_node_type]),
               "Action #{name} missing khr_node_type"
        assert is_binary(meta[:description]),
               "Action #{name} missing description"
      end)
    end
    
    test "error handling in planning context", %{domain: domain, state: state} do
      # Test that invalid arguments are handled gracefully
      
      # This should work fine
      valid_result = KHRInteractivityDomain.math_add(state, [1.0, 2.0])
      assert StateV2.get_fact(valid_result, "output", "value") == 3.0
      
      # Test function clause errors are caught at planning level
      assert_raise FunctionClauseError, fn ->
        KHRInteractivityDomain.math_add(state, ["invalid", "args"])
      end
      
      # But with proper numeric arguments, it should work in any state
      state_with_extra_facts = state
      |> StateV2.add_fact("extra", "data", "some_value")
      |> StateV2.add_fact("more", "nested", %{key: "value"})
      
      result = KHRInteractivityDomain.math_mul(state_with_extra_facts, [3.0, 7.0])
      assert StateV2.get_fact(result, "output", "value") == 21.0
      
      # Original state should be preserved
      assert StateV2.get_fact(result, "extra", "data") == "some_value"
      assert StateV2.get_fact(result, "more", "nested") == %{key: "value"}
    end
  end
  
  describe "STN temporal planner integration" do
    test "math nodes work with temporal constraints", %{domain: domain, state: state} do
      # This would be expanded when temporal constraints are implemented
      # For now, verify basic compatibility
      
      # Simulate temporal planning context
      timestamped_state = state
      |> StateV2.add_fact("temporal", "start_time", 0.0)
      |> StateV2.add_fact("temporal", "current_time", 1.5)
      
      # Math operations should work regardless of temporal context
      result = KHRInteractivityDomain.math_add(timestamped_state, [10.0, 5.0])
      
      assert StateV2.get_fact(result, "output", "value") == 15.0
      # Temporal facts should be preserved
      assert StateV2.get_fact(result, "temporal", "start_time") == 0.0
      assert StateV2.get_fact(result, "temporal", "current_time") == 1.5
    end
  end
  
  describe "HTN decomposition integration" do
    test "math nodes work in hierarchical task decomposition", %{domain: domain, state: state} do
      # Simulate HTN context with method decomposition
      task_state = state
      |> StateV2.add_fact("htn", "current_method", "calculate_area")
      |> StateV2.add_fact("htn", "decomposition_level", 2)
      
      # Math operations should work in HTN context
      # Calculate area of rectangle: length * width
      length = 5.0
      width = 3.5
      
      result = KHRInteractivityDomain.math_mul(task_state, [length, width])
      
      assert StateV2.get_fact(result, "output", "value") == 17.5
      # HTN context should be preserved
      assert StateV2.get_fact(result, "htn", "current_method") == "calculate_area"
      assert StateV2.get_fact(result, "htn", "decomposition_level") == 2
    end
  end
end
