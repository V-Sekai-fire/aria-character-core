# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlanner.STNMethodTest do
  use ExUnit.Case, async: true
  
  alias TemporalPlanner.STNMethod
  alias TemporalPlanner.STNAction
  alias Timeline

  describe "method creation" do
    test "creates method with sequential decomposition" do
      actions = [
        STNAction.new("move", duration: {2000, 3000}),
        STNAction.new("observe", duration: {1000, 2000})
      ]
      
      method = STNMethod.new("patrol", :sequential, actions)
      
      assert method.method_id == "patrol"
      assert method.decomposition_pattern == :sequential
      assert length(method.stn_actions) == 2
      assert Timeline.consistent?(method.method_stn)
    end

    test "creates method with parallel decomposition" do
      actions = [
        STNAction.new("scan_area", duration: {3000, 4000}),
        STNAction.new("monitor_comms", duration: {2000, 5000})
      ]
      
      method = STNMethod.new("surveillance", :parallel, actions)
      
      assert method.decomposition_pattern == :parallel
      assert Timeline.consistent?(method.method_stn)
      
      # Parallel execution should have duration equal to longest action
      {min_duration, max_duration} = method.estimated_duration
      assert min_duration == 3000  # max of minimums
      assert max_duration == 5000  # max of maximums
    end

    test "creates method with alternative decomposition" do
      actions = [
        STNAction.new("route_a", duration: {5000, 7000}),
        STNAction.new("route_b", duration: {4000, 6000})
      ]
      
      method = STNMethod.new("approach", :alternative, actions)
      
      assert method.decomposition_pattern == :alternative
      assert Timeline.consistent?(method.method_stn)
      
      # Alternative execution should have average duration
      {min_duration, max_duration} = method.estimated_duration
      assert min_duration == 4500  # average of minimums
      assert max_duration == 6500  # average of maximums
    end

    test "creates method with conditional decomposition" do
      actions = [
        STNAction.new("check_status", duration: {500, 1000}),
        STNAction.new("proceed", duration: {2000, 3000})
      ]
      
      method = STNMethod.new("conditional_advance", :conditional, actions)
      
      assert method.decomposition_pattern == :conditional
      assert Timeline.consistent?(method.method_stn)
    end
  end

  describe "bridge actions" do
    test "adds bridge action to method" do
      actions = [STNAction.new("setup", duration: {1000, 2000})]
      method = STNMethod.new("operation", :sequential, actions)
      
      bridge = %{
        action_id: "decide_route", 
        type: :decision, 
        duration: :instantaneous,
        metadata: %{priority: :high}
      }
      
      updated_method = STNMethod.add_bridge_action(method, bridge)
      
      assert length(updated_method.bridge_actions) == 1
      assert hd(updated_method.bridge_actions).action_id == "decide_route"
      assert Timeline.consistent?(updated_method.method_stn)
    end

    test "bridge actions create temporal segments" do
      actions = [
        STNAction.new("phase1", duration: {1000, 2000}),
        STNAction.new("phase2", duration: {2000, 3000})
      ]
      
      method = STNMethod.new("multi_phase", :sequential, actions)
      
      bridge = %{
        action_id: "checkpoint", 
        type: :condition, 
        duration: :instantaneous
      }
      
      updated_method = STNMethod.add_bridge_action(method, bridge)
      
      # Should have temporal segments
      assert length(updated_method.temporal_segments) >= 1
    end
  end

  describe "method composition" do
    test "chains methods sequentially" do
      method1 = STNMethod.new("setup", :sequential, [
        STNAction.new("prepare", duration: {1000, 2000})
      ])
      method2 = STNMethod.new("execute", :parallel, [
        STNAction.new("perform", duration: {3000, 4000})
      ])
      
      chained_stn = STNMethod.chain([method1, method2])
      
      assert Timeline.consistent?(chained_stn)
      
      # Should have timepoints from both methods
      time_points = Timeline.time_points(chained_stn)
      assert length(time_points) >= 4  # At least start/end for each action
    end

    test "executes methods in parallel" do
      method1 = STNMethod.new("recon", :sequential, [
        STNAction.new("scout", duration: {2000, 3000})
      ])
      method2 = STNMethod.new("comms", :parallel, [
        STNAction.new("radio_check", duration: {1000, 1500})
      ])
      
      parallel_stn = STNMethod.parallel([method1, method2])
      
      assert Timeline.consistent?(parallel_stn)
    end

    test "creates alternative method choices" do
      method1 = STNMethod.new("plan_a", :sequential, [
        STNAction.new("direct_approach", duration: {5000, 6000})
      ])
      method2 = STNMethod.new("plan_b", :parallel, [
        STNAction.new("flanking_maneuver", duration: {8000, 10000})
      ])
      
      alternative_stn = STNMethod.alternative([method1, method2])
      
      assert Timeline.consistent?(alternative_stn)
    end
  end

  describe "parallel solving" do
    test "solves method segments in parallel" do
      actions = [
        STNAction.new("task1", duration: {1000, 2000}),
        STNAction.new("task2", duration: {1500, 2500}),
        STNAction.new("task3", duration: {2000, 3000})
      ]
      
      method = STNMethod.new("complex_method", :sequential, actions)
      
      solved_stn = STNMethod.solve_parallel(method)
      
      assert Timeline.consistent?(solved_stn)
    end

    test "handles empty method gracefully" do
      method = STNMethod.new("empty_method", :sequential, [])
      
      solved_stn = STNMethod.solve_parallel(method)
      
      assert Timeline.consistent?(solved_stn)
    end
  end

  describe "execution checking" do
    test "checks if method can execute" do
      actions = [STNAction.new("test_action", duration: {1000, 2000})]
      method = STNMethod.new("test_method", :sequential, actions)
      
      world_stn = Timeline.new()
      |> Timeline.add_time_point("world_start")
      |> Timeline.add_constraint("world_start", "world_start", {0, 0})
      
      assert STNMethod.can_execute?(method, world_stn)
    end

    test "updates method timing after execution" do
      actions = [STNAction.new("timed_action", duration: {1000, 2000})]
      method = STNMethod.new("timed_method", :sequential, actions)
      
      updated_method = STNMethod.update_timing(method, 
        actual_duration: 1500,
        actual_start: DateTime.utc_now(),
        actual_end: DateTime.add(DateTime.utc_now(), 1500, :millisecond)
      )
      
      assert is_list(updated_method.metadata.execution_history)
      assert length(updated_method.metadata.execution_history) == 1
    end
  end

  describe "STN conversion" do
    test "converts method to STN" do
      actions = [STNAction.new("convert_test", duration: {2000, 3000})]
      method = STNMethod.new("conversion_method", :sequential, actions)
      
      stn = STNMethod.to_stn(method)
      
      assert %Timeline{} = stn
      assert Timeline.consistent?(stn)
    end
  end
end
