# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.Testing.BasicTests do
  @moduledoc """
  Basic scheduling tests for the MCP scheduler.
  
  Tests fundamental scheduling capabilities like empty schedules,
  single activities, multiple independent activities, and response formatting.
  """
  
  alias AriaEngine.MCP.Tools.ScheduleActivities
  
  def test_empty_schedule(include_raw) do
    test_name = "empty_schedule"
    
    params = %{
      "schedule_name" => "Empty Schedule Test",
      "activities" => [],
      "entities" => %{},
      "resources" => %{}
    }
    
    result = execute_scheduler_test(params)
    
    # Analyze result
    analysis = case result do
      %{"status" => "success", "schedule" => []} ->
        %{
          "status" => "✅ WORKING",
          "message" => "Correctly handles empty activity lists",
          "expected_behavior" => "Empty plan generation",
          "actual_behavior" => "Empty plan generated successfully"
        }
      
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) ->
        %{
          "status" => "⚠️ UNEXPECTED",
          "message" => "Generated non-empty schedule for empty activities",
          "expected_behavior" => "Empty plan generation",
          "actual_behavior" => "Generated #{length(schedule)} activities"
        }
      
      %{"status" => "error"} = error ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to handle empty activities",
          "expected_behavior" => "Empty plan generation",
          "actual_behavior" => "Error: #{Map.get(error, "reason", "unknown")}"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "Empty plan generation",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Basic Scheduling", analysis, result, include_raw)
  end
  
  def test_single_activity(include_raw) do
    test_name = "single_activity"
    
    params = %{
      "schedule_name" => "Single Activity Test",
      "activities" => [
        %{
          "id" => "task_A",
          "duration" => 2.0,
          "type" => "simple_task"
        }
      ]
    }
    
    result = execute_scheduler_test(params)
    
    # Analyze result
    analysis = case result do
      %{"status" => "success", "schedule" => [activity]} ->
        expected_duration = 2.0
        actual_duration = Map.get(activity, "duration", 0)
        
        if abs(actual_duration - expected_duration) < 0.1 do
          %{
            "status" => "✅ WORKING",
            "message" => "Correctly schedules single activity with proper duration",
            "expected_behavior" => "Single activity with 2.0 duration",
            "actual_behavior" => "Activity scheduled with #{actual_duration} duration"
          }
        else
          %{
            "status" => "⚠️ PARTIAL",
            "message" => "Schedules activity but duration mismatch",
            "expected_behavior" => "Duration: #{expected_duration}",
            "actual_behavior" => "Duration: #{actual_duration}"
          }
        end
      
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) ->
        %{
          "status" => "⚠️ UNEXPECTED",
          "message" => "Generated #{length(schedule)} activities instead of 1",
          "expected_behavior" => "Single activity scheduled",
          "actual_behavior" => "#{length(schedule)} activities generated"
        }
      
      %{"status" => "error"} = error ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to schedule single activity",
          "expected_behavior" => "Single activity scheduled",
          "actual_behavior" => "Error: #{Map.get(error, "reason", "unknown")}"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "Single activity scheduled",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Basic Scheduling", analysis, result, include_raw)
  end
  
  def test_multiple_activities_no_deps(include_raw) do
    test_name = "multiple_activities_no_deps"
    
    params = %{
      "schedule_name" => "Multiple Activities Test",
      "activities" => [
        %{"id" => "task_1", "duration" => 1.0},
        %{"id" => "task_2", "duration" => 2.0},
        %{"id" => "task_3", "duration" => 1.5}
      ]
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => "success", "schedule" => schedule} when length(schedule) == 3 ->
        %{
          "status" => "✅ WORKING",
          "message" => "Successfully schedules multiple independent activities",
          "expected_behavior" => "3 independent activities scheduled",
          "actual_behavior" => "#{length(schedule)} activities scheduled"
        }
      
      %{"status" => "success", "schedule" => schedule} ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Wrong number of activities",
          "expected_behavior" => "3 activities",
          "actual_behavior" => "#{length(schedule)} activities"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to schedule multiple activities",
          "expected_behavior" => "3 independent activities",
          "actual_behavior" => "Error or invalid response"
        }
    end
    
    build_test_result(test_name, "Basic Scheduling", analysis, result, include_raw)
  end
  
  def test_large_schedule(include_raw) do
    test_name = "large_schedule"
    
    # Generate 20 activities with various dependencies
    activities = Enum.map(1..20, fn i ->
      deps = if i > 1 and rem(i, 3) == 0 do
        ["task_#{i-1}"]
      else
        []
      end
      
      %{
        "id" => "task_#{i}",
        "duration" => :rand.uniform() * 2 + 0.5,
        "dependencies" => deps
      }
    end)
    
    params = %{
      "schedule_name" => "Large Schedule Test",
      "activities" => activities
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => "success", "schedule" => schedule} when length(schedule) == 20 ->
        %{
          "status" => "✅ WORKING",
          "message" => "Successfully handles large schedules",
          "expected_behavior" => "20 activities scheduled",
          "actual_behavior" => "All 20 activities scheduled successfully"
        }
      
      %{"status" => "success", "schedule" => schedule} ->
        %{
          "status" => "⚠️ PARTIAL",
          "message" => "Partial success with large schedule",
          "expected_behavior" => "20 activities",
          "actual_behavior" => "#{length(schedule)} activities scheduled"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to handle large schedule",
          "expected_behavior" => "20 activities scheduled",
          "actual_behavior" => "Error or invalid response"
        }
    end
    
    build_test_result(test_name, "Performance", analysis, result, include_raw)
  end
  
  def test_json_response_format(include_raw) do
    test_name = "json_response_format"
    
    params = %{
      "schedule_name" => "JSON Format Test",
      "activities" => [
        %{"id" => "test_task", "duration" => 1.0}
      ]
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => status, "schedule" => schedule, "analysis" => analysis} 
      when is_binary(status) and is_list(schedule) and is_map(analysis) ->
        %{
          "status" => "✅ WORKING",
          "message" => "JSON response format is correct",
          "expected_behavior" => "Valid JSON with required fields",
          "actual_behavior" => "All required fields present and properly typed"
        }
      
      %{"status" => _status} ->
        %{
          "status" => "⚠️ PARTIAL",
          "message" => "JSON response missing some fields",
          "expected_behavior" => "Complete JSON response structure",
          "actual_behavior" => "Some required fields missing"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Invalid JSON response format",
          "expected_behavior" => "Valid JSON response structure",
          "actual_behavior" => "Invalid or malformed response"
        }
    end
    
    build_test_result(test_name, "JSON Response Generation", analysis, result, include_raw)
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
