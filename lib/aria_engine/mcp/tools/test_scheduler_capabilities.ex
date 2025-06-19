# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.Tools.TestSchedulerCapabilities do
  @moduledoc """
  Comprehensive self-test system for the MCP scheduler capabilities.
  
  Runs a battery of tests to determine exactly what scheduling features work,
  what's partially functional, and what's completely broken. Provides honest
  reporting so users know what to expect before attempting real scheduling tasks.
  """
  
  use Hermes.Server.Component, type: :tool
  
  alias AriaEngine.MCP.Testing.{BasicTests, DependencyTests, EntityTests, ResourceTests}
  alias Hermes.Server.Response
  
  require Logger
  
  schema do
    field :test_level, :string, description: "Test depth: 'quick' (basic tests), 'comprehensive' (all tests), 'specific' (named test only)"
    field :specific_test, :string, description: "Run only this specific test (when test_level is 'specific')"
    field :include_raw_results, :boolean, description: "Include raw test outputs in results (default: false)"
  end
  
  @impl true
  def execute(params, frame) do
    test_level = Map.get(params, "test_level", "quick")
    specific_test = Map.get(params, "specific_test")
    include_raw = Map.get(params, "include_raw_results", false)
    
    # Run the appropriate test suite
    test_results = case test_level do
      "quick" -> run_quick_tests(include_raw)
      "comprehensive" -> run_comprehensive_tests(include_raw)
      "specific" -> run_specific_test(specific_test, include_raw)
      _ -> run_quick_tests(include_raw)
    end
    
    # Generate capability report
    capability_report = generate_capability_report(test_results)
    
    # Create response
    response_content = %{
      "status" => "success",
      "test_level" => test_level,
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "capability_report" => capability_report,
      "test_results" => test_results,
      "recommendations" => generate_recommendations(test_results)
    }
    
    response_text = Jason.encode!(response_content, pretty: true)
    {:reply, Response.text(Response.tool(), response_text), frame}
  end
  
  ## Test Suites
  
  defp run_quick_tests(include_raw) do
    [
      BasicTests.test_empty_schedule(include_raw),
      BasicTests.test_single_activity(include_raw),
      DependencyTests.test_basic_dependencies(include_raw),
      EntityTests.test_entity_capability_matching(include_raw),
      ResourceTests.test_resource_conflicts(include_raw)
    ]
  end
  
  defp run_comprehensive_tests(include_raw) do
    [
      BasicTests.test_empty_schedule(include_raw),
      BasicTests.test_single_activity(include_raw),
      BasicTests.test_multiple_activities_no_deps(include_raw),
      DependencyTests.test_basic_dependencies(include_raw),
      DependencyTests.test_complex_dependencies(include_raw),
      DependencyTests.test_circular_dependencies(include_raw),
      EntityTests.test_entity_capability_matching(include_raw),
      EntityTests.test_mixed_entity_types(include_raw),
      ResourceTests.test_resource_conflicts(include_raw),
      ResourceTests.test_resource_ownership(include_raw),
      BasicTests.test_large_schedule(include_raw),
      BasicTests.test_json_response_format(include_raw)
    ]
  end
  
  defp run_specific_test(test_name, include_raw) do
    case test_name do
      "empty_schedule" -> [BasicTests.test_empty_schedule(include_raw)]
      "single_activity" -> [BasicTests.test_single_activity(include_raw)]
      "basic_dependencies" -> [DependencyTests.test_basic_dependencies(include_raw)]
      "entity_capability_matching" -> [EntityTests.test_entity_capability_matching(include_raw)]
      "resource_conflicts" -> [ResourceTests.test_resource_conflicts(include_raw)]
      "complex_dependencies" -> [DependencyTests.test_complex_dependencies(include_raw)]
      _ -> [%{
        "test_name" => "unknown_test",
        "status" => "error",
        "message" => "Unknown test: #{test_name}",
        "available_tests" => list_available_tests()
      }]
    end
  end
  
  defp list_available_tests do
    [
      "empty_schedule",
      "single_activity", 
      "basic_dependencies",
      "complex_dependencies",
      "circular_dependencies",
      "entity_capability_matching",
      "mixed_entity_types",
      "resource_conflicts",
      "resource_ownership"
    ]
  end
  
  ## Report Generation
  
  defp generate_capability_report(test_results) do
    # Group tests by category and analyze overall status
    categories = Enum.group_by(test_results, &Map.get(&1, "category"))
    
    category_reports = Enum.map(categories, fn {category, tests} ->
      statuses = Enum.map(tests, fn test -> 
        Map.get(test, "analysis", %{}) |> Map.get("status", "❌ BROKEN")
      end)
      
      working_count = Enum.count(statuses, &String.starts_with?(&1, "✅"))
      partial_count = Enum.count(statuses, &String.starts_with?(&1, "⚠️"))
      broken_count = Enum.count(statuses, &String.starts_with?(&1, "❌"))
      total_count = length(statuses)
      
      overall_status = cond do
        working_count == total_count -> "✅ WORKING"
        working_count + partial_count == total_count -> "⚠️ PARTIAL"
        working_count > 0 -> "⚠️ MIXED"
        true -> "❌ BROKEN"
      end
      
      %{
        "category" => category,
        "overall_status" => overall_status,
        "working" => working_count,
        "partial" => partial_count,
        "broken" => broken_count,
        "total" => total_count,
        "tests" => Enum.map(tests, fn test ->
          %{
            "name" => Map.get(test, "test_name"),
            "status" => Map.get(test, "analysis", %{}) |> Map.get("status", "❌ BROKEN"),
            "message" => Map.get(test, "analysis", %{}) |> Map.get("message", "Unknown")
          }
        end)
      }
    end)
    
    # Generate overall summary
    all_statuses = Enum.flat_map(category_reports, fn cat -> 
      Enum.map(cat["tests"], &Map.get(&1, "status"))
    end)
    
    total_working = Enum.count(all_statuses, &String.starts_with?(&1, "✅"))
    total_partial = Enum.count(all_statuses, &String.starts_with?(&1, "⚠️"))
    total_broken = Enum.count(all_statuses, &String.starts_with?(&1, "❌"))
    total_tests = length(all_statuses)
    
    overall_health = cond do
      total_working >= total_tests * 0.8 -> "✅ HEALTHY"
      total_working >= total_tests * 0.5 -> "⚠️ PARTIAL"
      total_working > 0 -> "⚠️ POOR"
      true -> "❌ CRITICAL"
    end
    
    %{
      "overall_health" => overall_health,
      "summary" => %{
        "total_tests" => total_tests,
        "working" => total_working,
        "partial" => total_partial,
        "broken" => total_broken,
        "success_rate" => if(total_tests > 0, do: Float.round(total_working / total_tests * 100, 1), else: 0)
      },
      "categories" => category_reports
    }
  end
  
  defp generate_recommendations(test_results) do
    # Analyze test results and generate specific recommendations
    broken_tests = Enum.filter(test_results, fn test ->
      status = Map.get(test, "analysis", %{}) |> Map.get("status", "")
      String.starts_with?(status, "❌")
    end)
    
    partial_tests = Enum.filter(test_results, fn test ->
      status = Map.get(test, "analysis", %{}) |> Map.get("status", "")
      String.starts_with?(status, "⚠️")
    end)
    
    recommendations = []
    
    # Check for dependency issues
    dependency_broken = Enum.any?(broken_tests, fn test ->
      Map.get(test, "category") == "Dependency Constraints"
    end)
    
    recommendations = if dependency_broken do
      ["❌ CRITICAL: Dependency constraints are broken - avoid using for projects requiring task ordering" | recommendations]
    else
      recommendations
    end
    
    # Check for entity capability issues
    entity_issues = Enum.any?(broken_tests ++ partial_tests, fn test ->
      Map.get(test, "category") == "Entity-Capability Matching"
    end)
    
    recommendations = if entity_issues do
      ["⚠️ WARNING: Entity-capability matching has issues - verify assignments manually" | recommendations]
    else
      ["✅ SAFE: Entity-capability matching works well" | recommendations]
    end
    
    # Check for resource management
    resource_working = Enum.any?(test_results, fn test ->
      Map.get(test, "category") == "Resource Management" and
      String.starts_with?(Map.get(test, "analysis", %{}) |> Map.get("status", ""), "✅")
    end)
    
    recommendations = if resource_working do
      ["✅ SAFE: Resource conflict detection is working" | recommendations]
    else
      ["❌ AVOID: Resource management is unreliable" | recommendations]
    end
    
    # Add general recommendations
    working_count = Enum.count(test_results, fn test ->
      String.starts_with?(Map.get(test, "analysis", %{}) |> Map.get("status", ""), "✅")
    end)
    
    recommendations = if working_count >= length(test_results) * 0.7 do
      ["✅ RECOMMENDED: Scheduler is suitable for basic scheduling tasks" | recommendations]
    else
      ["❌ NOT RECOMMENDED: Too many critical issues for production use" | recommendations]
    end
    
    if length(recommendations) == 0 do
      ["Run comprehensive tests for detailed analysis"]
    else
      Enum.reverse(recommendations)
    end
  end
end
