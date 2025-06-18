#!/usr/bin/env elixir

# Brute Force MCP Temporal Scheduling Test Suite
# Tests each capability with minimal test cases

defmodule MCPBruteForceTest do
  @moduledoc """
  Minimal brute force test cases for MCP temporal scheduling capabilities.
  Each test isolates one specific feature with the smallest possible input.
  """

  require Logger

  def run_all_tests do
    IO.puts("=== MCP Temporal Scheduling Brute Force Test Suite ===")
    IO.puts("Testing each capability with minimal examples\n")

    test_cases = [
      {"Empty Plan", &test_empty_plan/0},
      {"Single Activity", &test_single_activity/0},
      {"Linear Dependency", &test_linear_dependency/0},
      {"Resource Conflict", &test_resource_conflict/0},
      {"Circular Dependency", &test_circular_dependency/0},
      {"Parallel Activities", &test_parallel_activities/0},
      {"Diamond Dependency", &test_diamond_dependency/0},
      {"Resource Sharing", &test_resource_sharing/0},
      {"Invalid Reference", &test_invalid_reference/0},
      {"Temporal Constraint", &test_temporal_constraint/0}
    ]

    results = Enum.map(test_cases, fn {name, test_func} ->
      IO.puts("Testing: #{name}")
      result = execute_test(test_func, name)
      
      case result.status do
        :success ->
          IO.puts("✅ SUCCESS: Generated schedule with #{result.schedule_length} activities")
        :failure ->
          IO.puts("❌ FAILURE: #{result.failure_reason}")
          print_expected_vs_actual(name, result)
        :expected_error ->
          IO.puts("⚠️  EXPECTED ERROR: #{Map.get(result, :reason, "Unknown")}")
        :error ->
          IO.puts("💥 UNEXPECTED ERROR: #{result.error}")
      end
      IO.puts("---")
      {name, result}
    end)

    print_summary(results)
  end

  defp execute_test(test_func, test_name \\ "Unknown") do
    try do
      request = test_func.()
      response = call_mcp_tool(request)
      analyze_response(response, test_name)
    rescue
      e ->
        %{status: :error, error: Exception.message(e), response: nil}
    end
  end

  defp call_mcp_tool(request) do
    # Simulate MCP tool call using the actual implementation
    alias AriaEngine.MCP.Tools.ScheduleActivities
    
    # Create a mock frame for the tool
    frame = %{}
    
    # Execute the tool
    case ScheduleActivities.execute(request, frame) do
      {:reply, response, _frame} ->
        # Extract the text content from the Hermes response format
        case response do
          %{content: [%{"text" => text}]} -> 
            Jason.decode!(text)
          %{content: [%{text: text}]} -> 
            Jason.decode!(text)
          %{text: text} -> 
            Jason.decode!(text)
          text when is_binary(text) -> 
            Jason.decode!(text)
          _ -> 
            %{"status" => "error", "reason" => "Invalid response format: #{inspect(response)}"}
        end
      
      other ->
        %{"status" => "error", "reason" => "Unexpected response: #{inspect(other)}"}
    end
  end

  defp analyze_response(response, test_name \\ "Unknown") do
    case response do
      %{"status" => "success"} = resp ->
        schedule = Map.get(resp, "schedule", [])
        analysis = Map.get(resp, "analysis", %{})
        
        # Special case: Empty Plan test should succeed with empty schedule
        if test_name == "Empty Plan" and length(schedule) == 0 do
          %{
            status: :success,
            response: resp,
            schedule_length: 0,
            analysis: analysis
          }
        # Check if we actually got a real schedule or just empty analysis
        elsif length(schedule) == 0 do
          %{
            status: :failure,
            response: resp,
            schedule_length: 0,
            analysis: analysis,
            failure_reason: "Expected real schedule with activities, got empty schedule (analysis-only mode)"
          }
        else
          %{
            status: :success,
            response: resp,
            schedule_length: length(schedule),
            analysis: analysis
          }
        end
      
      %{"status" => "error"} = resp ->
        %{
          status: :expected_error,
          response: resp,
          reason: Map.get(resp, "reason", "Unknown error")
        }
      
      _ ->
        %{
          status: :error,
          error: "Invalid response format",
          response: response
        }
    end
  end

  # Test Case 1: Empty Plan (Baseline)
  defp test_empty_plan do
    %{
      "schedule_name" => "Empty",
      "activities" => [],
      "resources" => %{},
      "constraints" => %{}
    }
  end

  # Test Case 2: Single Activity (Atomic Scheduling)
  defp test_single_activity do
    %{
      "schedule_name" => "Single",
      "activities" => [
        %{"id" => "A", "duration" => 1}
      ]
    }
  end

  # Test Case 3: Linear Dependency (Sequential Constraint)
  defp test_linear_dependency do
    %{
      "schedule_name" => "Linear",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]}
      ]
    }
  end

  # Test Case 4: Resource Conflict (Capacity Constraint)
  defp test_resource_conflict do
    %{
      "schedule_name" => "Conflict",
      "activities" => [
        %{"id" => "A", "duration" => 1, "resources" => ["R1"]},
        %{"id" => "B", "duration" => 1, "resources" => ["R1"]}
      ],
      "resources" => %{
        "R1" => %{"capacity" => 1}
      }
    }
  end

  # Test Case 5: Circular Dependency (Invalid Constraint)
  defp test_circular_dependency do
    %{
      "schedule_name" => "Circular",
      "activities" => [
        %{"id" => "A", "duration" => 1, "dependencies" => ["B"]},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]}
      ]
    }
  end

  # Test Case 6: Parallel Activities (Concurrent Execution)
  defp test_parallel_activities do
    %{
      "schedule_name" => "Parallel",
      "activities" => [
        %{"id" => "A", "duration" => 2},
        %{"id" => "B", "duration" => 2}
      ]
    }
  end

  # Test Case 7: Diamond Dependency (Convergent Paths)
  defp test_diamond_dependency do
    %{
      "schedule_name" => "Diamond",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["B", "C"]}
      ]
    }
  end

  # Test Case 8: Resource Sharing (Multi-Resource Activity)
  defp test_resource_sharing do
    %{
      "schedule_name" => "MultiResource",
      "activities" => [
        %{"id" => "A", "duration" => 1, "resources" => ["R1", "R2"]}
      ],
      "resources" => %{
        "R1" => %{"capacity" => 1},
        "R2" => %{"capacity" => 1}
      }
    }
  end

  # Test Case 9: Invalid Reference (Broken Dependency)
  defp test_invalid_reference do
    %{
      "schedule_name" => "Invalid",
      "activities" => [
        %{"id" => "A", "duration" => 1, "dependencies" => ["NONEXISTENT"]}
      ]
    }
  end

  # Test Case 10: Temporal Constraint (Duration Optimization)
  defp test_temporal_constraint do
    %{
      "schedule_name" => "Temporal",
      "activities" => [
        %{"id" => "A", "duration" => 5},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]}
      ],
      "constraints" => %{
        "max_duration" => 10
      }
    }
  end

  defp print_summary(results) do
    IO.puts("\n=== TEST SUMMARY ===")
    
    success_count = Enum.count(results, fn {_name, result} -> result.status == :success end)
    expected_error_count = Enum.count(results, fn {_name, result} -> result.status == :expected_error end)
    failure_count = Enum.count(results, fn {_name, result} -> result.status == :failure end)
    error_count = Enum.count(results, fn {_name, result} -> result.status == :error end)
    
    IO.puts("Total Tests: #{length(results)}")
    IO.puts("✅ Successful: #{success_count}")
    IO.puts("⚠️  Expected Errors: #{expected_error_count}")
    IO.puts("❌ Failures: #{failure_count}")
    IO.puts("💥 Unexpected Errors: #{error_count}")
    
    if failure_count > 0 do
      IO.puts("\n🚨 CRITICAL: #{failure_count} tests failed - MCP tool not generating real schedules!")
    end
    
    IO.puts("\n=== DETAILED RESULTS ===")
    Enum.each(results, fn {name, result} ->
      status_icon = case result.status do
        :success -> "✅"
        :expected_error -> "⚠️ "
        :failure -> "❌"
        :error -> "💥"
      end
      
      IO.puts("#{status_icon} #{name}: #{result.status}")
      case result.status do
        :success ->
          schedule_length = Map.get(result, :schedule_length, 0)
          analysis = Map.get(result, :analysis, %{})
          activities_analyzed = Map.get(analysis, "activities_analyzed", 0)
          IO.puts("    Schedule Length: #{schedule_length}")
          IO.puts("    Activities Analyzed: #{activities_analyzed}")
          
        :failure ->
          reason = Map.get(result, :failure_reason, "Unknown failure")
          IO.puts("    Failure: #{reason}")
          
        :expected_error ->
          reason = Map.get(result, :reason, "Unknown")
          IO.puts("    Error Reason: #{reason}")
          
        :error ->
          error = Map.get(result, :error, "Unknown")
          IO.puts("    Unexpected Error: #{error}")
      end
      IO.puts("")
    end)
    
    IO.puts("=== CAPABILITY ANALYSIS ===")
    analyze_capabilities(results)
  end

  defp analyze_capabilities(results) do
    capabilities = %{
      "Empty Plan Handling" => find_result(results, "Empty Plan"),
      "Basic Scheduling" => find_result(results, "Single Activity"),
      "Dependency Management" => find_result(results, "Linear Dependency"),
      "Resource Conflict Detection" => find_result(results, "Resource Conflict"),
      "Error Handling" => find_result(results, "Circular Dependency"),
      "Parallel Processing" => find_result(results, "Parallel Activities"),
      "Complex Dependencies" => find_result(results, "Diamond Dependency"),
      "Multi-Resource Allocation" => find_result(results, "Resource Sharing"),
      "Invalid Input Handling" => find_result(results, "Invalid Reference"),
      "Temporal Constraints" => find_result(results, "Temporal Constraint")
    }
    
    Enum.each(capabilities, fn {capability, {_name, result}} ->
      status_icon = case result.status do
        :success -> "✅"
        :expected_error -> "⚠️ "
        :failure -> "❌"
        :error -> "💥"
      end
      
      IO.puts("#{status_icon} #{capability}: #{result.status}")
    end)
  end

  defp find_result(results, name) do
    Enum.find(results, fn {result_name, _result} -> result_name == name end)
  end

  defp print_expected_vs_actual(test_name, result) do
    IO.puts("  EXPECTED: #{get_expected_schedule(test_name)}")
    IO.puts("  ACTUAL:   [] (empty schedule)")
    IO.puts("  PROBLEM:  MCP tool is in analysis-only mode, not generating real schedules")
  end

  defp get_expected_schedule(test_name) do
    case test_name do
      "Empty Plan" -> "[] (empty - this is correct)"
      "Single Activity" -> "[A(0-1)]"
      "Linear Dependency" -> "[A(0-1), B(1-2)]"
      "Resource Conflict" -> "[A(0-1), B(1-2)] or [B(0-1), A(1-2)]"
      "Circular Dependency" -> "ERROR: Circular dependency detected"
      "Parallel Activities" -> "[A(0-2), B(0-2)]"
      "Diamond Dependency" -> "[A(0-1), B(1-2), C(1-2), D(2-3)]"
      "Resource Sharing" -> "[A(0-1)]"
      "Invalid Reference" -> "ERROR: Invalid dependency reference"
      "Temporal Constraint" -> "[A(0-5), B(5-6)]"
      _ -> "Unknown expected schedule"
    end
  end
end

# Execute the test suite
MCPBruteForceTest.run_all_tests()
