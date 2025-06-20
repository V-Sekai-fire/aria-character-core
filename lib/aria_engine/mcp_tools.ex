# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPTools do
  # API Version Management
  @current_api_version "1.0.0"
  @supported_api_versions ["1.0.0"]

  @moduledoc """
  Shared MCP tool definitions and handlers for AriaEngine.
  
  This module provides a registry-based system for MCP tools that can be
  used by different MCP server implementations (stdio, HTTP, etc.).
  
  ## Versioning
  
  The MCP API uses semantic versioning (major.minor.patch):
  - Major: Breaking changes to existing tools
  - Minor: New tools or backward-compatible enhancements  
  - Patch: Bug fixes and internal improvements
  
  Current API version: #{@current_api_version}
  Supported versions: #{inspect(@supported_api_versions)}
  
  ## Adding Tools
  
  To add a new tool:
  1. Add the tool definition to the @tools list with version
  2. Add a handler function following the pattern handle_<tool_name>_tool_call/2
  3. The tool will automatically be available in all MCP servers
  4. Update API version appropriately (minor for new tools, major for breaking changes)
  """

  require Logger
  
  # Tool registry with versioning - add new tools here
  @tools [
    {:schedule_activities, "1.0.0"}
  ]
  
  @doc """
  Returns the current API version.
  """
  def current_api_version, do: @current_api_version
  
  @doc """
  Returns all supported API versions.
  """
  def supported_api_versions, do: @supported_api_versions
  
  @doc """
  Checks if a given API version is supported.
  """
  def version_supported?(version) when is_binary(version) do
    version in @supported_api_versions
  end
  
  @doc """
  Validates API version compatibility for a request.
  Returns {:ok, version} or {:error, reason}.
  """
  def validate_api_version(nil), do: {:ok, @current_api_version}
  def validate_api_version(version) when is_binary(version) do
    if version_supported?(version) do
      {:ok, version}
    else
      {:error, "Unsupported API version: #{version}. Supported versions: #{inspect(@supported_api_versions)}"}
    end
  end
  def validate_api_version(_), do: {:error, "API version must be a string"}
  
  @doc """
  Checks if a tool version is compatible with a requested API version.
  Uses semantic versioning compatibility rules.
  """
  def version_compatible?(tool_version, api_version) when is_binary(tool_version) and is_binary(api_version) do
    # For now, use simple exact matching. 
    # In the future, this could implement semantic versioning rules:
    # - Same major version required for compatibility
    # - Minor/patch versions are backward compatible
    tool_version == api_version
  end

  @doc """
  Returns all available tool definitions for the current API version.
  """
  def get_all_tools do
    get_all_tools(@current_api_version)
  end
  
  @doc """
  Returns all available tool definitions for a specific API version.
  """
  def get_all_tools(api_version) when is_binary(api_version) do
    case validate_api_version(api_version) do
      {:ok, validated_version} ->
        @tools
        |> Enum.filter(fn {_tool_name, tool_version} -> 
          version_compatible?(tool_version, validated_version)
        end)
        |> Enum.map(fn {tool_name, _version} -> 
          get_tool_definition(tool_name, validated_version)
        end)
      {:error, _reason} ->
        []
    end
  end

  @doc """
  Returns a specific tool definition by name for the current API version.
  """
  def get_tool_definition(tool_name) do
    get_tool_definition(tool_name, @current_api_version)
  end
  
  @doc """
  Returns a specific tool definition by name for a specific API version.
  """
  def get_tool_definition(:schedule_activities, api_version) when is_binary(api_version) do
    case validate_api_version(api_version) do
      {:ok, _validated_version} ->
        get_schedule_activities_definition(api_version)
      {:error, reason} ->
        %{error: reason}
    end
  end
  
  
  def get_tool_definition(tool_name, _api_version) do
    Logger.warning("MCPTools: Unknown tool definition requested: #{inspect(tool_name)}")
    %{error: "Unknown tool: #{tool_name}"}
  end
  
  defp get_schedule_activities_definition(api_version) do
    %{
      name: "schedule_activities",
      description: "Schedule activities using AriaEngine's temporal planner with entity and resource management. Returns complete SimulationResult with solution tree.",
      version: "1.0.0",
      apiVersion: api_version,
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
                duration: %{
                  oneOf: [
                    %{
                      type: "string",
                      format: "duration",
                      description: "The activity's duration in ISO 8601 format (e.g., 'PT2H30M', 'PT90S')."
                    },
                    %{
                      type: "integer",
                      description: "The activity's duration in seconds (non-negative integer)."
                    },
                    %{
                      type: "object",
                      properties: %{
                        start: %{
                          type: "string",
                          format: "date-time",
                          description: "Start time in ISO 8601 format."
                        },
                        end: %{
                          type: "string",
                          format: "date-time",
                          description: "End time in ISO 8601 format."
                        }
                      },
                      required: ["start", "end"],
                      description: "A fixed time window for the activity."
                    }
                  ],
                  description: "The duration of the activity, specified as an ISO 8601 duration string (hours/minutes/seconds), a non-negative integer (seconds), or a fixed start/end window (ISO 8601 datetimes)."
                },
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
  

  @doc """
  Handles any tool call by routing to the appropriate handler function.
  """
  def handle_tool_call(tool_name, params) when is_binary(tool_name) do
    tool_atom = String.to_atom(tool_name)
    handle_tool_call(tool_atom, params)
  end
  
  def handle_tool_call(tool_name, params) when is_list(tool_name) do
    # Handle charlist input (convert to string first)
    string_name = List.to_string(tool_name)
    handle_tool_call(string_name, params)
  end

  def handle_tool_call(:schedule_activities, params) do
    handle_schedule_activities_tool_call(params)
  end


  def handle_tool_call(tool_name, _params) do
    Logger.warning("MCPTools: Unknown tool requested: #{inspect(tool_name)}")
    %{
      status: "error",
      reason: "Unknown tool: #{tool_name}",
      schedule: [],
      analysis: %{},
      activity_log: [],
      resource_utilization: %{},
      timeline: [],
      simulation_metadata: %{}
    }
  end

  @doc """
  Handles the schedule_activities tool call with the given parameters.
  """
  def handle_schedule_activities_tool_call(params) do
    try do
      # Validate required parameters
      case validate_params(params) do
        {:ok, validated_params} ->
          # Extract and validate parameters
          schedule_name = validated_params["schedule_name"]
          raw_activities = validated_params["activities"] || []
          
          # Validate activities for type safety and circular dependencies
          case validate_activities(raw_activities) do
            {:ok, validated_activities} ->
              activities = convert_activities(validated_activities)
              entities = convert_entities(validated_params["entities"] || [])
              resources = validated_params["resources"] || %{}
              constraints = validated_params["constraints"] || %{}
              
              # Prepare scheduler options
              opts = [
                entities: entities,
                resources: resources,
                constraints: constraints,
                simulation_mode: Map.get(constraints, "simulation_mode", true),
                verbose: Map.get(constraints, "verbose", 0)
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
            resource_utilization: %{},
            timeline: [],
            simulation_metadata: %{}
          }
      end
    rescue
      e ->
        Logger.error("MCPTools error: #{Exception.message(e)}")
        %{
          status: "error",
          reason: "Internal error: #{Exception.message(e)}",
          schedule: [],
          analysis: %{},
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
        
      String.trim(params["schedule_name"]) == "" ->
        {:error, "schedule_name cannot be empty"}
        
      not Map.has_key?(params, "activities") ->
        {:error, "activities is required"}
        
      not is_list(params["activities"]) ->
        {:error, "activities must be a list"}
        
      true ->
        {:ok, params}
    end
  end
  
  defp validate_params(_), do: {:error, "Invalid parameters format"}
  
  # Validates activities for type safety and circular dependencies.
  defp validate_activities(activities) when is_list(activities) do
    try do
      # First validate each activity's structure and types
      case validate_activity_structures(activities) do
        {:ok, validated_activities} ->
          # Then check for circular dependencies
          case detect_circular_dependencies(validated_activities) do
            :ok -> {:ok, validated_activities}
            {:error, cycle} -> {:error, "Circular dependency detected: #{Enum.join(cycle, " → ")} → #{hd(cycle)}"}
          end
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "Invalid activity format: #{Exception.message(e)}"}
    end
  end
  
  defp validate_activities(_), do: {:error, "Activities must be a list"}
  
  # Validates the structure and types of individual activities.
  defp validate_activity_structures(activities) do
    validated = Enum.map(activities, &validate_single_activity/1)
    
    case Enum.find(validated, &match?({:error, _}, &1)) do
      {:error, reason} -> {:error, reason}
      nil -> {:ok, Enum.map(validated, fn {:ok, activity} -> activity end)}
    end
  end
  
  # Validates a single activity's structure and types.
  defp validate_single_activity(activity) when is_map(activity) do
    with {:ok, id} <- validate_id(activity),
         {:ok, duration} <- validate_duration(activity),
         :ok <- validate_dependencies_format(activity["dependencies"]) do
      
      validated_activity = %{
        "id" => id,
        "duration" => duration,
        "dependencies" => activity["dependencies"] || [],
        "required_capabilities" => activity["required_capabilities"] || [],
        "required_resources" => activity["required_resources"] || []
      }
      {:ok, validated_activity}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Invalid activity structure"}
    end
  end
  
  defp validate_single_activity(_), do: {:error, "Activity must be a map/object"}

  defp validate_id(activity) do
    cond do
      not Map.has_key?(activity, "id") ->
        {:error, "Activity missing required 'id' field"}
      not is_binary(activity["id"]) ->
        {:error, "Activity 'id' must be a string"}
      String.trim(activity["id"]) == "" ->
        {:error, "Activity 'id' cannot be empty"}
      true ->
        {:ok, String.trim(activity["id"])}
    end
  end

  defp validate_duration(activity) do
    case Map.get(activity, "duration") do
      nil ->
        {:error, "Activity missing required 'duration' field"}

      duration_str when is_binary(duration_str) ->
        case parse_iso8601_duration(duration_str) do
          {:ok, _parsed} -> {:ok, duration_str}
          {:error, reason} -> {:error, reason}
        end

      duration_map when is_map(duration_map) ->
        with {:ok, start_time} <- parse_datetime(duration_map, "start"),
             {:ok, end_time} <- parse_datetime(duration_map, "end") do
          if DateTime.compare(end_time, start_time) == :gt do
            {:ok, duration_map}
          else
            {:error, "End time must be after start time"}
          end
        end

      duration_int when is_integer(duration_int) ->
        if duration_int >= 0 do
          {:ok, duration_int}
        else
          {:error, "Activity 'duration' must be non-negative, got: #{duration_int}"}
        end

      _ ->
        {:error, "Invalid 'duration' format. Must be an ISO 8601 duration string, a start/end object, or an integer (seconds)."}
    end
  end

  defp parse_datetime(map, key) do
    case Map.get(map, key) do
      nil -> {:error, "Missing '#{key}' in duration object"}
      datetime_str when is_binary(datetime_str) ->
        case DateTime.from_iso8601(datetime_str) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          {:error, reason} -> {:error, "Invalid '#{key}' datetime format: #{reason}"}
        end
      _ -> {:error, "Invalid '#{key}' format: must be a string"}
    end
  end

  # Parse ISO8601 duration strings like "PT2H30M" without external dependencies
  defp parse_iso8601_duration(duration_str) when is_binary(duration_str) do
    # Simple regex-based parser for common ISO8601 duration formats
    # Supports: PT[n]H[n]M[n]S format
    regex = ~r/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$/
    
    case Regex.run(regex, String.upcase(duration_str)) do
      [_, hours_str, minutes_str, seconds_str] ->
        hours = parse_time_component(hours_str)
        minutes = parse_time_component(minutes_str)
        seconds = parse_time_component(seconds_str)
        
        {:ok, %{hours: hours, minutes: minutes, seconds: seconds}}
      
      [_, hours_str, minutes_str] ->
        hours = parse_time_component(hours_str)
        minutes = parse_time_component(minutes_str)
        
        {:ok, %{hours: hours, minutes: minutes, seconds: 0}}
      
      [_, hours_str] ->
        hours = parse_time_component(hours_str)
        
        {:ok, %{hours: hours, minutes: 0, seconds: 0}}
      
      _ ->
        {:error, "Invalid ISO 8601 duration format: #{duration_str}. Expected format like PT2H30M or PT90M"}
    end
  end

  defp parse_time_component(nil), do: 0
  defp parse_time_component(""), do: 0
  defp parse_time_component(str) when is_binary(str) do
    case Float.parse(str) do
      {value, ""} -> trunc(value)
      _ -> 0
    end
  end
  
  # Validates dependencies format.
  defp validate_dependencies_format(nil), do: :ok
  defp validate_dependencies_format(deps) when is_list(deps) do
    if Enum.all?(deps, &is_binary/1) do
      :ok
    else
      {:error, "Activity 'dependencies' must be a list of strings"}
    end
  end
  defp validate_dependencies_format(_), do: {:error, "Activity 'dependencies' must be a list of strings"}
  
  # Detects circular dependencies using depth-first search.
  defp detect_circular_dependencies(activities) do
    # Build dependency graph
    dependency_graph = build_dependency_graph(activities)
    activity_ids = Enum.map(activities, & &1["id"])
    
    # Check each activity for cycles using DFS
    case find_cycle_in_graph(dependency_graph, activity_ids) do
      nil -> :ok
      cycle -> {:error, cycle}
    end
  end
  
  # Builds a dependency graph from activities.
  defp build_dependency_graph(activities) do
    Enum.reduce(activities, %{}, fn activity, graph ->
      activity_id = activity["id"]
      dependencies = activity["dependencies"] || []
      Map.put(graph, activity_id, dependencies)
    end)
  end
  
  # Finds cycles in the dependency graph using DFS.
  defp find_cycle_in_graph(graph, activity_ids) do
    Enum.find_value(activity_ids, fn start_node ->
      visited = MapSet.new()
      path = []
      dfs_detect_cycle(graph, start_node, visited, path)
    end)
  end
  
  # Depth-first search to detect cycles.
  defp dfs_detect_cycle(graph, node, visited, path) do
    cond do
      node in path ->
        # Found a cycle - return the cycle path
        cycle_start_index = Enum.find_index(path, &(&1 == node))
        Enum.drop(path, cycle_start_index)
        
      MapSet.member?(visited, node) ->
        # Already visited this node in a different path, no cycle here
        nil
        
      true ->
        # Continue DFS
        updated_visited = MapSet.put(visited, node)
        updated_path = [node | path]
        dependencies = Map.get(graph, node, [])
        
        Enum.find_value(dependencies, fn dep ->
          dfs_detect_cycle(graph, dep, updated_visited, updated_path)
        end)
    end
  end
  
defp convert_activities(activities) when is_list(activities) do
    Enum.map(activities, fn activity ->
      %{
        id: Map.get(activity, "id"),
        duration: AriaEngine.Utils.duration_to_seconds(process_duration(Map.get(activity, "duration"))),
        dependencies: Map.get(activity, "dependencies", []),
        required_capabilities: convert_capabilities(Map.get(activity, "required_capabilities", [])),
        required_resources: convert_capabilities(Map.get(activity, "required_resources", []))
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
  defp convert_availability(availability) when is_map(availability), do: availability
  defp convert_availability(_), do: nil
  
  defp convert_simulation_result_to_map(%AriaEngine.Scheduler.SimulationResult{} = result) do
    try do
      %{
        status: result.status,
        reason: result.reason,
        schedule: result.schedule || [],
        analysis: result.analysis || %{},
        resource_utilization: result.resource_utilization || %{},
        timeline: result.timeline || [],
        simulation_metadata: result.simulation_metadata || %{}
      }
    rescue
      e ->
        Logger.error("Error converting SimulationResult to map: #{Exception.message(e)}")
        %{
          status: "error",
          reason: "Conversion error: #{Exception.message(e)}",
          schedule: [],
          analysis: %{},
          activity_log: [],
          resource_utilization: %{},
          timeline: [],
          simulation_metadata: %{}
        }
    end
  end
  

  defp process_duration(duration) do
    cond do
      is_binary(duration) ->
        duration
      is_map(duration) ->
        with {:ok, start_time} <- parse_duration_datetime(duration, "start"),
             {:ok, end_time} <- parse_duration_datetime(duration, "end") do
          seconds = DateTime.diff(end_time, start_time, :second)
          hours = div(seconds, 3600)
          minutes = div(rem(seconds, 3600), 60)
          secs = rem(seconds, 60)
          "PT" <>
            (if hours > 0, do: "#{hours}H", else: "") <>
            (if minutes > 0, do: "#{minutes}M", else: "") <>
            (if secs > 0, do: "#{secs}S", else: "")
        else
          _ -> nil
        end
      is_float(duration) ->
        duration
      is_integer(duration) ->
        duration * 1.0
      true ->
        nil
    end
  end

  defp convert_parsed_duration_to_seconds(%{hours: hours, minutes: minutes, seconds: seconds}) do
    hours * 3600 + minutes * 60 + trunc(seconds)
  end

  defp parse_duration_datetime(map, key) do
    case Map.get(map, key) do
      nil -> {:error, "Missing '#{key}' in duration object"}
      datetime_str when is_binary(datetime_str) ->
        case DateTime.from_iso8601(datetime_str) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          {:error, reason} -> {:error, "Invalid '#{key}' datetime format: #{reason}"}
        end
      _ -> {:error, "Invalid '#{key}' format: must be a string"}
    end
  end
end
