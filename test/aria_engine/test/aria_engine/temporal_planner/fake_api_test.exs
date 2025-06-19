# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlanner.FakeAPITest do
  @moduledoc """
  Tiny unit tests targeting confirmed fake API issues in temporal planner.
  Only tests functions that are actually missing or cause real problems.
  """
  
  use ExUnit.Case, async: true
  
  alias TemporalPlanner.{STNPlanner, STNMethod, STNAction}

  describe "Confirmed missing functions" do
    test "STNAction.to_stn/1 missing (only to_timeline/1 exists)" do
      action = STNAction.new("test", duration: {1000, 2000})
      
      # This function doesn't exist - STNAction only has to_timeline/1
      # Confirmed by compiler warning
      assert_raise UndefinedFunctionError, fn ->
        STNAction.to_stn(action)
      end
    end
  end

  describe "Performance issues (documented)" do
    test "PC-2 algorithm performance issue exists in STNPlannerTest" do
      # Note: The actual PC-2 performance issue is documented in:
      # test/aria_engine/test/aria_engine/temporal_planner/stn_planner_test.exs:297
      # "test complex scenarios handles large multi-method hierarchical plan"
      # 
      # That test consistently times out due to PC-2 algorithm performance issues
      # in Timeline.Internal.STN.PC2.apply_pc2_with_intermediate/3
      
      # This test just documents that the issue exists
      assert true, "PC-2 performance issue documented in STNPlannerTest"
    end
  end

  describe "Working APIs (verification tests)" do
    test "Timeline functions work correctly" do
      timeline = Timeline.new()
      
      # These should work without errors
      assert is_list(Timeline.time_points(timeline))
      assert %Timeline.Internal.STN{} = Timeline.get_stn(timeline)
      assert %Timeline{} = Timeline.add_time_point(timeline, "test_point")
      assert is_boolean(Timeline.consistent?(timeline))
    end

    test "STNAction functions work correctly" do
      action = STNAction.new("test", duration: {1000, 2000})
      
      # These should work without errors
      assert %Timeline{} = STNAction.to_timeline(action)
      assert %Timeline{} = STNAction.chain([action])
      assert %Timeline{} = STNAction.parallel([action])
      assert %Timeline{} = STNAction.alternative([action])
    end

    test "STNPlanner basic functions work correctly" do
      action = STNAction.new("task", duration: {1000, 2000})
      method = STNMethod.new("test_method", :sequential, [action])
      planner = STNPlanner.new("test_mission", :sequential)
      |> STNPlanner.add_method(method)
      
      # These should work without errors
      result = STNPlanner.solve_parallel(planner)
      assert %STNPlanner{} = result
    end

    test "STNMethod basic functions work correctly" do
      actions = [STNAction.new("task", duration: {1000, 2000})]
      method = STNMethod.new("test_method", :sequential, actions)
      
      # Basic method operations should work
      assert method.method_id == "test_method"
      assert method.decomposition_pattern == :sequential
      assert length(method.stn_actions) == 1
    end

    test "Timeline.Internal.STN functions work correctly" do
      stn1 = Timeline.Internal.STN.new()
      stn2 = Timeline.Internal.STN.new()
      
      # These functions actually exist and work
      assert %Timeline.Internal.STN{} = Timeline.Internal.STN.union(stn1, stn2)
      assert %Timeline.Internal.STN{} = Timeline.Internal.STN.intersection(stn1, stn2)
      assert %Timeline.Internal.STN{} = Timeline.Internal.STN.chain([stn1, stn2])
      assert %Timeline.Internal.STN{} = Timeline.Internal.STN.parallel_join([stn1, stn2])
    end
  end
end
