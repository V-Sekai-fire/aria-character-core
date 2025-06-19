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
    {:schedule_activities, "1.0.0"},
    {:director, "1.1.0"}
    # Add new tools here with version, e.g.:
    # {:analyze_timeline, "1.1.0"},
    # {:optimize_resources, "1.2.0"},
    # {:generate_report, "2.0.0"}
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
  
  def get_tool_definition(:director, api_version) when is_binary(api_version) do
    case validate_api_version(api_version) do
      {:ok, _validated_version} ->
        get_director_definition(api_version)
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
                      description: "The activity's duration in ISO 8601 format (e.g., 'PT2H30M')."
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
                  description: "The duration of the activity, specified as a time span or a fixed start/end window."
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
  
  defp get_director_definition(api_version) do
    %{
      name: "director",
      description: "Direct complex scenarios with entities, resources, and narrative flow coordination",
      version: "1.0.0",
      apiVersion: api_version,
      inputSchema: %{
        type: "object",
        properties: %{
          template: %{
            type: "string",
            enum: ["tri_zone_integration"],
            description: "Built-in mission template",
            examples: [
              %{
                value: "tri_zone_integration",
                summary: "Cross-Spectrum Protocol: Multi-zone integration mission",
                description: "Complex scenario across Verdant (bio-tech), Chrome (corporate), and Harmony (synthesis) districts. Features resource conflicts, entity cooperation, and temporal coordination challenges. Duration: ~20 minutes with 15 overlapping activities."
              }
            ]
          },
          narrative_mode: %{
            type: "boolean",
            default: true,
            description: "Include DateTime-stamped narrative markdown"
          }
        },
        required: ["template"]
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

  def handle_tool_call(:director, params) do
    handle_director_tool_call(params)
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
        Logger.error("MCPTools error: #{Exception.message(e)}")
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
        # Backwards compatibility for integer durations (minutes)
        if duration_int >= 0 do
          {:ok, duration_int}
        else
          {:error, "Activity 'duration' must be non-negative, got: #{duration_int}"}
        end
      
      _ ->
        {:error, "Invalid 'duration' format. Must be an ISO 8601 duration string, a start/end object, or an integer (minutes)."}
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
        duration: process_duration(Map.get(activity, "duration")),
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
          # Handle both timestamp and mission_duration formats
          time_info = case {log_entry.timestamp, log_entry.mission_duration} do
            {%DateTime{} = timestamp, _} ->
              %{timestamp: safe_datetime_to_iso8601(timestamp)}
            {nil, mission_duration} when is_binary(mission_duration) ->
              %{mission_duration: mission_duration}
            _ ->
              %{relative_minutes: log_entry.relative_minutes}
          end
          
          base_entry = %{
            activity_id: log_entry.activity_id,
            entity_id: log_entry.entity_id,
            event_type: log_entry.event_type,
            resource_snapshot: log_entry.resource_snapshot || %{},
            state_changes: log_entry.state_changes || [],
            metadata: log_entry.metadata || %{}
          }
          
          Map.merge(base_entry, time_info)
        _ ->
          entry
      end
    end)
  end
  
  defp convert_activity_log(_), do: []

  # Safe DateTime to ISO8601 conversion with proper Erlang syntax
  defp safe_datetime_to_iso8601(timestamp) do
    case timestamp do
      %DateTime{} = dt ->
        DateTime.to_iso8601(dt)
      
      {{year, month, day}, {hour, minute, second}} ->
        # Erlang datetime tuple format - convert to ISO8601 using NaiveDateTime
        case NaiveDateTime.from_erl({{year, month, day}, {hour, minute, second}}) do
          {:ok, naive_dt} -> NaiveDateTime.to_iso8601(naive_dt)
          {:error, _} -> "Invalid datetime tuple"
        end
      
      timestamp_str when is_binary(timestamp_str) ->
        timestamp_str
      
      timestamp_int when is_integer(timestamp_int) ->
        # Unix timestamp - convert to DateTime first
        case DateTime.from_unix(timestamp_int) do
          {:ok, dt} -> DateTime.to_iso8601(dt)
          {:error, _} -> "Invalid timestamp"
        end
      
      _ ->
        "Unknown timestamp format"
    end
  rescue
    _ -> "Error formatting timestamp"
  end

  defp process_duration(duration) do
    case duration do
      duration_str when is_binary(duration_str) ->
        case parse_iso8601_duration(duration_str) do
          {:ok, parsed_duration} ->
            convert_parsed_duration_to_minutes(parsed_duration)
          {:error, _} -> nil
        end
      duration_map when is_map(duration_map) ->
        with {:ok, start_time} <- parse_duration_datetime(duration_map, "start"),
             {:ok, end_time} <- parse_duration_datetime(duration_map, "end") do
          DateTime.diff(end_time, start_time, :minute)
        else
          _ -> nil
        end
      duration_int when is_integer(duration_int) ->
        # Keep integer durations as-is (test compatibility)
        duration_int
      _ ->
        nil
    end
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

  defp convert_parsed_duration_to_minutes(%{hours: hours, minutes: minutes, seconds: seconds}) do
    # Convert to minutes for scheduler compatibility
    hours * 60 + minutes + div(seconds, 60)
  end

  defp convert_duration_to_minutes(duration_proplist) when is_list(duration_proplist) do
    hours = Keyword.get(duration_proplist, :hours, 0)
    minutes = Keyword.get(duration_proplist, :minutes, 0)
    seconds = Keyword.get(duration_proplist, :seconds, 0)
    
    # Convert to minutes for test compatibility (keep existing behavior)
    hours * 60 + minutes + div(seconds, 60)
  end

  @doc """
  Handles the director tool call with template-based mission execution.
  """
  def handle_director_tool_call(params) do
    try do
      # Validate parameters
      case validate_director_params(params) do
        {:ok, validated_params} ->
          template = validated_params["template"]
          narrative_mode = Map.get(validated_params, "narrative_mode", true)
          
          # Load mission data based on template
          case load_template_data(template) do
            {:ok, mission_data} ->
              # Execute the mission using existing scheduler
              execute_mission(mission_data, narrative_mode)
              
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
        Logger.error("Director tool error: #{Exception.message(e)}")
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

  defp validate_director_params(params) when is_map(params) do
    cond do
      not Map.has_key?(params, "template") ->
        {:error, "template is required"}
        
      not is_binary(params["template"]) ->
        {:error, "template must be a string"}
        
      params["template"] not in ["tri_zone_integration"] ->
        {:error, "unsupported template: #{params["template"]}. Available templates: tri_zone_integration"}
        
      true ->
        {:ok, params}
    end
  end
  
  defp validate_director_params(_), do: {:error, "Invalid parameters format"}

  defp load_template_data("tri_zone_integration") do
    # Hardcoded mission data from isekai_merged_realms.json
    mission_data = %{
      "schedule_name" => "Cross-Spectrum Protocol: The Merged Realms",
      "activities" => get_tri_zone_activities(),
      "entities" => get_tri_zone_entities(),
      "resources" => get_tri_zone_resources(),
      "constraints" => get_tri_zone_constraints()
    }
    {:ok, mission_data}
  end
  
  defp load_template_data(template) do
    {:error, "Unknown template: #{template}"}
  end

  defp execute_mission(mission_data, narrative_mode) do
    # Convert mission data to scheduler format
    schedule_name = mission_data["schedule_name"]
    activities = convert_activities(mission_data["activities"])
    entities = convert_entities(mission_data["entities"])
    resources = mission_data["resources"]
    constraints = mission_data["constraints"]
    
    # Prepare scheduler options
    opts = [
      entities: entities,
      resources: resources,
      constraints: constraints,
      simulation_mode: Map.get(constraints, "simulation_mode", true),
      verbose: Map.get(constraints, "verbose", 2),
      log_activities: true,
      narrative_mode: narrative_mode
    ]
    
    # Call the scheduler
    case AriaEngine.Scheduler.schedule_activities(schedule_name, activities, opts) do
      {:ok, simulation_result} ->
        # Enhanced output with narrative if requested
        result = convert_simulation_result_to_map(simulation_result)
        
        if narrative_mode do
          Map.put(result, :narrative, generate_narrative(simulation_result))
        else
          result
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
  end

  defp generate_narrative(simulation_result) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    entity_lookup = create_entity_lookup()
    
    """
    # Cross-District Integration Mission
    
    **Mission Execution Report**  
    *Generated: #{timestamp}*
    
    ## Mission Overview
    
    A multi-disciplinary team successfully executed a complex cross-district integration protocol, combining expertise from logistics, biotechnology, cybersecurity, community organizing, emergency medicine, creative technology, data analysis, and urban planning to establish sustainable connections between three distinct urban districts.
    
    ## Team Achievements
    
    #{generate_team_achievements(simulation_result, entity_lookup)}
    
    ## Technical Results
    
    **Total Activities Scheduled**: #{length(simulation_result.schedule || [])}  
    **Mission Duration**: #{get_total_duration(simulation_result)}  
    **Resource Efficiency**: #{calculate_resource_efficiency(simulation_result)}  
    **Success Status**: #{simulation_result.status}
    
    ## Detailed Action Timeline
    
    #{generate_detailed_activity_timeline(simulation_result, entity_lookup)}
    
    ## Mission Completion
    
    #{generate_mission_summary(simulation_result, entity_lookup)}
    
    *End of Mission Report*
    """
  end

  defp get_total_duration(simulation_result) do
    case simulation_result.analysis do
      %{total_duration: duration} -> "#{duration} minutes"
      _ -> "Unknown"
    end
  end

  defp calculate_resource_efficiency(simulation_result) do
    case simulation_result.resource_utilization do
      resources when map_size(resources) > 0 ->
        total_used = Enum.reduce(resources, 0, fn {_key, usage}, acc -> 
          case usage do
            %{current_usage: used} -> acc + used
            _ -> acc
          end
        end)
        "#{total_used}% utilized"
      _ -> "Not calculated"
    end
  end

  defp generate_activity_timeline(simulation_result) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        activities
        |> Enum.take(10)  # Show first 10 activities
        |> Enum.map_join("\n", fn activity ->
          timestamp = Map.get(activity, :timestamp, Map.get(activity, "timestamp", "Unknown"))
          activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id", "unknown"))
          entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id", "unknown"))
          
          "- **#{format_timestamp(timestamp)}**: #{humanize_activity_id(activity_id)} (#{entity_id})"
        end)
      _ -> "No detailed timeline available"
    end
  end

  defp format_timestamp(timestamp) when is_binary(timestamp), do: timestamp
  defp format_timestamp(%DateTime{} = dt), do: DateTime.to_time(dt) |> Time.to_string()
  defp format_timestamp(_), do: "Unknown"

  defp humanize_activity_id(activity_id) do
    activity_id
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  # Helper functions for personalized narrative generation
  defp create_entity_lookup do
    entities = get_tri_zone_entities()
    Enum.reduce(entities, %{}, fn entity, acc ->
      Map.put(acc, entity["id"], entity)
    end)
  end

  defp generate_team_achievements(simulation_result, entity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        # Group activities by entity to show individual contributions
        entity_contributions = Enum.group_by(activities, fn activity ->
          Map.get(activity, :entity_id, Map.get(activity, "entity_id", "unknown"))
        end)
        
        entity_contributions
        |> Enum.map(fn {entity_id, entity_activities} ->
          entity_info = Map.get(entity_lookup, entity_id, %{"name" => entity_id, "background" => "Unknown specialist"})
          activity_count = length(entity_activities)
          
          key_activities = entity_activities
          |> Enum.take(2)
          |> Enum.map(fn activity ->
            activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id", "unknown"))
            humanize_activity_id(activity_id)
          end)
          |> Enum.join(" and ")
          
          "- **#{entity_info["name"]}**: Led #{key_activities} among #{activity_count} total activities, leveraging #{String.split(entity_info["background"], ",") |> hd()}"
        end)
        |> Enum.join("\n")
      _ -> "Team member contributions not available in detailed logs."
    end
  end

  defp generate_detailed_activity_timeline(simulation_result, entity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        activities
        |> Enum.take(8)  # Show first 8 activities for detail
        |> Enum.map(fn activity ->
          # Extract timestamp - try multiple possible fields
          timestamp = Map.get(activity, :mission_duration, 
                              Map.get(activity, "mission_duration",
                              Map.get(activity, :timestamp, 
                              Map.get(activity, "timestamp", "Unknown"))))
          
          activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id", "unknown"))
          entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id", "unknown"))
          
          # Handle empty or missing entity_id
          actual_entity_id = if entity_id == "unknown" or entity_id == "" or is_nil(entity_id) do
            # Try to find an entity that can handle this activity's capabilities
            find_capable_entity_for_activity(activity_id, entity_lookup)
          else
            entity_id
          end
          
          entity_info = Map.get(entity_lookup, actual_entity_id, %{"name" => "Unassigned Specialist", "capabilities" => [], "background" => "Cross-functional expertise"})
          
          # Generate specific action description based on entity and activity
          action_description = generate_specific_action_description(activity_id, entity_info, entity_lookup)
          
          "- **#{format_timestamp(timestamp)}**: #{action_description}"
        end)
        |> Enum.join("\n")
      _ -> "Detailed timeline not available - no activity log entries found."
    end
  end

  defp generate_specific_action_description(activity_id, entity_info, _entity_lookup) do
    entity_name = entity_info["name"] || "Unknown"
    entity_background = entity_info["background"] || ""
    capabilities = entity_info["capabilities"] || []
    
    # Generate contextual descriptions based on activity and entity background
    case activity_id do
      "initial_situation_assessment" ->
        "#{entity_name} applied #{get_relevant_capability(capabilities, ["rapid_assessment", "crisis_coordination"])} expertise to conduct comprehensive situation analysis, drawing on #{extract_experience(entity_background)}"
      
      "bio_district_infrastructure_survey" ->
        "#{entity_name} utilized #{get_relevant_capability(capabilities, ["ecosystem_analysis", "environmental_monitoring"])} skills to map bio-district infrastructure, leveraging background in #{extract_field(entity_background)}"
      
      "plant_computer_interface_setup" ->
        "#{entity_name} established plant-computer interfaces using #{get_relevant_capability(capabilities, ["plant_computer_interfaces", "bio_integration"])} expertise, building on #{extract_experience(entity_background)}"
      
      "underground_network_reconnaissance" ->
        "#{entity_name} conducted stealth reconnaissance of underground networks, applying #{get_relevant_capability(capabilities, ["stealth_operations", "network_penetration"])} skills from #{extract_field(entity_background)}"
      
      "community_stakeholder_coordination" ->
        "#{entity_name} coordinated with community stakeholders using #{get_relevant_capability(capabilities, ["stakeholder_coordination", "community_building"])} experience, drawing on #{extract_experience(entity_background)}"
      
      "ar_interface_development" ->
        "#{entity_name} developed AR interfaces leveraging #{get_relevant_capability(capabilities, ["ar_development", "user_interface_design"])} skills, utilizing background in #{extract_field(entity_background)}"
      
      _ ->
        "#{entity_name} executed #{humanize_activity_id(activity_id)} using #{get_first_capability(capabilities)} expertise, applying #{extract_experience(entity_background)}"
    end
  end

  defp get_relevant_capability(capabilities, preferred_caps) do
    relevant = Enum.find(capabilities, fn cap ->
      cap_str = to_string(cap)
      Enum.any?(preferred_caps, fn pref -> cap_str == pref end)
    end)
    
    case relevant do
      nil -> get_first_capability(capabilities)
      cap -> cap |> to_string() |> String.replace("_", " ")
    end
  end

  defp get_first_capability([]), do: "general problem-solving"
  defp get_first_capability([cap | _]), do: cap |> to_string() |> String.replace("_", " ")

  defp extract_experience(background) when is_binary(background) do
    cond do
      String.contains?(background, "years") -> 
        background |> String.split(",") |> Enum.find(&String.contains?(&1, "years")) || "extensive experience"
      String.contains?(background, "former") or String.contains?(background, "Former") ->
        background |> String.split(",") |> hd() |> String.trim()
      true -> 
        background |> String.split(",") |> hd() |> String.trim()
    end
  end
  defp extract_experience(_), do: "relevant professional experience"

  defp extract_field(background) when is_binary(background) do
    cond do
      String.contains?(background, "University") -> "academic research"
      String.contains?(background, "freelance") -> "independent consulting"  
      String.contains?(background, "neighborhood") -> "community organizing"
      String.contains?(background, "emergency") or String.contains?(background, "medicine") -> "emergency medicine"
      String.contains?(background, "game") or String.contains?(background, "indie") -> "creative technology"
      String.contains?(background, "Systems") -> "data systems analysis"
      String.contains?(background, "planning") -> "urban planning"
      String.contains?(background, "Flow") -> "logistics coordination"
      true -> "professional specialization"
    end
  end
  defp extract_field(_), do: "professional background"

  # Helper function to find an entity capable of handling a specific activity
  defp find_capable_entity_for_activity(activity_id, entity_lookup) do
    # Get activity requirements
    activity_requirements = get_activity_requirements(activity_id)
    
    # Find the best matching entity based on capabilities
    best_entity = entity_lookup
    |> Enum.find(fn {_entity_id, entity_info} ->
      entity_capabilities = entity_info["capabilities"] || []
      
      # Check if this entity has any of the required capabilities
      Enum.any?(activity_requirements, fn req_cap ->
        Enum.any?(entity_capabilities, fn entity_cap ->
          to_string(entity_cap) == req_cap
        end)
      end)
    end)
    
    case best_entity do
      {entity_id, _entity_info} -> entity_id
      nil -> 
        # Fallback: assign to Dr. Kai Chen for crisis management
        "dr_kai_chen"
    end
  end

  # Get required capabilities for a specific activity
  defp get_activity_requirements(activity_id) do
    case activity_id do
      "initial_situation_assessment" -> ["rapid_assessment", "crisis_coordination"]
      "bio_district_infrastructure_survey" -> ["ecosystem_analysis", "environmental_monitoring"]
      "plant_computer_interface_setup" -> ["plant_computer_interfaces", "bio_integration"]
      "bio_sensor_network_integration" -> ["bio_integration", "system_integration"]
      "environmental_monitoring_deployment" -> ["environmental_monitoring", "data_analysis"]
      "underground_network_reconnaissance" -> ["stealth_operations", "network_penetration"]
      "corporate_security_audit" -> ["security_audits", "incident_response"]
      "data_recovery_operations" -> ["data_recovery", "data_analysis"]
      "community_stakeholder_coordination" -> ["stakeholder_coordination", "community_building"]
      "resource_sharing_network_setup" -> ["resource_sharing", "volunteer_coordination"]
      "cross_district_protocol_design" -> ["systems_thinking", "process_design"]
      "mesh_network_communication_setup" -> ["system_integration", "real_time_monitoring"]
      "integrated_systems_coordination" -> ["multi_team_coordination", "infrastructure_planning"]
      "ar_interface_development" -> ["ar_development", "user_interface_design"]
      "final_system_validation" -> ["predictive_modeling", "rapid_assessment"]
      _ -> ["crisis_coordination"]  # Default fallback
    end
  end

  defp generate_mission_summary(simulation_result, entity_lookup) do
    total_entities = map_size(entity_lookup)
    
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        active_entities = activities
        |> Enum.map(fn activity -> Map.get(activity, :entity_id, Map.get(activity, "entity_id")) end)
        |> Enum.uniq()
        |> length()
        
        """
        The cross-district integration mission successfully coordinated #{active_entities} specialized team members from diverse professional backgrounds, including logistics, biotechnology, cybersecurity, community organizing, emergency medicine, creative technology, data analysis, and urban planning. The mission established sustainable communication channels between districts, implemented resource-sharing protocols, and created integrated monitoring systems.
        
        Key innovations included plant-computer interface protocols developed by botanical researchers, mesh network communication systems designed by data specialists, and community engagement frameworks created by neighborhood organizers. The team's diverse expertise enabled comprehensive solutions spanning technical, social, and infrastructural challenges.
        """
      _ ->
        """
        The mission planning phase was completed with #{total_entities} team members identified across multiple specializations. Full execution logs are not available, but the comprehensive planning phase established frameworks for cross-district integration including technical protocols, community engagement strategies, and resource coordination systems.
        """
    end
  end

  # Template data definitions
  defp get_tri_zone_activities() do
    [
      %{
        "id" => "initial_situation_assessment",
        "duration" => "PT2H",
        "dependencies" => [],
        "required_capabilities" => ["rapid_assessment", "crisis_coordination"],
        "required_resources" => ["sensor_network"]
      },
      %{
        "id" => "bio_district_infrastructure_survey",
        "duration" => "PT45M",
        "dependencies" => ["initial_situation_assessment"],
        "required_capabilities" => ["ecosystem_analysis", "environmental_monitoring"],
        "required_resources" => ["bio_energy"]
      },
      %{
        "id" => "plant_computer_interface_setup",
        "duration" => "PT3H",
        "dependencies" => ["bio_district_infrastructure_survey"],
        "required_capabilities" => ["plant_computer_interfaces", "bio_integration"],
        "required_resources" => ["bio_energy", "collective_knowledge"]
      },
      %{
        "id" => "bio_sensor_network_integration",
        "duration" => "PT90M",
        "dependencies" => ["plant_computer_interface_setup"],
        "required_capabilities" => ["bio_integration", "system_integration"],
        "required_resources" => ["collective_knowledge", "sensor_network"]
      },
      %{
        "id" => "environmental_monitoring_deployment",
        "duration" => "PT2H",
        "dependencies" => ["bio_sensor_network_integration"],
        "required_capabilities" => ["environmental_monitoring", "data_analysis"],
        "required_resources" => ["bio_energy", "sensor_network"]
      },
      %{
        "id" => "underground_network_reconnaissance",
        "duration" => "PT4H",
        "dependencies" => ["environmental_monitoring_deployment"],
        "required_capabilities" => ["stealth_operations", "network_penetration"],
        "required_resources" => ["stolen_access_codes"]
      },
      %{
        "id" => "corporate_security_audit",
        "duration" => "PT6H",
        "dependencies" => ["underground_network_reconnaissance"],
        "required_capabilities" => ["security_audits", "incident_response"],
        "required_resources" => ["stolen_access_codes", "storage_devices"]
      },
      %{
        "id" => "data_recovery_operations",
        "duration" => "PT3H",
        "dependencies" => ["corporate_security_audit"],
        "required_capabilities" => ["data_recovery", "data_analysis"],
        "required_resources" => ["storage_devices"]
      },
      %{
        "id" => "community_stakeholder_coordination",
        "duration" => "PT5H",
        "dependencies" => ["data_recovery_operations"],
        "required_capabilities" => ["stakeholder_coordination", "community_building"],
        "required_resources" => ["community_credits"]
      },
      %{
        "id" => "resource_sharing_network_setup",
        "duration" => "PT4H",
        "dependencies" => ["community_stakeholder_coordination"],
        "required_capabilities" => ["resource_sharing", "volunteer_coordination"],
        "required_resources" => ["public_fabricators", "community_credits"]
      },
      %{
        "id" => "cross_district_protocol_design",
        "duration" => "PT8H",
        "dependencies" => ["resource_sharing_network_setup", "bio_sensor_network_integration"],
        "required_capabilities" => ["systems_thinking", "process_design"],
        "required_resources" => ["bio_energy", "community_credits", "collective_knowledge"]
      },
      %{
        "id" => "mesh_network_communication_setup",
        "duration" => "PT2H",
        "dependencies" => ["cross_district_protocol_design"],
        "required_capabilities" => ["system_integration", "real_time_monitoring"],
        "required_resources" => ["mesh_network", "translation_matrices"]
      },
      %{
        "id" => "integrated_systems_coordination",
        "duration" => "PT12H",
        "dependencies" => ["mesh_network_communication_setup"],
        "required_capabilities" => ["multi_team_coordination", "infrastructure_planning"],
        "required_resources" => ["bio_energy", "community_credits", "mesh_network"]
      },
      %{
        "id" => "ar_interface_development",
        "duration" => "PT30M",
        "dependencies" => ["integrated_systems_coordination"],
        "required_capabilities" => ["ar_development", "user_interface_design"],
        "required_resources" => ["translation_matrices"]
      },
      %{
        "id" => "final_system_validation",
        "duration" => "PT15M",
        "dependencies" => ["ar_interface_development"],
        "required_capabilities" => ["predictive_modeling", "rapid_assessment"],
        "required_resources" => ["sensor_network"]
      }
    ]
  end

  defp get_tri_zone_entities() do
    [
      %{
        "id" => "alex_rivera",
        "name" => "Alex Rivera, SynergyFlow logistics coordinator",
        "type" => "logistics_specialist",
        "capabilities" => ["supply_chain_optimization", "crisis_coordination", "cross_team_communication", "resource_allocation", "route_planning"],
        "background" => "Former SynergyFlow distribution specialist with 8 years coordinating multi-site operations",
        "availability" => %{}
      },
      %{
        "id" => "dr_elena_vasquez",
        "name" => "Dr. Elena Vasquez, Greenfield University botanical researcher",
        "type" => "bio_researcher",
        "capabilities" => ["bio_integration", "ecosystem_analysis", "plant_computer_interfaces", "environmental_monitoring", "biological_protocols"],
        "background" => "Published researcher on plant-computer interfaces, community garden coordinator",
        "availability" => %{}
      },
      %{
        "id" => "jake_morrison",
        "name" => "Jake Morrison, freelance security researcher",
        "type" => "security_expert",
        "capabilities" => ["network_penetration", "data_recovery", "security_audits", "incident_response", "stealth_operations"],
        "background" => "Former military IT specialist, now freelance penetration tester for small businesses",
        "availability" => %{}
      },
      %{
        "id" => "maria_santos",
        "name" => "Maria Santos, neighborhood organizer",
        "type" => "community_coordinator",
        "capabilities" => ["community_building", "resource_sharing", "conflict_mediation", "volunteer_coordination", "grassroots_organizing"],
        "background" => "Runs neighborhood tool library, coordinates mutual aid and disaster response",
        "availability" => %{}
      },
      %{
        "id" => "dr_kai_chen",
        "name" => "Dr. Kai Chen, emergency medicine physician",
        "type" => "crisis_specialist",
        "capabilities" => ["rapid_assessment", "multi_team_coordination", "stress_management", "emergency_protocols", "triage_decision_making"],
        "background" => "Emergency room physician at Metro General, specializes in disaster response coordination",
        "availability" => %{}
      },
      %{
        "id" => "river_thompson",
        "name" => "River Thompson, indie game developer",
        "type" => "creative_technologist",
        "capabilities" => ["user_interface_design", "creative_problem_solving", "storytelling", "ar_development", "community_engagement"],
        "background" => "Indie game developer creating AR experiences for community events and social causes",
        "availability" => %{}
      },
      %{
        "id" => "sam_okafor",
        "name" => "Sam Okafor, DataFlow Systems analyst",
        "type" => "data_specialist",
        "capabilities" => ["data_analysis", "pattern_recognition", "system_integration", "real_time_monitoring", "predictive_modeling"],
        "background" => "Senior data analyst at DataFlow Systems, expertise in cross-platform integration",
        "availability" => %{}
      },
      %{
        "id" => "casey_nguyen",
        "name" => "Casey Nguyen, urban planning consultant",
        "type" => "systems_coordinator",
        "capabilities" => ["systems_thinking", "stakeholder_coordination", "resource_optimization", "infrastructure_planning", "process_design"],
        "background" => "Urban planning consultant specializing in sustainable community development",
        "availability" => %{}
      }
    ]
  end

  defp get_tri_zone_resources() do
    %{
      "reality_anchors" => %{
        "type" => "dimensional_stability",
        "capacity" => 3,
        "current_usage" => 0
      },
      "bio_energy" => %{
        "type" => "renewable_organic",
        "capacity" => 100,
        "current_usage" => 0
      },
      "collective_knowledge" => %{
        "type" => "shared_information",
        "capacity" => 50,
        "current_usage" => 0
      },
      "stolen_access_codes" => %{
        "type" => "limited_security",
        "capacity" => 5,
        "current_usage" => 0
      },
      "illegal_augments" => %{
        "type" => "black_market_tech",
        "capacity" => 3,
        "current_usage" => 0
      },
      "storage_devices" => %{
        "type" => "data_container",
        "capacity" => 10,
        "current_usage" => 0
      },
      "underground_currency" => %{
        "type" => "alternative_economy",
        "capacity" => 25,
        "current_usage" => 0
      },
      "public_fabricators" => %{
        "type" => "shared_manufacturing",
        "capacity" => 8,
        "current_usage" => 0
      },
      "community_credits" => %{
        "type" => "cooperative_economy",
        "capacity" => 40,
        "current_usage" => 0
      },
      "mesh_network" => %{
        "type" => "distributed_communication",
        "capacity" => 15,
        "current_usage" => 0
      },
      "translation_matrices" => %{
        "type" => "cross_zone_protocol",
        "capacity" => 6,
        "current_usage" => 0
      },
      "sensor_network" => %{
        "type" => "environmental_monitoring",
        "capacity" => 12,
        "current_usage" => 0
      }
    }
  end

  defp get_tri_zone_constraints() do
    %{
      "max_duration" => 1200,
      "simulation_mode" => true,
      "verbose" => 2,
      "narrative_flow" => true,
      "cross_zone_dependencies" => true,
      "resource_compatibility_matrix" => %{
        "bio_energy" => ["verdant_sector", "harmony_hub"],
        "stolen_access_codes" => ["chrome_underworld"],
        "community_credits" => ["harmony_hub", "tri_zone_integration"],
        "reality_anchors" => ["dimensional_operations"]
      }
    }
  end
end
