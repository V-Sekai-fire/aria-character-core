# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SchedulerTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.Scheduler
  
  describe "schedule_activities/3" do
    test "handles empty activity list correctly" do
      {:ok, result} = Scheduler.schedule_activities("Empty Project", [])
      
      assert result.status == "success"
      assert result.reason == "Empty plan successfully generated - valid solution for empty todo list"
      assert result.schedule == []
      assert result.analysis.activities_analyzed == 0
      assert result.analysis.dependencies_found == 0
      assert result.analysis.resource_conflicts == 0
      assert result.analysis.circular_dependencies == 0
      assert result.analysis.critical_path_length == 0
      assert result.analysis.hybrid_planner_used == true
      assert result.analysis.empty_plan_reason == "Empty todo list results in empty plan (valid solution)"
    end
    
    test "schedules simple activities with dependencies" do
      activities = [
        %{id: "design", duration: 5, dependencies: []},
        %{id: "develop", duration: 10, dependencies: ["design"]},
        %{id: "test", duration: 3, dependencies: ["develop"]},
        %{id: "deploy", duration: 1, dependencies: ["test"]}
      ]
      
      {:ok, result} = Scheduler.schedule_activities("Website Launch", activities)
      
      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 4
      assert result.analysis.activities_analyzed == 4
      assert result.analysis.dependencies_found == 3
      assert result.analysis.schedule_name == "Website Launch"
      assert result.analysis.method =~ "Critical Path Method"
    end
    
    test "schedules activities with resources and constraints" do
      activities = [
        %{id: "task1", duration: 2, dependencies: [], resources: ["developer"]},
        %{id: "task2", duration: 3, dependencies: [], resources: ["developer"]}
      ]
      
      resources = %{developer: %{capacity: 1}}
      constraints = %{max_duration: 10}
      
      {:ok, result} = Scheduler.schedule_activities(
        "Resource Test", 
        activities,
        resources: resources,
        constraints: constraints
      )
      
      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 2
      assert result.analysis.activities_analyzed == 2
      assert result.analysis.resource_conflicts >= 0
    end
    
    test "handles verbose logging" do
      activities = [%{id: "task1", duration: 1, dependencies: []}]
      
      {:ok, result} = Scheduler.schedule_activities(
        "Verbose Test",
        activities,
        verbose: 3
      )
      
      assert result.status == "success"
      assert is_list(result.schedule)
    end
    
    test "returns analysis with correct structure" do
      activities = [
        %{id: "a", duration: 1, dependencies: []},
        %{id: "b", duration: 2, dependencies: ["a"]}
      ]
      
      {:ok, result} = Scheduler.schedule_activities("Analysis Test", activities)
      
      analysis = result.analysis
      assert is_map(analysis)
      assert Map.has_key?(analysis, :schedule_name)
      assert Map.has_key?(analysis, :method)
      assert Map.has_key?(analysis, :activities_analyzed)
      assert Map.has_key?(analysis, :dependencies_found)
      assert Map.has_key?(analysis, :resource_conflicts)
      assert Map.has_key?(analysis, :circular_dependencies)
      assert Map.has_key?(analysis, :critical_path_length)
      assert Map.has_key?(analysis, :hybrid_planner_used)
      
      assert analysis.activities_analyzed == 2
      assert analysis.dependencies_found == 1
    end
    
    test "scheduled activities have timing information" do
      activities = [
        %{id: "first", duration: 5, dependencies: []},
        %{id: "second", duration: 3, dependencies: ["first"]}
      ]
      
      {:ok, result} = Scheduler.schedule_activities("Timing Test", activities)
      
      scheduled = result.schedule
      assert length(scheduled) == 2
      
      # Check that activities have timing information
      Enum.each(scheduled, fn activity ->
        assert Map.has_key?(activity, :start_time)
        assert Map.has_key?(activity, :end_time)
        assert Map.has_key?(activity, :scheduled)
        assert activity.scheduled == true
      end)
    end
    
    test "handles activities without duration" do
      activities = [
        %{id: "no_duration", dependencies: []}
      ]
      
      {:ok, result} = Scheduler.schedule_activities("No Duration Test", activities)
      
      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 1
    end
    
    test "handles activities with empty dependencies" do
      activities = [
        %{id: "independent1", duration: 1, dependencies: []},
        %{id: "independent2", duration: 2, dependencies: []}
      ]
      
      {:ok, result} = Scheduler.schedule_activities("Independent Test", activities)
      
      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 2
      assert result.analysis.dependencies_found == 0
    end
  end
  
  describe "error handling" do
    test "handles invalid input gracefully" do
      # This should not crash, even with unusual input
      {:ok, result} = Scheduler.schedule_activities("", [])
      assert result.status == "success"
    end
  end
end
