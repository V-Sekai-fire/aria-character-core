# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Verification.ControlFlowVerificationTest do
  @moduledoc """
  KHR_interactivity Control Flow Specification Verification Tests
  
  Verifies that control flow implementations match exact KHR specification requirements:
  - Socket ordering and activation semantics
  - Condition evaluation logic
  - Configuration-based behavior
  - Timing and iteration handling
  """

  use ExUnit.Case
  alias StateV2
  alias NodeLibrary.KHRInteractivity.ControlFlow
  alias NodeLibrary.KHRInteractivity.Support.GLTFSceneMock

  describe "flow/sequence specification compliance" do
    test "socket ordering and activation semantics" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # KHR spec: flow/sequence activates operations in order, one after another
      operations = [
        ["math/add", 101, 2.0, 3.0],
        ["math/mul", 102, 4.0, 5.0], 
        ["math/sub", 103, 10.0, 1.0]
      ]
      
      result_state = ControlFlow.flow_sequence(state, [100, operations])
      
      # Verify sequence completion tracking
      assert StateV2.get_fact(result_state, "100", "completed") == true
      
      # Verify results are stored in execution order
      results = StateV2.get_fact(result_state, "100", "results")
      assert length(results) == 3
      
      # Each operation should have been "executed" (mocked execution)
      assert Enum.all?(results, fn result ->
        case result do
          {:executed, _operation} -> true
          _ -> false
        end
      end)
    end

    test "empty sequence handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      result_state = ControlFlow.flow_sequence(state, [200, []])
      
      # Empty sequence should still complete successfully
      assert StateV2.get_fact(result_state, "200", "results") == []
      assert StateV2.get_fact(result_state, "200", "completed") == true
    end

    test "sequence with invalid operations" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      result_state = ControlFlow.flow_sequence(state, [300, "invalid_operations"])
      
      # Invalid input should result in non-completion
      assert StateV2.get_fact(result_state, "300", "completed") == false
    end
  end

  describe "flow/branch specification compliance" do
    test "condition evaluation with boolean values" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # True condition
      result_state_true = ControlFlow.flow_branch(state, [400, true, "true_value", "false_value"])
      assert StateV2.get_fact(result_state_true, "400", "value") == "true_value"
      assert StateV2.get_fact(result_state_true, "400", "condition_result") == true
      
      # False condition
      result_state_false = ControlFlow.flow_branch(state, [401, false, "true_value", "false_value"])
      assert StateV2.get_fact(result_state_false, "401", "value") == "false_value"
      assert StateV2.get_fact(result_state_false, "401", "condition_result") == false
    end

    test "condition evaluation with numeric values" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Non-zero number (truthy)
      result_state_nonzero = ControlFlow.flow_branch(state, [500, 5.0, "truthy", "falsy"])
      assert StateV2.get_fact(result_state_nonzero, "500", "value") == "truthy"
      assert StateV2.get_fact(result_state_nonzero, "500", "condition_result") == true
      
      # Zero (falsy)
      result_state_zero = ControlFlow.flow_branch(state, [501, 0, "truthy", "falsy"])
      assert StateV2.get_fact(result_state_zero, "501", "value") == "falsy"
      assert StateV2.get_fact(result_state_zero, "501", "condition_result") == false
    end

    test "single-branch form (if-then)" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # True condition - should execute then branch
      result_state_true = ControlFlow.flow_branch(state, [600, true, "executed"])
      assert StateV2.get_fact(result_state_true, "600", "value") == "executed"
      
      # False condition - should return nil
      result_state_false = ControlFlow.flow_branch(state, [601, false, "executed"])
      assert StateV2.get_fact(result_state_false, "601", "value") == nil
    end

    test "condition evaluation edge cases" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Nil condition (falsy)
      result_state_nil = ControlFlow.flow_branch(state, [700, nil, "truthy", "falsy"])
      assert StateV2.get_fact(result_state_nil, "700", "value") == "falsy"
      assert StateV2.get_fact(result_state_nil, "700", "condition_result") == false
      
      # Non-boolean, non-numeric value (truthy by default)
      result_state_string = ControlFlow.flow_branch(state, [701, "hello", "truthy", "falsy"])
      assert StateV2.get_fact(result_state_string, "701", "value") == "truthy"
      assert StateV2.get_fact(result_state_string, "701", "condition_result") == true
    end
  end

  describe "flow/switch specification compliance" do
    test "case matching with exact values" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      cases = [
        {"option_a", "result_a"},
        {"option_b", "result_b"},
        {"option_c", "result_c"}
      ]
      
      # Matching case
      result_state_match = ControlFlow.flow_switch(state, [800, "option_b", cases])
      assert StateV2.get_fact(result_state_match, "800", "value") == "result_b"
      assert StateV2.get_fact(result_state_match, "800", "selected_case") == "option_b"
      
      # Non-matching case (should return default)
      result_state_no_match = ControlFlow.flow_switch(state, [801, "option_d", cases])
      assert StateV2.get_fact(result_state_no_match, "801", "value") == nil
      assert StateV2.get_fact(result_state_no_match, "801", "selected_case") == "option_d"
    end

    test "default case handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      cases_with_default = [
        {"option_a", "result_a"},
        {"option_b", "result_b"},
        {:default, "default_result"}
      ]
      
      # Non-matching case should use default
      result_state = ControlFlow.flow_switch(state, [900, "unknown_option", cases_with_default])
      assert StateV2.get_fact(result_state, "900", "value") == "default_result"
    end

    test "numeric selector values" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      numeric_cases = [
        {0, "zero"},
        {1, "one"},
        {2, "two"}
      ]
      
      result_state = ControlFlow.flow_switch(state, [1000, 1, numeric_cases])
      assert StateV2.get_fact(result_state, "1000", "value") == "one"
      assert StateV2.get_fact(result_state, "1000", "selected_case") == 1
    end

    test "invalid cases handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      result_state = ControlFlow.flow_switch(state, [1100, "selector", "invalid_cases"])
      assert StateV2.get_fact(result_state, "1100", "value") == nil
    end
  end

  describe "flow/select specification compliance" do
    test "index-based value selection" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      values = ["first", "second", "third", "fourth"]
      
      # Valid indices
      result_state_0 = ControlFlow.flow_select(state, [1200, 0, values])
      assert StateV2.get_fact(result_state_0, "1200", "value") == "first"
      assert StateV2.get_fact(result_state_0, "1200", "selected_index") == 0
      
      result_state_2 = ControlFlow.flow_select(state, [1201, 2, values])
      assert StateV2.get_fact(result_state_2, "1201", "value") == "third"
      assert StateV2.get_fact(result_state_2, "1201", "selected_index") == 2
    end

    test "out-of-bounds index handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      values = ["a", "b", "c"]
      
      # Negative index
      result_state_negative = ControlFlow.flow_select(state, [1300, -1, values])
      assert StateV2.get_fact(result_state_negative, "1300", "value") == nil
      assert StateV2.get_fact(result_state_negative, "1300", "selected_index") == -1
      
      # Index too large
      result_state_large = ControlFlow.flow_select(state, [1301, 5, values])
      assert StateV2.get_fact(result_state_large, "1301", "value") == nil
      assert StateV2.get_fact(result_state_large, "1301", "selected_index") == 5
    end

    test "empty values list" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      result_state = ControlFlow.flow_select(state, [1400, 0, []])
      assert StateV2.get_fact(result_state, "1400", "value") == nil
      assert StateV2.get_fact(result_state, "1400", "selected_index") == 0
    end

    test "invalid input handling" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Non-integer index
      result_state_invalid_index = ControlFlow.flow_select(state, [1500, "invalid", ["a", "b"]])
      assert StateV2.get_fact(result_state_invalid_index, "1500", "value") == nil
      
      # Non-list values
      result_state_invalid_values = ControlFlow.flow_select(state, [1501, 0, "not_a_list"])
      assert StateV2.get_fact(result_state_invalid_values, "1501", "value") == nil
    end
  end

  describe "flow/loop specification compliance" do
    test "fixed iteration count" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      operation = ["math/add", 0, 1, 1]  # Simple addition operation
      
      result_state = ControlFlow.flow_loop(state, [1600, 3, operation])
      
      # Should complete successfully
      assert StateV2.get_fact(result_state, "1600", "completed") == true
      assert StateV2.get_fact(result_state, "1600", "iterations") == 3
      
      # Should have results for each iteration
      results = StateV2.get_fact(result_state, "1600", "results")
      assert length(results) == 3
      
      # Each iteration should provide context
      assert Enum.all?(results, fn result ->
        case result do
          {:executed, _operation, %{iteration: _}} -> true
          _ -> false
        end
      end)
    end

    test "zero and negative iteration counts" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      operation = ["math/add", 0, 1, 1]
      
      # Zero iterations
      result_state_zero = ControlFlow.flow_loop(state, [1700, 0, operation])
      assert StateV2.get_fact(result_state_zero, "1700", "completed") == false
      
      # Negative iterations
      result_state_negative = ControlFlow.flow_loop(state, [1701, -5, operation])
      assert StateV2.get_fact(result_state_negative, "1701", "completed") == false
    end

    test "invalid loop parameters" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Non-integer count
      result_state = ControlFlow.flow_loop(state, [1800, "invalid", ["operation"]])
      assert StateV2.get_fact(result_state, "1800", "completed") == false
    end
  end

  describe "flow/while specification compliance" do
    test "condition-based iteration with max limit" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Mock condition that will be true for a few iterations then false
      condition_check = fn -> true end  # Simplified for testing
      operation = ["math/increment", 0]
      
      result_state = ControlFlow.flow_while(state, [1900, condition_check, operation, 5])
      
      # Should complete (though condition logic is simplified in test)
      assert StateV2.get_fact(result_state, "1900", "completed") == true
      
      # Should track iterations
      iterations = StateV2.get_fact(result_state, "1900", "iterations")
      assert is_integer(iterations)
      assert iterations >= 0
    end

    test "default while loop behavior" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Test default max iterations (100)
      condition_check = fn -> false end  # Immediate false to prevent long execution
      operation = ["math/noop", 0]
      
      result_state = ControlFlow.flow_while(state, [2000, condition_check, operation])
      
      assert StateV2.get_fact(result_state, "2000", "completed") == true
      assert StateV2.get_fact(result_state, "2000", "iterations") == 0
    end

    test "max iteration protection" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Condition that would always be true - should be limited by max_iterations
      condition_check = fn -> true end  
      operation = ["math/noop", 0]
      
      result_state = ControlFlow.flow_while(state, [2100, condition_check, operation, 3])
      
      # Should complete due to max iteration limit
      assert StateV2.get_fact(result_state, "2100", "completed") == true
      assert StateV2.get_fact(result_state, "2100", "iterations") == 3
    end
  end

  describe "KHR specification integration tests" do
    test "nested control flow operations" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Sequence containing branches and switches
      nested_operations = [
        ["flow/branch", 3001, true, "branch_result"],
        ["flow/switch", 3002, "option_a", [{"option_a", "switch_result"}]],
        ["flow/select", 3003, 1, ["zero", "one", "two"]]
      ]
      
      result_state = ControlFlow.flow_sequence(state, [3000, nested_operations])
      
      # Sequence should complete
      assert StateV2.get_fact(result_state, "3000", "completed") == true
      
      # All nested operations should be "executed"
      results = StateV2.get_fact(result_state, "3000", "results")
      assert length(results) == 3
    end

    test "control flow with glTF scene interaction" do
      state = GLTFSceneMock.setup_state_with_scene()
      
      # Use node properties in control flow decisions
      node_translation = GLTFSceneMock.get_node_property(state, "head", "translation")
      y_position = Enum.at(node_translation, 1)  # Y component
      
      # Branch based on node height
      condition = y_position > 1.0
      
      result_state = ControlFlow.flow_branch(state, [4000, condition, "head_is_high", "head_is_low"])
      
      # Should evaluate correctly based on head node Y position (1.8)
      assert StateV2.get_fact(result_state, "4000", "value") == "head_is_high"
      assert StateV2.get_fact(result_state, "4000", "condition_result") == true
    end
  end
end
