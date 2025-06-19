# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.SchedulerTool do
  @moduledoc """
  MCP tool implementation for AriaEngine scheduling capabilities.
  
  Provides the `schedule_activities` tool that bridges between MCP protocol
  and the standalone AriaEngine.Scheduler module, handling JSON schema
  conversion and maintaining full scheduler functionality.
  
  ## Tool Interface
  
  **Tool Name:** `schedule_activities`
  
  **Description:** Schedule activities using AriaEngine's hybrid temporal planner
  with entity/resource management and comprehensive analysis.
  
  **Input Schema:**
  ```json
  {
    "schedule_name": {"type": "string", "required": true},
    "activities": {"type": "array", "required": true},
    "resources": {"type": "object", "required": false},
    "constraints": {"type": "object", "required": false}
  }
  ```
  
  **Output Schema:**
  ```json
  {
    "status": "success" | "error",
    "reason": "string",
    "schedule": "array",
    "analysis": "object"
  }
  ```
  
  ## Features
  
  - Empty activity list handling (returns successful empty plans)
  - Full entity and resource management support
  - Comprehensive scheduling analysis and reporting
  - Resource conflict detection and resolution
  - Critical path analysis with resource constraints
  - Simulation mode for predictive scheduling
  """
  
  require Logger
  
  @doc """
  Get the MCP tool definition for schedule_activities.
  
  Returns the tool schema that MCP clients use for tool discovery.
  """
  def get_tool_definition do
    %{
      name: "schedule_activities",
      description: "Schedule activities using AriaEngine's hybrid temporal planner with entity/resource management and comprehensive analysis",
      inputSchema: %{
        type: "object",
        properties: %{
          schedule_name: %{
            type: "string",
            description: "Name for this scheduling request"
          },
          activities: %{
            type: "array",
            description: "List of activities to schedule (can be empty for valid empty plan)",
            items: %{
              type: "object",
              properties: %{
                id: %{type: "string", description: "Unique activity identifier"},
                duration: %{type: "number", description: "Activity duration in time units"},
                dependencies: %{
                  type: "array",
                  items: %{type: "string"},
                  description: "List of activity IDs this activity depends on"
                },
                required_capabilities: %{
                  type: "array",
                  items: %{type: "string"},
                  description: "Required entity capabilities for this activity"
                },
                required_resources: %{
                  type: "array",
                  items: %{type: "string"},
                  description: "Required resource IDs for this activity"
                }
              },
              required: ["id", "duration", "dependencies"]
            }
          },
          resources: %{
            type: "object",
            description: "Resource definitions with capacity and constraints",
            additionalProperties: %{
              type: "object",
              properties: %{
                type: %{type: "string", description: "Resource type (computational, physical, human, virtual)"},
                capacity: %{type: "number", description: "Maximum resource capacity"},
                current_usage: %{type: "number", description: "Current resource usage"},
                constraints: %{type: "object", description: "Resource-specific constraints"},
                availability_schedule: %{
                  type: "array",
                  items: %{type: "object"},
                  description: "Time intervals when resource is available"
                }
              }
            }
          },
          constraints: %{
            type: "object",
            description: "Scheduling constraints and limits",
            properties: %{
              max_duration: %{type: "number", description: "Maximum total schedule duration"},
              resource_limits: %{type: "object", description: "Global resource usage limits"},
              temporal_constraints: %{type: "array", description: "Additional temporal constraints"}
            }
          }
        },
        required: ["schedule_name", "activities"]
      }
    }
  end
  
  @doc """
  Handle the schedule_activities tool call.
  
  Converts MCP JSON input to Elixir structures, calls the scheduler,
  and converts the result back to MCP JSON format.
  """
  def handle_tool_call(params) do
    try do
      # Extract and validate required parameters
      schedule_name = Map.get(params, "schedule_name")
      activities = Map.get(params, "activities", [])
      resources = Map.get(params, "resources", %{})
      constraints = Map.get(params, "constraints", %{})
      
      # Validate required parameters
      if is_nil(schedule_name) or not is_binary(schedule_name) do
        return_error("schedule_name is required and must be a string")
      else
        # Convert input to scheduler format
        converted_activities = convert_activities_from_mcp(activities)
        scheduler_opts = build_scheduler_options(resources, constraints)
        
        Logger.info("MCP SchedulerTool: Processing '#{schedule_name}' with #{length(activities)} activities")
        
        # Call the scheduler
        case AriaEngine.Scheduler.schedule_activities(schedule_name, converted_activities, scheduler_opts) do
          {:ok, result} ->
            # Convert scheduler result to MCP format
            convert_scheduler_result_to_mcp(result)
            
          {:error, reason} ->
            return_error("Scheduler error: #{reason}")
        end
      end
    rescue
      e ->
        error_msg = "Tool call error: #{Exception.message(e)}"
        Logger.error(error_msg)
        return_error(error_msg)
    end
  end
  
  # Private helper functions
  
  defp build_scheduler_options(resources, constraints) do
    opts = []
    
    # Convert resources if provided
    opts = if map_size(resources) > 0 do
      converted_resources = convert_resources_from_mcp(resources)
      Keyword.put(opts, :resources, converted_resources)
    else
      opts
    end
    
    # Add constraints if provided
    opts = if map_size(constraints) > 0 do
      Keyword.put(opts, :constraints, constraints)
    else
      opts
    end
    
    # Enable activity logging for MCP calls
    opts = Keyword.put(opts, :log_activities, true)
    
    # Set reasonable verbosity for MCP usage
    Keyword.put(opts, :verbose, 1)
  end
  
  defp convert_activities_from_mcp(activities) when is_list(activities) do
    Enum.map(activities, fn activity ->
      # Convert string keys to atom keys for scheduler compatibility
      %{
        id: Map.get(activity, "id"),
        duration: Map.get(activity, "duration"),
        dependencies: Map.get(activity, "dependencies", []),
        required_capabilities: convert_to_atoms(Map.get(activity, "required_capabilities", [])),
        required_resources: Map.get(activity, "required_resources", [])
      }
    end)
  end
  
  defp convert_activities_from_mcp(_), do: []
  
  defp convert_to_atoms(list) when is_list(list) do
    Enum.map(list, fn item ->
      case item do
        str when is_binary(str) -> String.to_atom(str)
        atom when is_atom(atom) -> atom
        _ -> item
      end
    end)
  end
  
  defp convert_to_atoms(_), do: []
  
  defp convert_resources_from_mcp(resources_map) do
    Enum.map(resources_map, fn {resource_id, resource_config} ->
      %AriaEngine.Scheduler.Resource{
        id: to_string(resource_id),
        type: parse_resource_type(Map.get(resource_config, "type", "computational")),
        capacity: Map.get(resource_config, "capacity", 1),
        current_usage: Map.get(resource_config, "current_usage", 0),
        constraints: Map.get(resource_config, "constraints", %{}),
        availability_schedule: parse_availability_schedule(Map.get(resource_config, "availability_schedule", [])),
        metadata: Map.get(resource_config, "metadata", %{})
      }
    end)
  end
  
  defp parse_resource_type(type_string) do
    case String.downcase(to_string(type_string)) do
      "computational" -> :computational
      "physical" -> :physical
      "human" -> :human
      "virtual" -> :virtual
      _ -> :computational  # Default fallback
    end
  end
  
  defp parse_availability_schedule(schedule_list) when is_list(schedule_list) do
    # For now, return as-is. Could be enhanced to parse into Timeline.Interval structs
    schedule_list
  end
  
  defp parse_availability_schedule(_), do: []
  
  defp convert_scheduler_result_to_mcp(%AriaEngine.Scheduler.SimulationResult{} = result) do
    %{
      status: result.status,
      reason: result.reason,
      schedule: convert_schedule_to_mcp(result.schedule),
      analysis: convert_analysis_to_mcp(result.analysis)
    }
  end
  
  defp convert_schedule_to_mcp(schedule) when is_list(schedule) do
    # Convert schedule items to MCP-friendly format
    Enum.map(schedule, fn item ->
      case item do
        %{} = map -> map  # Already a map, keep as-is
        _ -> %{item: item}  # Wrap non-maps
      end
    end)
  end
  
  defp convert_schedule_to_mcp(_), do: []
  
  defp convert_analysis_to_mcp(analysis) when is_map(analysis) do
    # Ensure all analysis data is JSON-serializable
    analysis
    |> Enum.map(fn {key, value} ->
      {to_string(key), convert_value_to_json_safe(value)}
    end)
    |> Map.new()
  end
  
  defp convert_analysis_to_mcp(_), do: %{}
  
  defp convert_value_to_json_safe(value) when is_atom(value), do: to_string(value)
  defp convert_value_to_json_safe(value) when is_list(value) do
    Enum.map(value, &convert_value_to_json_safe/1)
  end
  defp convert_value_to_json_safe(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {to_string(k), convert_value_to_json_safe(v)} end)
    |> Map.new()
  end
  defp convert_value_to_json_safe(value), do: value
  
  defp return_error(reason) do
    %{
      status: "error",
      reason: reason,
      schedule: [],
      analysis: %{}
    }
  end
end
