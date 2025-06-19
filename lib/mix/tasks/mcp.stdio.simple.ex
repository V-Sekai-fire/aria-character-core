# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Stdio.Simple do
  @moduledoc """
  Simple MCP server implementation for stdio transport.
  
  This is a minimal, working MCP server that properly handles the protocol
  without external framework dependencies.
  """

  use Mix.Task
  require Logger

  @shortdoc "Start simple MCP server in stdio mode"

  @impl Mix.Task
  def run(_args) do
    # Ensure all required applications are started
    {:ok, _} = Application.ensure_all_started(:logger)
    {:ok, _} = Application.ensure_all_started(:jason)
    {:ok, _} = Application.ensure_all_started(:aria_character_core)

    # Configure logger to write to stderr to avoid interfering with MCP protocol
    Logger.configure(level: :info)
    
    # Write startup message to stderr
    IO.puts(:stderr, "Starting simple Aria Engine MCP server in stdio mode...")
    IO.puts(:stderr, "Server ready for MCP client connections")
    IO.puts(:stderr, "PID: #{inspect(self())}")

    # Start the simple MCP server loop
    server_loop()
  end

  defp server_loop do
    case IO.gets("") do
      :eof ->
        IO.puts(:stderr, "MCP server: EOF received, shutting down")
        :ok

      {:error, reason} ->
        IO.puts(:stderr, "MCP server: IO error: #{inspect(reason)}")
        :error

      line when is_binary(line) ->
        IO.puts(:stderr, "MCP server: Received line: #{String.trim(line)}")
        line
        |> String.trim()
        |> handle_request()
        |> case do
          :continue -> server_loop()
        end
    end
  end

  defp handle_request("") do
    # Empty line, continue
    :continue
  end

  defp handle_request(line) do
    try do
      request = Jason.decode!(line)
      response = process_request(request)
      
      if response do
        IO.puts(Jason.encode!(response))
      end
      
      :continue
    rescue
      e ->
        Logger.error("MCP server: Error processing request: #{Exception.message(e)}")
        error_response = %{
          jsonrpc: "2.0",
          id: nil,
          error: %{
            code: -32700,
            message: "Parse error"
          }
        }
        IO.puts(Jason.encode!(error_response))
        :continue
    end
  end

  defp process_request(%{"method" => "initialize", "id" => id, "params" => _params}) do
    IO.puts(:stderr, "MCP server: Received initialize request")
    
    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: %{
          tools: %{}
        },
        serverInfo: %{
          name: "aria-scheduler",
          version: "1.0.0"
        }
      }
    }
  end

  defp process_request(%{"method" => "initialized", "params" => _params}) do
    Logger.info("MCP server: Received initialized notification")
    # No response for notifications
    nil
  end

  defp process_request(%{"method" => "tools/list", "id" => id}) do
    Logger.info("MCP server: Received tools/list request")
    
    tools = [get_schedule_activities_tool_definition()]

    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        tools: tools
      }
    }
  end

  defp process_request(%{"method" => "tools/call", "id" => id, "params" => %{"name" => "schedule_activities", "arguments" => args}}) do
    Logger.info("MCP server: Received schedule_activities tool call")
    
    try do
      result = handle_schedule_activities_tool_call(args)
      
      %{
        jsonrpc: "2.0",
        id: id,
        result: %{
          content: [
            %{
              type: "text",
              text: Jason.encode!(result)
            }
          ]
        }
      }
    rescue
      e ->
        Logger.error("MCP server: Tool call failed: #{Exception.message(e)}")
        
        %{
          jsonrpc: "2.0",
          id: id,
          error: %{
            code: -32603,
            message: "Internal error",
            data: %{error: Exception.message(e)}
          }
        }
    end
  end

  defp process_request(%{"method" => method, "id" => id}) do
    Logger.warning("MCP server: Unknown method: #{method}")
    
    %{
      jsonrpc: "2.0",
      id: id,
      error: %{
        code: -32601,
        message: "Method not found"
      }
    }
  end

  defp process_request(%{"method" => method}) do
    Logger.info("MCP server: Received notification: #{method}")
    # No response for notifications
    nil
  end

  defp process_request(request) do
    Logger.warning("MCP server: Invalid request format: #{inspect(request)}")
    
    %{
      jsonrpc: "2.0",
      id: nil,
      error: %{
        code: -32600,
        message: "Invalid Request"
      }
    }
  end

  # Scheduler tool functions (migrated from AriaEngine.MCP.SchedulerTool)
  
  # Get the MCP tool definition for the schedule_activities tool.
  defp get_schedule_activities_tool_definition do
    %{
      name: "schedule_activities",
      description: "Schedule activities using AriaEngine's temporal planner with entity and resource management. Returns complete SimulationResult with solution tree.",
      inputSchema: %{
        type: "object",
        properties: %{
          schedule_name: %{
            type: "string",
            description: "Name for this scheduling request"
          },
          activities: %{
            type: "array",
            description: "List of activities to schedule",
            items: %{
              type: "object",
              properties: %{
                id: %{type: "string", description: "Activity identifier"},
                duration: %{type: "integer", description: "Duration in minutes"},
                dependencies: %{
                  type: "array",
                  items: %{type: "string"},
                  description: "List of activity IDs this depends on"
                },
                required_capabilities: %{
                  type: "array",
                  items: %{type: "string"},
                  description: "Required entity capabilities"
                },
                required_resources: %{
                  type: "array",
                  items: %{type: "string"},
                  description: "Required resource IDs"
                }
              },
              required: ["id", "duration"]
            }
          },
          entities: %{
            type: "array",
            description: "Available entities with capabilities",
            items: %{
              type: "object",
              properties: %{
                id: %{type: "string"},
                type: %{type: "string"},
                capabilities: %{type: "array", items: %{type: "string"}},
                availability: %{type: "object"}
              }
            }
          },
          resources: %{
            type: "object",
            description: "Available resources with capacity",
            additionalProperties: %{
              type: "object",
              properties: %{
                type: %{type: "string"},
                capacity: %{type: "integer"},
                current_usage: %{type: "integer"}
              }
            }
          },
          constraints: %{
            type: "object",
            description: "Scheduling constraints and options",
            properties: %{
              max_duration: %{type: "integer"},
              simulation_mode: %{type: "boolean"},
              verbose: %{type: "integer"}
            }
          }
        },
        required: ["schedule_name", "activities"]
      }
    }
  end
  
  # Handle MCP tool call for schedule_activities.
  # Takes MCP JSON parameters and returns the complete SimulationResult from
  # AriaEngine.Scheduler.schedule_activities/3.
  defp handle_schedule_activities_tool_call(params) do
    try do
      # Validate required parameters
      case validate_params(params) do
        {:ok, validated_params} ->
          # Extract parameters
          schedule_name = validated_params["schedule_name"]
          activities = convert_activities(validated_params["activities"] || [])
          entities = convert_entities(validated_params["entities"] || [])
          resources = validated_params["resources"] || %{}
          constraints = validated_params["constraints"] || %{}
          
          # Prepare scheduler options
          opts = [
            entities: entities,
            resources: resources,
            constraints: constraints,
            simulation_mode: Map.get(constraints, "simulation_mode", true),
            verbose: Map.get(constraints, "verbose", 0),
            log_activities: true
          ]
          
          # Call the scheduler
          case AriaEngine.Scheduler.schedule_activities(schedule_name, activities, opts) do
            {:ok, simulation_result} ->
              # Return the complete SimulationResult
              convert_simulation_result_to_map(simulation_result)
              
            {:error, reason} ->
              %{
                status: "error",
                reason: reason,
                schedule: [],
                analysis: %{},
                activity_log: [],
                resource_utilization: %{},
                timeline: [],
                simulation_metadata: %{}
              }
          end
          
        {:error, reason} ->
          %{
            status: "error",
            reason: reason,
            schedule: [],
            analysis: %{},
            activity_log: [],
            resource_utilization: %{},
            timeline: [],
            simulation_metadata: %{}
          }
      end
    rescue
      e ->
        Logger.error("SchedulerTool error: #{Exception.message(e)}")
        %{
          status: "error",
          reason: "Internal error: #{Exception.message(e)}",
          schedule: [],
          analysis: %{},
          activity_log: [],
          resource_utilization: %{},
          timeline: [],
          simulation_metadata: %{}
        }
    end
  end
  
  # Private helper functions
  
  defp validate_params(params) when is_map(params) do
    cond do
      not Map.has_key?(params, "schedule_name") ->
        {:error, "schedule_name is required"}
        
      not is_binary(params["schedule_name"]) ->
        {:error, "schedule_name is required and must be a string"}
        
      not Map.has_key?(params, "activities") ->
        {:error, "activities is required"}
        
      not is_list(params["activities"]) ->
        {:error, "activities must be a list"}
        
      true ->
        {:ok, params}
    end
  end
  
  defp validate_params(_), do: {:error, "Invalid parameters format"}
  
  defp convert_activities(activities) when is_list(activities) do
    Enum.map(activities, fn activity ->
      %{
        id: Map.get(activity, "id"),
        duration: Map.get(activity, "duration"),
        dependencies: Map.get(activity, "dependencies", []),
        required_capabilities: convert_capabilities(Map.get(activity, "required_capabilities", [])),
        required_resources: Map.get(activity, "required_resources", [])
      }
    end)
  end
  
  defp convert_activities(_), do: []
  
  defp convert_entities(entities) when is_list(entities) do
    Enum.map(entities, fn entity ->
      %AriaEngine.Scheduler.Entity{
        id: Map.get(entity, "id", "unknown"),
        type: String.to_atom(Map.get(entity, "type", "agent")),
        capabilities: convert_capabilities(Map.get(entity, "capabilities", [])),
        current_activity: Map.get(entity, "current_activity"),
        availability: convert_availability(Map.get(entity, "availability")),
        resources_held: Map.get(entity, "resources_held", []),
        metadata: Map.get(entity, "metadata", %{})
      }
    end)
  end
  
  defp convert_entities(_), do: []
  
  defp convert_capabilities(capabilities) when is_list(capabilities) do
    Enum.map(capabilities, fn cap ->
      if is_binary(cap), do: String.to_atom(cap), else: cap
    end)
  end
  
  defp convert_capabilities(_), do: []
  
  defp convert_availability(nil), do: nil
  defp convert_availability(availability) when is_map(availability) do
    # Convert to Timeline.Interval if needed
    # For now, just pass through - the scheduler can handle maps
    availability
  end
  defp convert_availability(_), do: nil
  
  defp convert_simulation_result_to_map(%AriaEngine.Scheduler.SimulationResult{} = result) do
    %{
      status: result.status,
      reason: result.reason,
      schedule: result.schedule || [],
      analysis: result.analysis || %{},
      activity_log: convert_activity_log(result.activity_log || []),
      resource_utilization: result.resource_utilization || %{},
      timeline: result.timeline || [],
      simulation_metadata: result.simulation_metadata || %{}
    }
  end
  
  defp convert_activity_log(activity_log) when is_list(activity_log) do
    Enum.map(activity_log, fn entry ->
      case entry do
        %AriaEngine.Scheduler.ActivityLogEntry{} = log_entry ->
          %{
            timestamp: DateTime.to_iso8601(log_entry.timestamp),
            activity_id: log_entry.activity_id,
            entity_id: log_entry.entity_id,
            event_type: log_entry.event_type,
            resource_snapshot: log_entry.resource_snapshot || %{},
            state_changes: log_entry.state_changes || [],
            metadata: log_entry.metadata || %{}
          }
        _ ->
          entry
      end
    end)
  end
  
  defp convert_activity_log(_), do: []
end
