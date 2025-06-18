#!/usr/bin/env elixir

# Incremental Complexity Scaling Test Suite
# Systematically increases problem complexity across multiple dimensions

defmodule IncrementalScalingTest do
  @moduledoc """
  Systematic scaling test that increases complexity gradually across:
  - Activity count (1 → 2 → 3 → 4 → 5 → 8 → 10 → 32 → 64)
  - Dependency complexity (none → linear → tree → DAG → complex)
  - Resource constraints (none → single → multiple → conflicts)
  - Temporal complexity (uniform → variable → mixed)
  """

  require Logger

  def run_all_tests do
    IO.puts("=== Incremental Complexity Scaling Test Suite ===")
    IO.puts("Testing gradual complexity increase across multiple dimensions\n")

    # Phase 1: Activity Count Scaling (keeping other dimensions simple)
    IO.puts("🔢 PHASE 1: Activity Count Scaling")
    activity_scaling_tests = [
      {"1 Activity", &test_1_activity/0},
      {"2 Activities", &test_2_activities/0},
      {"3 Activities", &test_3_activities/0},
      {"4 Activities", &test_4_activities/0},
      {"5 Activities", &test_5_activities/0},
      {"8 Activities", &test_8_activities/0},
      {"10 Activities", &test_10_activities/0},
      {"32 Activities", &test_32_activities/0},
      {"64 Activities", &test_64_activities/0}
    ]
    
    phase1_results = run_test_phase(activity_scaling_tests)
    
    # Phase 2: Dependency Complexity Scaling (fixed at 4 activities)
    IO.puts("\n🔗 PHASE 2: Dependency Complexity Scaling")
    dependency_scaling_tests = [
      {"4 Parallel", &test_4_parallel/0},
      {"4 Linear Chain", &test_4_linear_chain/0},
      {"4 Tree Structure", &test_4_tree_structure/0},
      {"4 Diamond DAG", &test_4_diamond_dag/0},
      {"4 Complex DAG", &test_4_complex_dag/0}
    ]
    
    phase2_results = run_test_phase(dependency_scaling_tests)
    
    # Phase 3: Resource Constraint Scaling (fixed at 4 activities)
    IO.puts("\n🏭 PHASE 3: Resource Constraint Scaling")
    resource_scaling_tests = [
      {"4 No Resources", &test_4_no_resources/0},
      {"4 Single Resource", &test_4_single_resource/0},
      {"4 Multiple Resources", &test_4_multiple_resources/0},
      {"4 Resource Conflicts", &test_4_resource_conflicts/0},
      {"4 Capacity Limits", &test_4_capacity_limits/0}
    ]
    
    phase3_results = run_test_phase(resource_scaling_tests)
    
    # Phase 4: Temporal Complexity Scaling (fixed at 4 activities)
    IO.puts("\n⏱️  PHASE 4: Temporal Complexity Scaling")
    temporal_scaling_tests = [
      {"4 Uniform Duration", &test_4_uniform_duration/0},
      {"4 Variable Duration", &test_4_variable_duration/0},
      {"4 Long Duration", &test_4_long_duration/0},
      {"4 Mixed Duration", &test_4_mixed_duration/0}
    ]
    
    phase4_results = run_test_phase(temporal_scaling_tests)
    
    # Combined Analysis
    all_results = phase1_results ++ phase2_results ++ phase3_results ++ phase4_results
    print_scaling_analysis(all_results)
  end

  defp run_test_phase(test_cases) do
    Enum.map(test_cases, fn {name, test_func} ->
      IO.puts("  Testing: #{name}")
      result = execute_test(test_func, name)
      
      case result.status do
        :success ->
          IO.puts("  ✅ SUCCESS: Generated schedule with #{result.schedule_length} activities")
        :failure ->
          IO.puts("  ❌ FAILURE: #{result.failure_reason}")
        :expected_error ->
          IO.puts("  ⚠️  EXPECTED ERROR: #{Map.get(result, :reason, "Unknown")}")
        :error ->
          IO.puts("  💥 UNEXPECTED ERROR: #{result.error}")
      end
      
      {name, result}
    end)
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
    alias AriaEngine.MCP.Tools.ScheduleActivities
    
    frame = %{}
    
    case ScheduleActivities.execute(request, frame) do
      {:reply, response, _frame} ->
        case response do
          %{content: [%{"text" => text}]} -> Jason.decode!(text)
          %{content: [%{text: text}]} -> Jason.decode!(text)
          %{text: text} -> Jason.decode!(text)
          text when is_binary(text) -> Jason.decode!(text)
          _ -> %{"status" => "error", "reason" => "Invalid response format"}
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
        
        # Check if we got a real schedule or just empty analysis
        if length(schedule) == 0 and not String.contains?(test_name, "0 Activities") do
          %{
            status: :failure,
            response: resp,
            schedule_length: 0,
            analysis: analysis,
            failure_reason: "Expected real schedule with activities, got empty schedule"
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

  # ==================== PHASE 1: ACTIVITY COUNT SCALING ====================

  # 1 Activity - Baseline
  defp test_1_activity do
    %{
      "schedule_name" => "Scale_1_Activity",
      "activities" => [
        %{"id" => "A", "duration" => 1}
      ]
    }
  end

  # 2 Activities - Parallel (no dependencies)
  defp test_2_activities do
    %{
      "schedule_name" => "Scale_2_Activities",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1}
      ]
    }
  end

  # 3 Activities - Linear chain
  defp test_3_activities do
    %{
      "schedule_name" => "Scale_3_Activities",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["B"]}
      ]
    }
  end

  # 4 Activities - Simple tree
  defp test_4_activities do
    %{
      "schedule_name" => "Scale_4_Activities",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["B", "C"]}
      ]
    }
  end

  # 5 Activities - Extended tree
  defp test_5_activities do
    %{
      "schedule_name" => "Scale_5_Activities",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["B"]},
        %{"id" => "E", "duration" => 1, "dependencies" => ["C"]}
      ]
    }
  end

  # 8 Activities - Binary tree structure
  defp test_8_activities do
    %{
      "schedule_name" => "Scale_8_Activities",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["B"]},
        %{"id" => "E", "duration" => 1, "dependencies" => ["B"]},
        %{"id" => "F", "duration" => 1, "dependencies" => ["C"]},
        %{"id" => "G", "duration" => 1, "dependencies" => ["C"]},
        %{"id" => "H", "duration" => 1, "dependencies" => ["D", "E", "F", "G"]}
      ]
    }
  end

  # 10 Activities - Complex DAG
  defp test_10_activities do
    %{
      "schedule_name" => "Scale_10_Activities",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "E", "duration" => 1, "dependencies" => ["B"]},
        %{"id" => "F", "duration" => 1, "dependencies" => ["C", "D"]},
        %{"id" => "G", "duration" => 1, "dependencies" => ["D", "E"]},
        %{"id" => "H", "duration" => 1, "dependencies" => ["F"]},
        %{"id" => "I", "duration" => 1, "dependencies" => ["G"]},
        %{"id" => "J", "duration" => 1, "dependencies" => ["H", "I"]}
      ]
    }
  end

  # 32 Activities - Multi-phase project structure
  defp test_32_activities do
    %{
      "schedule_name" => "Scale_32_Activities",
      "activities" => [
        # Phase 1: Initialization (4 parallel activities)
        %{"id" => "A1", "duration" => 1},
        %{"id" => "A2", "duration" => 1},
        %{"id" => "A3", "duration" => 1},
        %{"id" => "A4", "duration" => 1},
        
        # Phase 2: Setup (8 activities depending on Phase 1)
        %{"id" => "B1", "duration" => 1, "dependencies" => ["A1"]},
        %{"id" => "B2", "duration" => 1, "dependencies" => ["A1"]},
        %{"id" => "B3", "duration" => 1, "dependencies" => ["A2"]},
        %{"id" => "B4", "duration" => 1, "dependencies" => ["A2"]},
        %{"id" => "B5", "duration" => 1, "dependencies" => ["A3"]},
        %{"id" => "B6", "duration" => 1, "dependencies" => ["A3"]},
        %{"id" => "B7", "duration" => 1, "dependencies" => ["A4"]},
        %{"id" => "B8", "duration" => 1, "dependencies" => ["A4"]},
        
        # Phase 3: Core work (12 activities with mixed dependencies)
        %{"id" => "C1", "duration" => 1, "dependencies" => ["B1", "B2"]},
        %{"id" => "C2", "duration" => 1, "dependencies" => ["B1", "B3"]},
        %{"id" => "C3", "duration" => 1, "dependencies" => ["B2", "B4"]},
        %{"id" => "C4", "duration" => 1, "dependencies" => ["B3", "B4"]},
        %{"id" => "C5", "duration" => 1, "dependencies" => ["B5", "B6"]},
        %{"id" => "C6", "duration" => 1, "dependencies" => ["B5", "B7"]},
        %{"id" => "C7", "duration" => 1, "dependencies" => ["B6", "B8"]},
        %{"id" => "C8", "duration" => 1, "dependencies" => ["B7", "B8"]},
        %{"id" => "C9", "duration" => 1, "dependencies" => ["C1", "C2"]},
        %{"id" => "C10", "duration" => 1, "dependencies" => ["C3", "C4"]},
        %{"id" => "C11", "duration" => 1, "dependencies" => ["C5", "C6"]},
        %{"id" => "C12", "duration" => 1, "dependencies" => ["C7", "C8"]},
        
        # Phase 4: Integration (6 activities)
        %{"id" => "D1", "duration" => 1, "dependencies" => ["C9", "C10"]},
        %{"id" => "D2", "duration" => 1, "dependencies" => ["C10", "C11"]},
        %{"id" => "D3", "duration" => 1, "dependencies" => ["C11", "C12"]},
        %{"id" => "D4", "duration" => 1, "dependencies" => ["C9", "C12"]},
        %{"id" => "D5", "duration" => 1, "dependencies" => ["D1", "D2"]},
        %{"id" => "D6", "duration" => 1, "dependencies" => ["D3", "D4"]},
        
        # Phase 5: Completion (2 final activities)
        %{"id" => "E1", "duration" => 1, "dependencies" => ["D5", "D6"]},
        %{"id" => "E2", "duration" => 1, "dependencies" => ["E1"]}
      ]
    }
  end

  # 64 Activities - Enterprise-scale project structure
  defp test_64_activities do
    %{
      "schedule_name" => "Scale_64_Activities",
      "activities" => [
        # Phase 1: Infrastructure Setup (8 parallel activities)
        %{"id" => "A1", "duration" => 1}, %{"id" => "A2", "duration" => 1},
        %{"id" => "A3", "duration" => 1}, %{"id" => "A4", "duration" => 1},
        %{"id" => "A5", "duration" => 1}, %{"id" => "A6", "duration" => 1},
        %{"id" => "A7", "duration" => 1}, %{"id" => "A8", "duration" => 1},
        
        # Phase 2: Foundation Services (16 activities depending on Phase 1)
        %{"id" => "B1", "duration" => 1, "dependencies" => ["A1"]},
        %{"id" => "B2", "duration" => 1, "dependencies" => ["A1"]},
        %{"id" => "B3", "duration" => 1, "dependencies" => ["A2"]},
        %{"id" => "B4", "duration" => 1, "dependencies" => ["A2"]},
        %{"id" => "B5", "duration" => 1, "dependencies" => ["A3"]},
        %{"id" => "B6", "duration" => 1, "dependencies" => ["A3"]},
        %{"id" => "B7", "duration" => 1, "dependencies" => ["A4"]},
        %{"id" => "B8", "duration" => 1, "dependencies" => ["A4"]},
        %{"id" => "B9", "duration" => 1, "dependencies" => ["A5"]},
        %{"id" => "B10", "duration" => 1, "dependencies" => ["A5"]},
        %{"id" => "B11", "duration" => 1, "dependencies" => ["A6"]},
        %{"id" => "B12", "duration" => 1, "dependencies" => ["A6"]},
        %{"id" => "B13", "duration" => 1, "dependencies" => ["A7"]},
        %{"id" => "B14", "duration" => 1, "dependencies" => ["A7"]},
        %{"id" => "B15", "duration" => 1, "dependencies" => ["A8"]},
        %{"id" => "B16", "duration" => 1, "dependencies" => ["A8"]},
        
        # Phase 3: Core Development (24 activities with complex cross-dependencies)
        %{"id" => "C1", "duration" => 1, "dependencies" => ["B1", "B2"]},
        %{"id" => "C2", "duration" => 1, "dependencies" => ["B1", "B3"]},
        %{"id" => "C3", "duration" => 1, "dependencies" => ["B2", "B4"]},
        %{"id" => "C4", "duration" => 1, "dependencies" => ["B3", "B4"]},
        %{"id" => "C5", "duration" => 1, "dependencies" => ["B5", "B6"]},
        %{"id" => "C6", "duration" => 1, "dependencies" => ["B5", "B7"]},
        %{"id" => "C7", "duration" => 1, "dependencies" => ["B6", "B8"]},
        %{"id" => "C8", "duration" => 1, "dependencies" => ["B7", "B8"]},
        %{"id" => "C9", "duration" => 1, "dependencies" => ["B9", "B10"]},
        %{"id" => "C10", "duration" => 1, "dependencies" => ["B9", "B11"]},
        %{"id" => "C11", "duration" => 1, "dependencies" => ["B10", "B12"]},
        %{"id" => "C12", "duration" => 1, "dependencies" => ["B11", "B12"]},
        %{"id" => "C13", "duration" => 1, "dependencies" => ["B13", "B14"]},
        %{"id" => "C14", "duration" => 1, "dependencies" => ["B13", "B15"]},
        %{"id" => "C15", "duration" => 1, "dependencies" => ["B14", "B16"]},
        %{"id" => "C16", "duration" => 1, "dependencies" => ["B15", "B16"]},
        %{"id" => "C17", "duration" => 1, "dependencies" => ["C1", "C2"]},
        %{"id" => "C18", "duration" => 1, "dependencies" => ["C3", "C4"]},
        %{"id" => "C19", "duration" => 1, "dependencies" => ["C5", "C6"]},
        %{"id" => "C20", "duration" => 1, "dependencies" => ["C7", "C8"]},
        %{"id" => "C21", "duration" => 1, "dependencies" => ["C9", "C10"]},
        %{"id" => "C22", "duration" => 1, "dependencies" => ["C11", "C12"]},
        %{"id" => "C23", "duration" => 1, "dependencies" => ["C13", "C14"]},
        %{"id" => "C24", "duration" => 1, "dependencies" => ["C15", "C16"]},
        
        # Phase 4: System Integration (12 activities)
        %{"id" => "D1", "duration" => 1, "dependencies" => ["C17", "C18"]},
        %{"id" => "D2", "duration" => 1, "dependencies" => ["C18", "C19"]},
        %{"id" => "D3", "duration" => 1, "dependencies" => ["C19", "C20"]},
        %{"id" => "D4", "duration" => 1, "dependencies" => ["C20", "C21"]},
        %{"id" => "D5", "duration" => 1, "dependencies" => ["C21", "C22"]},
        %{"id" => "D6", "duration" => 1, "dependencies" => ["C22", "C23"]},
        %{"id" => "D7", "duration" => 1, "dependencies" => ["C23", "C24"]},
        %{"id" => "D8", "duration" => 1, "dependencies" => ["C17", "C24"]},
        %{"id" => "D9", "duration" => 1, "dependencies" => ["D1", "D2"]},
        %{"id" => "D10", "duration" => 1, "dependencies" => ["D3", "D4"]},
        %{"id" => "D11", "duration" => 1, "dependencies" => ["D5", "D6"]},
        %{"id" => "D12", "duration" => 1, "dependencies" => ["D7", "D8"]},
        
        # Phase 5: Final Delivery (4 activities)
        %{"id" => "E1", "duration" => 1, "dependencies" => ["D9", "D10"]},
        %{"id" => "E2", "duration" => 1, "dependencies" => ["D11", "D12"]},
        %{"id" => "E3", "duration" => 1, "dependencies" => ["E1", "E2"]},
        %{"id" => "E4", "duration" => 1, "dependencies" => ["E3"]}
      ]
    }
  end

  # ==================== PHASE 2: DEPENDENCY COMPLEXITY SCALING ====================

  # 4 Parallel - No dependencies
  defp test_4_parallel do
    %{
      "schedule_name" => "Dep_4_Parallel",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1},
        %{"id" => "C", "duration" => 1},
        %{"id" => "D", "duration" => 1}
      ]
    }
  end

  # 4 Linear Chain - A→B→C→D
  defp test_4_linear_chain do
    %{
      "schedule_name" => "Dep_4_Linear",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["B"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["C"]}
      ]
    }
  end

  # 4 Tree Structure - A→{B,C}, B→D
  defp test_4_tree_structure do
    %{
      "schedule_name" => "Dep_4_Tree",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["B"]}
      ]
    }
  end

  # 4 Diamond DAG - A→{B,C}→D
  defp test_4_diamond_dag do
    %{
      "schedule_name" => "Dep_4_Diamond",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["B", "C"]}
      ]
    }
  end

  # 4 Complex DAG - Multiple convergence points
  defp test_4_complex_dag do
    %{
      "schedule_name" => "Dep_4_Complex",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1, "dependencies" => ["A"]},
        %{"id" => "C", "duration" => 1, "dependencies" => ["A", "B"]},
        %{"id" => "D", "duration" => 1, "dependencies" => ["A", "B", "C"]}
      ]
    }
  end

  # ==================== PHASE 3: RESOURCE CONSTRAINT SCALING ====================

  # 4 No Resources - Baseline
  defp test_4_no_resources do
    %{
      "schedule_name" => "Res_4_None",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 1},
        %{"id" => "C", "duration" => 1},
        %{"id" => "D", "duration" => 1}
      ]
    }
  end

  # 4 Single Resource - All activities need same resource
  defp test_4_single_resource do
    %{
      "schedule_name" => "Res_4_Single",
      "activities" => [
        %{"id" => "A", "duration" => 1, "resources" => ["R1"]},
        %{"id" => "B", "duration" => 1, "resources" => ["R1"]},
        %{"id" => "C", "duration" => 1, "resources" => ["R1"]},
        %{"id" => "D", "duration" => 1, "resources" => ["R1"]}
      ],
      "resources" => %{
        "R1" => %{"capacity" => 1}
      }
    }
  end

  # 4 Multiple Resources - Different resources
  defp test_4_multiple_resources do
    %{
      "schedule_name" => "Res_4_Multiple",
      "activities" => [
        %{"id" => "A", "duration" => 1, "resources" => ["R1"]},
        %{"id" => "B", "duration" => 1, "resources" => ["R2"]},
        %{"id" => "C", "duration" => 1, "resources" => ["R3"]},
        %{"id" => "D", "duration" => 1, "resources" => ["R1", "R2"]}
      ],
      "resources" => %{
        "R1" => %{"capacity" => 1},
        "R2" => %{"capacity" => 1},
        "R3" => %{"capacity" => 1}
      }
    }
  end

  # 4 Resource Conflicts - Overlapping resource needs
  defp test_4_resource_conflicts do
    %{
      "schedule_name" => "Res_4_Conflicts",
      "activities" => [
        %{"id" => "A", "duration" => 2, "resources" => ["R1", "R2"]},
        %{"id" => "B", "duration" => 2, "resources" => ["R1", "R3"]},
        %{"id" => "C", "duration" => 2, "resources" => ["R2", "R3"]},
        %{"id" => "D", "duration" => 1, "resources" => ["R1", "R2", "R3"]}
      ],
      "resources" => %{
        "R1" => %{"capacity" => 1},
        "R2" => %{"capacity" => 1},
        "R3" => %{"capacity" => 1}
      }
    }
  end

  # 4 Capacity Limits - Limited resource capacity
  defp test_4_capacity_limits do
    %{
      "schedule_name" => "Res_4_Capacity",
      "activities" => [
        %{"id" => "A", "duration" => 1, "resources" => ["Workers"]},
        %{"id" => "B", "duration" => 1, "resources" => ["Workers"]},
        %{"id" => "C", "duration" => 1, "resources" => ["Workers"]},
        %{"id" => "D", "duration" => 1, "resources" => ["Workers"]}
      ],
      "resources" => %{
        "Workers" => %{"capacity" => 2}  # Only 2 workers available
      }
    }
  end

  # ==================== PHASE 4: TEMPORAL COMPLEXITY SCALING ====================

  # 4 Uniform Duration - All activities same duration
  defp test_4_uniform_duration do
    %{
      "schedule_name" => "Time_4_Uniform",
      "activities" => [
        %{"id" => "A", "duration" => 2},
        %{"id" => "B", "duration" => 2},
        %{"id" => "C", "duration" => 2},
        %{"id" => "D", "duration" => 2}
      ]
    }
  end

  # 4 Variable Duration - Different durations
  defp test_4_variable_duration do
    %{
      "schedule_name" => "Time_4_Variable",
      "activities" => [
        %{"id" => "A", "duration" => 1},
        %{"id" => "B", "duration" => 2},
        %{"id" => "C", "duration" => 3},
        %{"id" => "D", "duration" => 4}
      ]
    }
  end

  # 4 Long Duration - Some very long activities
  defp test_4_long_duration do
    %{
      "schedule_name" => "Time_4_Long",
      "activities" => [
        %{"id" => "A", "duration" => 10},
        %{"id" => "B", "duration" => 1},
        %{"id" => "C", "duration" => 15},
        %{"id" => "D", "duration" => 2}
      ]
    }
  end

  # 4 Mixed Duration - Combination of short/medium/long
  defp test_4_mixed_duration do
    %{
      "schedule_name" => "Time_4_Mixed",
      "activities" => [
        %{"id" => "A", "duration" => 0.5},
        %{"id" => "B", "duration" => 5},
        %{"id" => "C", "duration" => 1},
        %{"id" => "D", "duration" => 20}
      ]
    }
  end

  # ==================== ANALYSIS AND REPORTING ====================

  defp print_scaling_analysis(all_results) do
    IO.puts("\n=== SCALING ANALYSIS ===")
    
    # Group results by phase
    phases = [
      {"Activity Count Scaling", Enum.filter(all_results, fn {name, _} -> String.starts_with?(name, "Scale_") end)},
      {"Dependency Complexity", Enum.filter(all_results, fn {name, _} -> String.starts_with?(name, "Dep_") end)},
      {"Resource Constraints", Enum.filter(all_results, fn {name, _} -> String.starts_with?(name, "Res_") end)},
      {"Temporal Complexity", Enum.filter(all_results, fn {name, _} -> String.starts_with?(name, "Time_") end)}
    ]
    
    Enum.each(phases, fn {phase_name, phase_results} ->
      IO.puts("\n📊 #{phase_name}:")
      
      success_count = Enum.count(phase_results, fn {_name, result} -> result.status == :success end)
      total_count = length(phase_results)
      
      success_rate = if total_count > 0 do
        Float.round(success_count/total_count*100, 1)
      else
        0.0
      end
      
      IO.puts("  Success Rate: #{success_count}/#{total_count} (#{success_rate}%)")
      
      # Find breaking point
      breaking_point = find_breaking_point(phase_results)
      if breaking_point do
        IO.puts("  ⚠️  Breaking Point: #{breaking_point}")
      else
        IO.puts("  ✅ No breaking point found in this range")
      end
      
      # Show detailed results
      Enum.each(phase_results, fn {name, result} ->
        status_icon = case result.status do
          :success -> "✅"
          :failure -> "❌"
          :expected_error -> "⚠️ "
          :error -> "💥"
        end
        
        schedule_info = case result.status do
          :success -> " (#{result.schedule_length} activities scheduled)"
          _ -> ""
        end
        
        IO.puts("    #{status_icon} #{name}#{schedule_info}")
      end)
    end)
    
    # Overall summary
    total_tests = length(all_results)
    total_successes = Enum.count(all_results, fn {_name, result} -> result.status == :success end)
    
    IO.puts("\n🎯 OVERALL SCALING RESULTS:")
    IO.puts("Total Tests: #{total_tests}")
    IO.puts("Total Successes: #{total_successes}")
    IO.puts("Overall Success Rate: #{Float.round(total_successes/total_tests*100, 1)}%")
    
    if total_successes < total_tests do
      IO.puts("\n🚨 SCALING ISSUES DETECTED:")
      IO.puts("The system is not handling all complexity levels successfully.")
      IO.puts("Focus optimization efforts on the failing test categories.")
    else
      IO.puts("\n🎉 EXCELLENT SCALING PERFORMANCE:")
      IO.puts("The system handles all tested complexity levels successfully!")
    end
  end

  defp find_breaking_point(phase_results) do
    # Find the first failure in the sequence
    Enum.find_value(phase_results, fn {name, result} ->
      if result.status != :success do
        name
      else
        nil
      end
    end)
  end
end

# Execute the incremental scaling test suite
IncrementalScalingTest.run_all_tests()
