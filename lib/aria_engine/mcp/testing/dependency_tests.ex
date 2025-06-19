# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.Testing.DependencyTests do
  @moduledoc """
  Dependency constraint tests for the MCP scheduler.
  
  Tests temporal ordering, complex dependency patterns, and circular dependency detection.
  """
  
  alias AriaEngine.MCP.Tools.ScheduleActivities
  
  def test_basic_dependencies(include_raw) do
    test_name = "basic_dependencies"
    
    params = %{
      "schedule_name" => "Basic Dependencies Test",
      "activities" => [
        %{
          "id" => "task_A",
          "duration" => 1.0,
          "type" => "preparation"
        },
        %{
          "id" => "task_B",
          "duration" => 2.0,
          "dependencies" => ["task_A"],
          "type" => "execution"
        }
      ]
    }
    
    result = execute_scheduler_test(params)
    
    # Analyze result
    analysis = case result do
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) and length(schedule) == 2 ->
        # Find the activities in the schedule
        task_a = Enum.find(schedule, fn act -> Map.get(act, "id") == "task_A" end)
        task_b = Enum.find(schedule, fn act -> Map.get(act, "id") == "task_B" end)
        
        case {task_a, task_b} do
          {%{"start_time" => start_a, "end_time" => end_a}, %{"start_time" => start_b}} ->
            # Check if dependency is respected: task_B should start after task_A ends
            if start_b >= end_a do
              %{
                "status" => "✅ WORKING",
                "message" => "Dependencies correctly enforced",
                "expected_behavior" => "Task B starts after Task A ends",
                "actual_behavior" => "Task A: #{start_a}-#{end_a}, Task B starts: #{start_b}"
              }
            else
              %{
                "status" => "❌ BROKEN",
                "message" => "Dependencies ignored - tasks overlap",
                "expected_behavior" => "Task B starts after Task A ends (≥#{end_a})",
                "actual_behavior" => "Task B starts at #{start_b} (violates dependency)"
              }
            end
          
          _ ->
            %{
              "status" => "❌ BROKEN",
              "message" => "Missing timing information in schedule",
              "expected_behavior" => "Activities with start/end times",
              "actual_behavior" => "Incomplete timing data"
            }
        end
      
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Wrong number of activities scheduled",
          "expected_behavior" => "2 activities scheduled",
          "actual_behavior" => "#{length(schedule)} activities scheduled"
        }
      
      %{"status" => "error"} = error ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to schedule dependent activities",
          "expected_behavior" => "2 activities with dependency ordering",
          "actual_behavior" => "Error: #{Map.get(error, "reason", "unknown")}"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "2 activities with dependency ordering",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Dependency Constraints", analysis, result, include_raw)
  end
  
  def test_complex_dependencies(include_raw) do
    test_name = "complex_dependencies"
    
    params = %{
      "schedule_name" => "Complex Dependencies Test",
      "activities" => [
        %{"id" => "A", "duration" => 1.0},
        %{"id" => "B", "duration" => 1.0, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1.0, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1.0, "dependencies" => ["B", "C"]}
      ]
    }
    
    result = execute_scheduler_test(params)
    
    # Analyze result - this is a complex test that checks diamond dependency pattern
    analysis = case result do
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) and length(schedule) == 4 ->
        # Check if the diamond dependency is respected
        activities = Map.new(schedule, fn act -> {Map.get(act, "id"), act} end)
        
        case {activities["A"], activities["B"], activities["C"], activities["D"]} do
          {%{"end_time" => end_a}, %{"start_time" => start_b}, %{"start_time" => start_c}, %{"start_time" => start_d}} ->
            b_after_a = start_b >= end_a
            c_after_a = start_c >= end_a
            d_after_bc = start_d >= max(Map.get(activities["B"], "end_time", 0), Map.get(activities["C"], "end_time", 0))
            
            if b_after_a and c_after_a and d_after_bc do
              %{
                "status" => "✅ WORKING",
                "message" => "Complex diamond dependencies correctly handled",
                "expected_behavior" => "Diamond dependency pattern (A -> B,C -> D)",
                "actual_behavior" => "All dependencies respected"
              }
            else
              %{
                "status" => "❌ BROKEN",
                "message" => "Complex dependencies violated",
                "expected_behavior" => "Diamond dependency pattern respected",
                "actual_behavior" => "Dependencies violated: B after A: #{b_after_a}, C after A: #{c_after_a}, D after B,C: #{d_after_bc}"
              }
            end
          
          _ ->
            %{
              "status" => "❌ BROKEN",
              "message" => "Missing timing information",
              "expected_behavior" => "Complete timing data for all activities",
              "actual_behavior" => "Incomplete timing information"
            }
        end
      
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Wrong number of activities scheduled",
          "expected_behavior" => "4 activities with diamond dependencies",
          "actual_behavior" => "#{length(schedule)} activities scheduled"
        }
      
      %{"status" => "error"} = error ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to handle complex dependencies",
          "expected_behavior" => "Diamond dependency pattern scheduling",
          "actual_behavior" => "Error: #{Map.get(error, "reason", "unknown")}"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "Diamond dependency pattern scheduling",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Dependency Constraints", analysis, result, include_raw)
  end
  
  def test_circular_dependencies(include_raw) do
    test_name = "circular_dependencies"
    
    params = %{
      "schedule_name" => "Circular Dependencies Test",
      "activities" => [
        %{"id" => "A", "duration" => 1.0, "dependencies" => ["B"]},
        %{"id" => "B", "duration" => 1.0, "dependencies" => ["A"]}
      ]
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => "error"} ->
        %{
          "status" => "✅ WORKING",
          "message" => "Correctly detects and rejects circular dependencies",
          "expected_behavior" => "Error on circular dependencies",
          "actual_behavior" => "Circular dependency detected and rejected"
        }
      
      %{"status" => "success", "analysis" => %{"circular_dependencies" => count}} when count > 0 ->
        %{
          "status" => "⚠️ PARTIAL",
          "message" => "Detects circular dependencies but still generates schedule",
          "expected_behavior" => "Reject circular dependencies",
          "actual_behavior" => "Detected #{count} circular dependencies but continued"
        }
      
      %{"status" => "success"} ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Fails to detect circular dependencies",
          "expected_behavior" => "Detect and reject circular dependencies",
          "actual_behavior" => "Scheduled activities with circular dependencies"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response",
          "expected_behavior" => "Detect circular dependencies",
          "actual_behavior" => "Invalid response format"
        }
    end
    
    build_test_result(test_name, "Dependency Constraints", analysis, result, include_raw)
  end
  
  def test_temporal_constraints(include_raw) do
    test_name = "temporal_constraints"
    
    params = %{
      "schedule_name" => "Temporal Constraints Test",
      "activities" => [
        %{"id" => "A", "duration" => 2.0},
        %{"id" => "B", "duration" => 1.0, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1.5, "dependencies" => ["A"]}
      ]
    }
    
    result = execute_scheduler_test(params)
    
    # Check if STN temporal constraints are working
    analysis = case result do
      %{"status" => "success", "schedule" => schedule} when length(schedule) == 3 ->
        # Check if parallel execution after A is handled correctly
        activities = Map.new(schedule, fn act -> {Map.get(act, "id"), act} end)
        
        case {activities["A"], activities["B"], activities["C"]} do
          {%{"end_time" => end_a}, %{"start_time" => start_b}, %{"start_time" => start_c}} ->
            b_after_a = start_b >= end_a
            c_after_a = start_c >= end_a
            
            if b_after_a and c_after_a do
              %{
                "status" => "✅ WORKING",
                "message" => "STN temporal constraints working correctly",
                "expected_behavior" => "B and C start after A ends, can run in parallel",
                "actual_behavior" => "Dependencies respected, parallel execution possible"
              }
            else
              %{
                "status" => "❌ BROKEN",
                "message" => "STN temporal constraints violated",
                "expected_behavior" => "B and C start after A ends",
                "actual_behavior" => "B after A: #{b_after_a}, C after A: #{c_after_a}"
              }
            end
          
          _ ->
            %{
              "status" => "❌ BROKEN",
              "message" => "Missing temporal information",
              "expected_behavior" => "Complete timing data",
              "actual_behavior" => "Incomplete timing information"
            }
        end
      
      %{"status" => "error"} = error ->
        %{
          "status" => "❌ BROKEN",
          "message" => "STN temporal constraint solving failed",
          "expected_behavior" => "Temporal constraint resolution",
          "actual_behavior" => "Error: #{Map.get(error, "reason", "unknown")}"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "Temporal constraint resolution",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Temporal Constraint Solving", analysis, result, include_raw)
  end
  
  ## Helper Functions
  
  defp execute_scheduler_test(params) do
    try do
      # Create a mock frame for the scheduler test
      frame = %{}
      
      # Execute the ScheduleActivities tool
      case ScheduleActivities.execute(params, frame) do
        {:reply, %{content: [%{text: response_text}]}, _frame} ->
          Jason.decode!(response_text)
        
        {:reply, response, _frame} ->
          %{"status" => "error", "reason" => "Unexpected response format: #{inspect(response)}"}
        
        other ->
          %{"status" => "error", "reason" => "Unexpected return value: #{inspect(other)}"}
      end
    rescue
      e ->
        %{"status" => "error", "reason" => "Exception: #{Exception.message(e)}"}
    end
  end
  
  defp build_test_result(test_name, category, analysis, result, include_raw) do
    base_result = %{
      "test_name" => test_name,
      "category" => category,
      "analysis" => analysis
    }
    
    if include_raw do
      Map.put(base_result, "raw_result", result)
    else
      base_result
    end
  end
end
