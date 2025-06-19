# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.Testing.EntityTests do
  @moduledoc """
  Entity and capability matching tests for the MCP scheduler.
  
  Tests entity assignment, capability requirements, and mixed entity types.
  """
  
  alias AriaEngine.MCP.Tools.ScheduleActivities
  
  def test_entity_capability_matching(include_raw) do
    test_name = "entity_capability_matching"
    
    params = %{
      "schedule_name" => "Entity Capability Test",
      "activities" => [
        %{
          "id" => "welding_task",
          "duration" => 3.0,
          "required_capabilities" => ["welding", "safety_certified"],
          "type" => "manufacturing"
        }
      ],
      "entities" => %{
        "welder_1" => %{
          "type" => "human",
          "capabilities" => ["welding", "safety_certified"],
          "properties" => %{"certification" => "AWS_D1.1"}
        }
      }
    }
    
    result = execute_scheduler_test(params)
    
    # Analyze result
    analysis = case result do
      %{"status" => "success", "schedule" => [activity]} ->
        %{
          "status" => "✅ WORKING",
          "message" => "Successfully handles entity-capability matching",
          "expected_behavior" => "Activity scheduled with capability requirements",
          "actual_behavior" => "Activity scheduled: #{Map.get(activity, "id")}"
        }
      
      %{"status" => "success", "schedule" => schedule} when is_list(schedule) ->
        %{
          "status" => "⚠️ UNEXPECTED",
          "message" => "Generated #{length(schedule)} activities instead of 1",
          "expected_behavior" => "Single activity with capability matching",
          "actual_behavior" => "#{length(schedule)} activities generated"
        }
      
      %{"status" => "error"} = error ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to handle capability requirements",
          "expected_behavior" => "Activity scheduled with capability matching",
          "actual_behavior" => "Error: #{Map.get(error, "reason", "unknown")}"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "Activity scheduled with capability matching",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Entity-Capability Matching", analysis, result, include_raw)
  end
  
  def test_mixed_entity_types(include_raw) do
    test_name = "mixed_entity_types"
    
    params = %{
      "schedule_name" => "Mixed Entity Types Test",
      "activities" => [
        %{
          "id" => "equipment_setup",
          "duration" => 0.5,
          "assigned_entity" => "crane_1"
        },
        %{
          "id" => "skilled_work",
          "duration" => 2.0,
          "required_capabilities" => ["welding", "safety"]
        }
      ],
      "entities" => %{
        "crane_1" => %{
          "type" => "equipment",
          "capabilities" => [],
          "properties" => %{"max_load" => "50_tons"}
        },
        "welder_1" => %{
          "type" => "human",
          "capabilities" => ["welding", "safety"],
          "properties" => %{"certification" => "AWS"}
        }
      }
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => "success", "schedule" => schedule} when length(schedule) == 2 ->
        %{
          "status" => "✅ WORKING",
          "message" => "Successfully handles mixed entity types",
          "expected_behavior" => "Equipment and human entities both scheduled",
          "actual_behavior" => "Both activities scheduled successfully"
        }
      
      %{"status" => "success", "schedule" => schedule} ->
        %{
          "status" => "⚠️ PARTIAL",
          "message" => "Partial success with mixed entities",
          "expected_behavior" => "2 activities with different entity types",
          "actual_behavior" => "#{length(schedule)} activities scheduled"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to handle mixed entity types",
          "expected_behavior" => "Equipment and human entities",
          "actual_behavior" => "Error or invalid response"
        }
    end
    
    build_test_result(test_name, "Entity-Capability Matching", analysis, result, include_raw)
  end
  
  def test_capability_mismatch(include_raw) do
    test_name = "capability_mismatch"
    
    params = %{
      "schedule_name" => "Capability Mismatch Test",
      "activities" => [
        %{
          "id" => "specialized_task",
          "duration" => 1.0,
          "required_capabilities" => ["nuclear_safety", "radiation_handling"]
        }
      ],
      "entities" => %{
        "general_worker" => %{
          "type" => "human",
          "capabilities" => ["basic_safety", "manual_labor"],
          "properties" => %{"experience" => "2_years"}
        }
      }
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => "error"} ->
        %{
          "status" => "✅ WORKING",
          "message" => "Correctly rejects tasks when capabilities don't match",
          "expected_behavior" => "Error when no suitable entity available",
          "actual_behavior" => "Capability mismatch detected and rejected"
        }
      
      %{"status" => "success", "schedule" => schedule} when length(schedule) == 1 ->
        # Check if the system created an auto-generated agent
        activity = List.first(schedule)
        if Map.has_key?(activity, "auto_generated_agent") do
          %{
            "status" => "⚠️ PARTIAL",
            "message" => "Creates auto-generated agent for missing capabilities",
            "expected_behavior" => "Error or explicit capability matching",
            "actual_behavior" => "Auto-generated agent created to fulfill requirements"
          }
        else
          %{
            "status" => "❌ BROKEN",
            "message" => "Schedules task despite capability mismatch",
            "expected_behavior" => "Error when capabilities don't match",
            "actual_behavior" => "Task scheduled without proper capability validation"
          }
        end
      
      %{"status" => "success"} ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Ignores capability requirements",
          "expected_behavior" => "Validate capability requirements",
          "actual_behavior" => "Scheduled without capability validation"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Unexpected response format",
          "expected_behavior" => "Capability validation",
          "actual_behavior" => "Invalid response structure"
        }
    end
    
    build_test_result(test_name, "Entity-Capability Matching", analysis, result, include_raw)
  end
  
  def test_entity_assignment_override(include_raw) do
    test_name = "entity_assignment_override"
    
    params = %{
      "schedule_name" => "Entity Assignment Override Test",
      "activities" => [
        %{
          "id" => "specific_assignment",
          "duration" => 1.0,
          "assigned_entity" => "specialist_1",
          "required_capabilities" => ["advanced_skill"]
        }
      ],
      "entities" => %{
        "specialist_1" => %{
          "type" => "human",
          "capabilities" => ["basic_skill"],  # Missing required capability
          "properties" => %{"department" => "engineering"}
        },
        "expert_1" => %{
          "type" => "human",
          "capabilities" => ["advanced_skill"],  # Has required capability
          "properties" => %{"department" => "research"}
        }
      }
    }
    
    result = execute_scheduler_test(params)
    
    analysis = case result do
      %{"status" => "success", "schedule" => [activity]} ->
        # Check if the system respects explicit assignment or switches to capable entity
        assigned_entity = Map.get(activity, "assigned_entity")
        
        cond do
          assigned_entity == "specialist_1" ->
            %{
              "status" => "⚠️ PARTIAL",
              "message" => "Respects explicit assignment but ignores capability mismatch",
              "expected_behavior" => "Either reject or reassign to capable entity",
              "actual_behavior" => "Assigned to specialist_1 despite missing capability"
            }
          
          assigned_entity == "expert_1" ->
            %{
              "status" => "✅ WORKING",
              "message" => "Intelligently reassigns to capable entity",
              "expected_behavior" => "Reassign to entity with required capabilities",
              "actual_behavior" => "Reassigned to expert_1 with advanced_skill"
            }
          
          true ->
            %{
              "status" => "⚠️ PARTIAL",
              "message" => "Creates alternative assignment solution",
              "expected_behavior" => "Handle assignment vs capability conflict",
              "actual_behavior" => "Alternative assignment: #{assigned_entity || "auto-generated"}"
            }
        end
      
      %{"status" => "error"} ->
        %{
          "status" => "⚠️ PARTIAL",
          "message" => "Rejects conflicting assignment/capability requirements",
          "expected_behavior" => "Handle assignment vs capability conflict",
          "actual_behavior" => "Rejected due to conflicting requirements"
        }
      
      _ ->
        %{
          "status" => "❌ BROKEN",
          "message" => "Failed to handle assignment override scenario",
          "expected_behavior" => "Handle assignment vs capability conflict",
          "actual_behavior" => "Invalid or unexpected response"
        }
    end
    
    build_test_result(test_name, "Entity-Capability Matching", analysis, result, include_raw)
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
