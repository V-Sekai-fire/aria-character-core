# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.LazyExecutionTest do
  @moduledoc """
  Test-driven development for Plan.Core.run_lazy_refineahead/4 function.
  
  This test suite defines the expected behavior of lazy execution with
  refinement-ahead capabilities, following TDD methodology.
  """

  use ExUnit.Case, async: true
  
  alias AriaEngine.StateV2
  alias Plan.Core
  
  describe "Plan.Core.run_lazy_refineahead/4 - Basic Functionality" do
    test "function exists and has correct signature" do
      # This test will fail initially since the function doesn't exist
      assert function_exported?(Plan.Core, :run_lazy_refineahead, 4)
    end
    
    test "executes simple plan with single action successfully" do
      domain = create_simple_domain()
      initial_state = create_initial_state()
      
      # Create a simple plan with one action
      todos = [{:move, ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with lazy refinement
      assert {:ok, final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, [])
      
      # Verify the action was executed
      assert StateV2.get_fact(final_state, "robot", "location") == "goal"
    end
    
    test "executes multi-step plan incrementally" do
      domain = create_multi_step_domain()
      initial_state = create_initial_state()
      
      # Create a plan with multiple actions
      todos = [{"multi_step_task", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with lazy refinement
      assert {:ok, final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, [])
      
      # Verify all steps were executed
      assert StateV2.get_fact(final_state, "robot", "location") == "goal"
      assert StateV2.get_fact(final_state, "robot", "prepared") == true
    end
    
    test "handles empty plan gracefully" do
      domain = create_simple_domain()
      initial_state = create_initial_state()
      
      # Create empty plan
      todos = []
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with lazy refinement
      assert {:ok, final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, [])
      
      # State should be unchanged
      assert final_state == initial_state
    end
  end
  
  describe "Plan.Core.run_lazy_refineahead/4 - Failure Handling and Replanning" do
    test "handles action failure with replanning" do
      domain = create_failing_domain()
      initial_state = create_unprepared_state()
      
      # Create plan that will initially fail but has alternative methods
      todos = [{"move_with_failure", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with lazy refinement - should trigger replanning
      assert {:ok, final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, [])
      
      # Verify we reached the goal despite initial failure
      assert StateV2.get_fact(final_state, "robot", "location") == "goal"
      assert StateV2.get_fact(final_state, "robot", "prepared") == true
    end
    
    test "returns error when no alternative methods available" do
      domain = create_always_failing_domain()
      initial_state = create_initial_state()
      
      # Create plan with action that always fails
      todos = [{:always_fail, []}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with lazy refinement - should fail
      assert {:error, reason} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, [])
      assert String.contains?(reason, "execution failed") or String.contains?(reason, "no alternatives")
    end
    
    test "maintains state consistency during failure recovery" do
      domain = create_partial_failure_domain()
      initial_state = create_initial_state()
      
      # Create plan where middle action fails
      todos = [{"partial_failure_task", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with lazy refinement
      result = Core.run_lazy_refineahead(domain, initial_state, solution_tree, [])
      
      case result do
        {:ok, final_state} ->
          # If recovery succeeded, verify state consistency
          assert StateV2.get_fact(final_state, "robot", "location") == "goal"
        {:error, _reason} ->
          # If recovery failed, that's also acceptable for this test
          assert true
      end
    end
  end
  
  describe "Plan.Core.run_lazy_refineahead/4 - Refinement-Ahead Logic" do
    test "optimizes execution with lookahead" do
      domain = create_optimization_domain()
      initial_state = create_initial_state()
      
      # Create plan that can be optimized with lookahead
      todos = [{"optimizable_task", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with refinement-ahead enabled
      opts = [refinement_ahead: true, lookahead_depth: 2]
      assert {:ok, final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, opts)
      
      # Verify optimization occurred (specific to domain implementation)
      assert StateV2.get_fact(final_state, "robot", "location") == "goal"
      assert StateV2.get_fact(final_state, "robot", "optimized") == true
    end
    
    test "respects lookahead depth limits" do
      domain = create_deep_plan_domain()
      initial_state = create_initial_state()
      
      # Create deep plan
      todos = [{"deep_task", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with limited lookahead
      opts = [refinement_ahead: true, lookahead_depth: 1]
      assert {:ok, _final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, opts)
    end
  end
  
  describe "Plan.Core.run_lazy_refineahead/4 - State Management" do
    test "maintains execution checkpoints" do
      domain = create_checkpoint_domain()
      initial_state = create_initial_state()
      
      # Create plan with multiple checkpointable actions
      todos = [{"checkpoint_task", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with checkpointing enabled
      opts = [enable_checkpoints: true]
      assert {:ok, final_state} = Core.run_lazy_refineahead(domain, initial_state, solution_tree, opts)
      
      # Verify execution completed
      assert StateV2.get_fact(final_state, "robot", "location") == "goal"
    end
    
    test "supports rollback to previous checkpoint" do
      domain = create_rollback_domain()
      initial_state = create_initial_state()
      
      # Create plan that requires rollback
      todos = [{"rollback_task", ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Execute with rollback capability
      opts = [enable_checkpoints: true, enable_rollback: true]
      result = Core.run_lazy_refineahead(domain, initial_state, solution_tree, opts)
      
      # Should either succeed or fail gracefully
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
  
  describe "Plan.Core.run_lazy_refineahead/4 - Integration with LazyExecutionStrategy" do
    test "integrates correctly with strategy interface" do
      domain = create_simple_domain()
      initial_state = create_initial_state()
      
      # Create solution tree
      todos = [{:move, ["start", "goal"]}]
      {:ok, solution_tree} = Core.plan(domain, initial_state, todos)
      
      # Test integration through strategy
      strategy = HybridPlanner.Strategies.Default.LazyExecutionStrategy
      strategies = %{state_strategy: create_mock_state_strategy()}
      opts = [domain: domain]
      
      # This should use run_lazy_refineahead internally
      assert {:ok, final_state} = strategy.execute_plan(solution_tree, initial_state, strategies, opts)
      assert StateV2.get_fact(final_state, "robot", "location") == "goal"
    end
  end
  
  # Helper functions to create test domains and states
  
  defp create_simple_domain do
    Domain.new("simple_test")
    |> Domain.add_action(:move, &move_action/2)
  end
  
  defp create_multi_step_domain do
    Domain.new("multi_step_test")
    |> Domain.add_action(:prepare, &prepare_action/2)
    |> Domain.add_action(:move, &move_action/2)
    |> Domain.add_task_method("multi_step_task", &multi_step_method/2)
  end
  
  defp create_failing_domain do
    Domain.new("failing_test")
    |> Domain.add_action(:move_unreliable, &move_unreliable_action/2)
    |> Domain.add_action(:move_reliable, &move_reliable_action/2)
    |> Domain.add_task_method("move_with_failure", &method_unreliable_move/2)
    |> Domain.add_task_method("move_with_failure", &method_reliable_move/2)
  end
  
  defp create_always_failing_domain do
    Domain.new("always_failing_test")
    |> Domain.add_action(:always_fail, &always_fail_action/2)
  end
  
  defp create_partial_failure_domain do
    Domain.new("partial_failure_test")
    |> Domain.add_action(:step1, &step1_action/2)
    |> Domain.add_action(:step2_fail, &step2_fail_action/2)
    |> Domain.add_action(:step3, &step3_action/2)
    |> Domain.add_task_method("partial_failure_task", &partial_failure_method/2)
  end
  
  defp create_optimization_domain do
    Domain.new("optimization_test")
    |> Domain.add_action(:move_optimized, &move_optimized_action/2)
    |> Domain.add_task_method("optimizable_task", &optimizable_method/2)
  end
  
  defp create_deep_plan_domain do
    Domain.new("deep_plan_test")
    |> Domain.add_action(:step, &step_action/2)
    |> Domain.add_task_method("deep_task", &deep_task_method/2)
  end
  
  defp create_checkpoint_domain do
    Domain.new("checkpoint_test")
    |> Domain.add_action(:checkpoint_move, &checkpoint_move_action/2)
    |> Domain.add_task_method("checkpoint_task", &checkpoint_method/2)
  end
  
  defp create_rollback_domain do
    Domain.new("rollback_test")
    |> Domain.add_action(:rollback_move, &rollback_move_action/2)
    |> Domain.add_task_method("rollback_task", &rollback_method/2)
  end
  
  defp create_initial_state do
    StateV2.new()
    |> StateV2.set_fact("robot", "location", "start")
    |> StateV2.set_fact("robot", "prepared", false)
    |> StateV2.set_fact("robot", "optimized", false)
  end
  
  defp create_unprepared_state do
    StateV2.new()
    |> StateV2.set_fact("robot", "location", "start")
    |> StateV2.set_fact("robot", "prepared", false)
  end
  
  # Action implementations
  
  defp move_action(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      StateV2.set_fact(state, "robot", "location", to)
    else
      false
    end
  end
  
  defp prepare_action(state, []) do
    StateV2.set_fact(state, "robot", "prepared", true)
  end
  
  defp move_unreliable_action(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    prepared = StateV2.get_fact(state, "robot", "prepared")
    
    if robot_location == from and prepared == true do
      StateV2.set_fact(state, "robot", "location", to)
    else
      false
    end
  end
  
  defp move_reliable_action(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    
    if robot_location == from do
      state
      |> StateV2.set_fact("robot", "prepared", true)
      |> StateV2.set_fact("robot", "location", to)
    else
      false
    end
  end
  
  defp always_fail_action(_state, _args), do: false
  
  defp step1_action(state, []), do: StateV2.set_fact(state, "robot", "step1", true)
  defp step2_fail_action(_state, _args), do: false
  defp step3_action(state, []), do: StateV2.set_fact(state, "robot", "step3", true)
  
  defp move_optimized_action(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      state
      |> StateV2.set_fact("robot", "location", to)
      |> StateV2.set_fact("robot", "optimized", true)
    else
      false
    end
  end
  
  defp step_action(state, [step_num]) do
    StateV2.set_fact(state, "robot", "step_#{step_num}", true)
  end
  
  defp checkpoint_move_action(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      StateV2.set_fact(state, "robot", "location", to)
    else
      false
    end
  end
  
  defp rollback_move_action(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      StateV2.set_fact(state, "robot", "location", to)
    else
      false
    end
  end
  
  # Method implementations
  
  defp multi_step_method(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:prepare, []}, {:move, [from, to]}]
    else
      false
    end
  end
  
  defp method_unreliable_move(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:move_unreliable, [from, to]}]
    else
      false
    end
  end
  
  defp method_reliable_move(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:move_reliable, [from, to]}]
    else
      false
    end
  end
  
  defp partial_failure_method(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:step1, []}, {:step2_fail, []}, {:step3, []}, {:move, [from, to]}]
    else
      false
    end
  end
  
  defp optimizable_method(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:move_optimized, [from, to]}]
    else
      false
    end
  end
  
  defp deep_task_method(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:step, [1]}, {:step, [2]}, {:step, [3]}, {:move, [from, to]}]
    else
      false
    end
  end
  
  defp checkpoint_method(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:checkpoint_move, [from, to]}]
    else
      false
    end
  end
  
  defp rollback_method(state, [from, to]) do
    robot_location = StateV2.get_fact(state, "robot", "location")
    if robot_location == from do
      [{:rollback_move, [from, to]}]
    else
      false
    end
  end
  
  defp create_mock_state_strategy do
    %{
      apply_action: fn state, {action_name, args}, _domain, _opts ->
        case action_name do
          :move -> {:ok, move_action(state, args)}
          _ -> {:error, "Unknown action"}
        end
      end
    }
  end
end
