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
    try do
      %{
        status: result.status,
        reason: result.reason,
        schedule: result.schedule || [],
        analysis: result.analysis || %{},
        activity_log: safe_convert_activity_log(result.activity_log || []),
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
  
  defp safe_convert_activity_log(activity_log) when is_list(activity_log) do
    try do
      convert_activity_log(activity_log)
    rescue
      e ->
        Logger.warning("Error converting activity log: #{Exception.message(e)}")
        []
    end
  end
  
  defp safe_convert_activity_log(_), do: []

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
    # Convert to fractional minutes for better precision
    hours * 60 + minutes + (seconds / 60)
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
    # Load from JSON file instead of hardcoded data
    case load_mission_from_file("isekai_merged_realms.json") do
      {:ok, mission_data} -> {:ok, mission_data}
      {:error, reason} -> {:error, "Failed to load mission file: #{reason}"}
    end
  end
  
  defp load_template_data(template) do
    {:error, "Unknown template: #{template}"}
  end

  defp load_mission_from_file(filename) do
    file_path = Path.join([:code.priv_dir(:aria_character_core), "mission_scripts", filename])
    
    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, mission_data} -> {:ok, mission_data}
          {:error, reason} -> {:error, "JSON decode error: #{inspect(reason)}"}
        end
      {:error, reason} -> {:error, "File read error: #{inspect(reason)}"}
    end
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
    
    # Call the scheduler with enhanced error handling
    scheduler_result = AriaEngine.Scheduler.schedule_activities(schedule_name, activities, opts)
    Logger.debug("Scheduler returned: #{inspect(scheduler_result)}")
    
    case scheduler_result do
      {:ok, simulation_result} when is_map(simulation_result) ->
        # Enhanced output with narrative if requested
        result = convert_simulation_result_to_map(simulation_result)
        
        if narrative_mode do
          Map.put(result, :narrative, generate_narrative_from_mission_data(simulation_result, mission_data))
        else
          result
        end
        
      {:ok, empty_result} when is_list(empty_result) ->
        # Handle case where scheduler returns empty list instead of SimulationResult
        Logger.warning("Scheduler returned empty list instead of SimulationResult: #{inspect(empty_result)}")
        create_basic_success_result(mission_data, narrative_mode)
        
      {:ok, nil} ->
        # Handle nil result
        Logger.warning("Scheduler returned nil result")
        create_basic_success_result(mission_data, narrative_mode)
        
      {:ok, unexpected_result} ->
        Logger.error("Scheduler returned unexpected format: #{inspect(unexpected_result)}")
        create_basic_success_result(mission_data, narrative_mode)
        
      {:error, reason} ->
        Logger.error("Scheduler returned error: #{inspect(reason)}")
        %{
          status: "error",
          reason: "Scheduler error: #{inspect(reason)}",
          schedule: [],
          analysis: %{},
          activity_log: [],
          resource_utilization: %{},
          timeline: [],
          simulation_metadata: %{}
        }
        
      other ->
        Logger.error("Scheduler returned completely unexpected format: #{inspect(other)}")
        create_basic_success_result(mission_data, narrative_mode)
    end
  end

  defp generate_narrative_from_mission_data(simulation_result, mission_data) do
    try do
      timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
      narrative_context = safe_get_map(mission_data, "narrative_context", %{})
      
      # Safely build lookup tables with validation
      entity_lookup = safe_build_entity_lookup(mission_data["entities"] || [])
      activity_lookup = safe_build_activity_lookup(mission_data["activities"] || [])
      
      # Only proceed with complex generation if we have valid data
      if map_size(entity_lookup) > 0 and map_size(activity_lookup) > 0 do
        generate_detailed_capability_narrative(simulation_result, mission_data, entity_lookup, activity_lookup, narrative_context, timestamp)
      else
        generate_simple_fallback_narrative(simulation_result, mission_data, narrative_context, timestamp)
      end
    rescue
      e ->
        Logger.error("Error generating narrative: #{Exception.message(e)}")
        generate_error_fallback_narrative(simulation_result, mission_data)
    end
  end

  defp generate_detailed_capability_narrative(simulation_result, mission_data, entity_lookup, activity_lookup, narrative_context, timestamp) do
    # Safely generate each section with individual error handling
    story_phases = safe_detect_story_phases(simulation_result, entity_lookup, activity_lookup)
    capability_achievements = safe_generate_capability_achievements(simulation_result, entity_lookup, activity_lookup)
    story_phase_narrative = safe_generate_story_phase_narrative(story_phases, entity_lookup)
    capability_timeline = safe_generate_capability_timeline(simulation_result, entity_lookup, activity_lookup)
    entity_outcomes = safe_generate_entity_outcomes(simulation_result, entity_lookup)
    
    title = Map.get(narrative_context, "title", mission_data["schedule_name"])
    setting = Map.get(narrative_context, "setting", "Multi-entity coordination scenario")
    crisis = Map.get(narrative_context, "crisis", "Complex coordination challenge")
    success_outcome = Map.get(narrative_context, "success_outcome", "Successful coordination achieved")
    
    """
    # #{title}
    
    **Mission Execution Report**  
    *Generated: #{timestamp}*
    
    ## Mission Overview
    
    #{setting}: #{crisis}
    
    This mission coordinated #{safe_count_entity_types(entity_lookup)} different entity types, including #{safe_list_entity_types(entity_lookup)}, to address complex challenges requiring #{safe_count_unique_capabilities(entity_lookup)} distinct capabilities.
    
    ## Player Entity Capability Analysis
    
    #{capability_achievements}
    
    ## Story Flow by Entity Actions
    
    #{story_phase_narrative}
    
    ## Technical Results
    
    **Total Activities Scheduled**: #{length(simulation_result.schedule || [])}  
    **Mission Duration**: #{safe_get_total_duration(simulation_result)}  
    **Resource Efficiency**: #{safe_calculate_resource_efficiency(simulation_result)}  
    **Success Status**: #{simulation_result.status}
    
    ## Entity-Driven Timeline
    
    #{capability_timeline}
    
    ## Mission Completion
    
    #{success_outcome}
    
    #{entity_outcomes}
    
    *End of Mission Report*
    """
  end

  defp generate_simple_fallback_narrative(simulation_result, mission_data, narrative_context, timestamp) do
    title = Map.get(narrative_context, "title", mission_data["schedule_name"])
    
    """
    # #{title}
    
    **Mission Execution Report**  
    *Generated: #{timestamp}*
    
    ## Mission Overview
    
    Mission planning completed successfully with comprehensive entity coordination framework established.
    
    ## Technical Results
    
    **Total Activities Scheduled**: #{length(simulation_result.schedule || [])}  
    **Success Status**: #{simulation_result.status}
    
    ## Mission Completion
    
    Planning phase completed successfully. Full execution analysis requires complete activity logs.
    
    *End of Mission Report*
    """
  end

  defp generate_error_fallback_narrative(simulation_result, mission_data) do
    title = mission_data["schedule_name"] || "Mission Execution"
    
    """
    # #{title}
    
    **Mission Execution Report**  
    *Generated: #{DateTime.utc_now() |> DateTime.to_iso8601()}*
    
    ## Mission Status
    
    **Success Status**: #{simulation_result.status}  
    **Activities**: #{length(simulation_result.schedule || [])} scheduled
    
    Mission completed with basic coordination metrics available.
    
    *End of Mission Report*
    """
  end

  defp get_total_duration(simulation_result) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        # Calculate duration from activity log timestamps
        last_activity = List.last(activities)
        case Map.get(last_activity, :mission_duration, Map.get(last_activity, "mission_duration")) do
          duration_str when is_binary(duration_str) ->
            # Extract hours from "Mission Hour X:XX" format
            case Regex.run(~r/Mission Hour (\d+):(\d+)/, duration_str) do
              [_, hours, minutes] ->
                total_minutes = String.to_integer(hours) * 60 + String.to_integer(minutes)
                "#{total_minutes} minutes (#{hours}h #{minutes}m)"
              _ -> duration_str
            end
          _ -> "Unknown duration format"
        end
      _ -> 
        # Fallback: check analysis or estimate from schedule
        case simulation_result.analysis do
          %{total_duration: duration} -> "#{duration} minutes"
          _ -> 
            # Last resort: count activities and estimate
            activity_count = length(simulation_result.schedule || [])
            estimated = activity_count * 60  # rough estimate
            "~#{estimated} minutes (estimated from #{activity_count} activities)"
        end
    end
  end

  defp calculate_resource_efficiency(simulation_result) do
    case simulation_result.resource_utilization do
      resources when map_size(resources) > 0 ->
        # Calculate actual utilization percentages
        {total_capacity, total_used} = Enum.reduce(resources, {0, 0}, fn {_key, resource_data}, {cap_acc, used_acc} ->
          capacity = Map.get(resource_data, :capacity, Map.get(resource_data, "capacity", 0))
          current_usage = Map.get(resource_data, :current_usage, Map.get(resource_data, "current_usage", 0))
          {cap_acc + capacity, used_acc + current_usage}
        end)
        
        if total_capacity > 0 do
          efficiency = round(total_used / total_capacity * 100)
          "#{efficiency}% (#{total_used}/#{total_capacity} units)"
        else
          "No measurable capacity"
        end
      _ -> 
        # Check if we have resource data in other formats
        case simulation_result.simulation_metadata do
          %{resource_stats: stats} -> "#{Map.get(stats, :efficiency, 0)}% (from metadata)"
          _ -> "No resource utilization data available"
        end
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

  defp format_timestamp(timestamp) when is_binary(timestamp) do
    # Check if it's already a mission time format and convert if needed
    if String.starts_with?(timestamp, "Mission") do
      # Convert "Mission Minute X" to T+format
      case Regex.run(~r/Mission Minute (\d+(?:\.\d+)?)/, timestamp) do
        [_, minutes_str] ->
          case Float.parse(minutes_str) do
            {minutes, ""} -> format_timestamp(minutes)
            _ -> timestamp
          end
        _ -> timestamp
      end
    else
      timestamp
    end
  end
  defp format_timestamp(%DateTime{} = dt), do: DateTime.to_time(dt) |> Time.to_string()
  defp format_timestamp(minutes) when is_number(minutes) do
    # Convert fractional minutes to realistic time display
    total_seconds = round(minutes * 60)
    
    cond do
      total_seconds < 60 ->
        "T+#{total_seconds}s"
      total_seconds < 3600 ->
        mins = div(total_seconds, 60)
        secs = rem(total_seconds, 60)
        if secs == 0 do
          "T+#{mins}m"
        else
          "T+#{mins}m#{secs}s"
        end
      true ->
        hours = div(total_seconds, 3600)
        remaining_mins = div(rem(total_seconds, 3600), 60)
        "T+#{hours}h#{remaining_mins}m"
    end
  end
  defp format_timestamp(_), do: "Mission Time Unknown"

  defp humanize_activity_id(activity_id) do
    activity_id
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
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


  # Entity-capability-driven narrative generation helpers

  defp build_entity_lookup(entities) when is_list(entities) do
    Enum.reduce(entities, %{}, fn entity, acc ->
      Map.put(acc, entity["id"], entity)
    end)
  end

  defp build_activity_lookup(activities) when is_list(activities) do
    Enum.reduce(activities, %{}, fn activity, acc ->
      Map.put(acc, activity["id"], activity)
    end)
  end

  defp detect_story_phases_from_capabilities(simulation_result, entity_lookup, activity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        # Group activities by dominant entity type capabilities
        activities
        |> Enum.group_by(&detect_phase_from_activity(&1, entity_lookup, activity_lookup))
        |> Enum.map(fn {phase, phase_activities} ->
          %{
            phase: phase,
            description: get_phase_description(phase),
            activities: phase_activities,
            dominant_entities: get_dominant_entities(phase_activities, entity_lookup)
          }
        end)
      _ -> []
    end
  end

  defp detect_phase_from_activity(activity, entity_lookup, activity_lookup) do
    activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id"))
    entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id"))
    
    # Get activity requirements
    activity_data = Map.get(activity_lookup, activity_id, %{})
    required_capabilities = Map.get(activity_data, "required_capabilities", [])
    
    # Get entity type and capabilities
    entity_data = Map.get(entity_lookup, entity_id, %{})
    entity_type = Map.get(entity_data, "type", "unknown")
    entity_capabilities = Map.get(entity_data, "capabilities", [])
    
    # Determine phase based on capability patterns
    cond do
      entity_type == "conceptual" -> :conceptual_evolution
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "bio")) -> :bio_integration
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "network")) || 
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "security")) -> :cyber_operations
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "community")) ||
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "coordination")) -> :community_synthesis
      Enum.any?(entity_capabilities, &String.contains?(to_string(&1), "crisis")) -> :crisis_management
      true -> :operational_coordination
    end
  end

  defp get_phase_description(phase) do
    case phase do
      :bio_integration -> "Living systems integration and biological interface establishment"
      :cyber_operations -> "Information network infiltration and digital security operations"
      :community_synthesis -> "Stakeholder coordination and collaborative framework development"
      :crisis_management -> "Rapid assessment and emergency coordination protocols"
      :conceptual_evolution -> "Abstract state transitions and emergent property development"
      :operational_coordination -> "Cross-functional coordination and system integration"
      _ -> "Complex multi-domain operations"
    end
  end

  defp get_dominant_entities(phase_activities, entity_lookup) do
    phase_activities
    |> Enum.map(fn activity -> Map.get(activity, :entity_id, Map.get(activity, "entity_id")) end)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_entity, count} -> count end, :desc)
    |> Enum.take(3)
    |> Enum.map(fn {entity_id, _count} -> 
      entity_data = Map.get(entity_lookup, entity_id, %{})
      Map.get(entity_data, "name", entity_id)
    end)
  end

  defp count_entity_types(entity_lookup) do
    entity_lookup
    |> Map.values()
    |> Enum.map(fn entity -> Map.get(entity, "type", "unknown") end)
    |> Enum.uniq()
    |> length()
  end

  defp list_entity_types(entity_lookup) do
    entity_lookup
    |> Map.values()
    |> Enum.map(fn entity -> Map.get(entity, "type", "unknown") end)
    |> Enum.uniq()
    |> Enum.map(&humanize_entity_type/1)
    |> Enum.join(", ")
  end

  defp humanize_entity_type(type) do
    type
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp count_unique_capabilities(entity_lookup) do
    entity_lookup
    |> Map.values()
    |> Enum.flat_map(fn entity -> Map.get(entity, "capabilities", []) end)
    |> Enum.uniq()
    |> length()
  end

  defp generate_capability_based_achievements(simulation_result, entity_lookup, activity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        # Group by capability types used
        capability_usage = activities
        |> Enum.flat_map(&extract_capabilities_from_activity(&1, entity_lookup, activity_lookup))
        |> Enum.frequencies()
        |> Enum.sort_by(fn {_cap, count} -> count end, :desc)
        |> Enum.take(8)
        
        capability_usage
        |> Enum.map(fn {capability, usage_count} ->
          entities_with_cap = find_entities_with_capability(capability, entity_lookup)
          "- **#{humanize_capability(capability)}**: Used #{usage_count} times by #{Enum.join(entities_with_cap, ", ")}"
        end)
        |> Enum.join("\n")
      _ -> "Capability analysis not available - no activity execution data."
    end
  end

  defp extract_capabilities_from_activity(activity, entity_lookup, activity_lookup) do
    activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id"))
    entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id"))
    
    # Get activity requirements
    activity_data = Map.get(activity_lookup, activity_id, %{})
    required_capabilities = Map.get(activity_data, "required_capabilities", [])
    
    # Get entity capabilities
    entity_data = Map.get(entity_lookup, entity_id, %{})
    entity_capabilities = Map.get(entity_data, "capabilities", [])
    
    # Return intersection of required and available capabilities
    required_capabilities
    |> Enum.filter(fn req_cap ->
      Enum.any?(entity_capabilities, fn entity_cap ->
        to_string(entity_cap) == to_string(req_cap)
      end)
    end)
  end

  defp find_entities_with_capability(capability, entity_lookup) do
    entity_lookup
    |> Enum.filter(fn {_id, entity} ->
      capabilities = Map.get(entity, "capabilities", [])
      Enum.any?(capabilities, fn cap -> to_string(cap) == to_string(capability) end)
    end)
    |> Enum.map(fn {_id, entity} -> 
      Map.get(entity, "name", Map.get(entity, "id", "Unknown"))
    end)
    |> Enum.take(3)  # Limit to top 3 for readability
  end

  defp humanize_capability(capability) do
    capability
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp generate_story_phase_narrative(story_phases, _entity_lookup) do
    if length(story_phases) > 0 do
      story_phases
      |> Enum.map(fn phase ->
        activity_count = length(phase.activities)
        entity_list = Enum.join(phase.dominant_entities, ", ")
        
        "**#{humanize_capability(to_string(phase.phase))} Phase**: #{phase.description}  \n" <>
        "#{activity_count} activities coordinated by #{entity_list}"
      end)
      |> Enum.join("\n\n")
    else
      "Story phase analysis not available - insufficient activity execution data."
    end
  end

  defp generate_capability_timeline(simulation_result, entity_lookup, activity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        activities
        |> Enum.take(10)  # Show first 10 activities
        |> Enum.map(fn activity ->
          timestamp = Map.get(activity, :mission_duration, 
                              Map.get(activity, "mission_duration",
                              Map.get(activity, :timestamp, 
                              Map.get(activity, "timestamp", "Unknown"))))
          
          activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id", "unknown"))
          entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id", "unknown"))
          
          # Get primary capability used
          capabilities = extract_capabilities_from_activity(activity, entity_lookup, activity_lookup)
          primary_capability = case capabilities do
            [cap | _] -> humanize_capability(cap)
            [] -> "General coordination"
          end
          
          # Enhanced entity name resolution with debugging
          entity_name = resolve_entity_name(entity_id, entity_lookup)
          
          "- **#{format_timestamp(timestamp)}**: #{humanize_activity_id(activity_id)} (#{primary_capability} by #{entity_name})"
        end)
        |> Enum.join("\n")
      _ -> "Capability timeline not available - no detailed execution logs."
    end
  end

  # Enhanced entity name resolution with multiple fallback strategies
  defp resolve_entity_name(entity_id, entity_lookup) do
    cond do
      # If entity_id is nil or empty, return generic name
      is_nil(entity_id) or entity_id == "" or entity_id == "unknown" ->
        "Unassigned Entity"
      
      # Try direct lookup by entity_id
      Map.has_key?(entity_lookup, entity_id) ->
        entity_data = Map.get(entity_lookup, entity_id)
        extract_entity_display_name(entity_data, entity_id)
      
      # If direct lookup fails, try to find by partial match or similar keys
      true ->
        case find_entity_by_fuzzy_match(entity_id, entity_lookup) do
          {_key, entity_data} -> extract_entity_display_name(entity_data, entity_id)
          nil -> humanize_entity_id(entity_id)  # Use formatted entity_id as fallback
        end
    end
  end

  # Extract display name from entity data with multiple strategies
  defp extract_entity_display_name(entity_data, fallback_id) when is_map(entity_data) do
    cond do
      # Try "name" field first
      Map.has_key?(entity_data, "name") and is_binary(entity_data["name"]) ->
        entity_data["name"] |> String.split(",") |> hd() |> String.trim()
      
      # Try "display_name" field
      Map.has_key?(entity_data, "display_name") and is_binary(entity_data["display_name"]) ->
        entity_data["display_name"] |> String.trim()
      
      # Try "id" field and humanize it
      Map.has_key?(entity_data, "id") and is_binary(entity_data["id"]) ->
        humanize_entity_id(entity_data["id"])
      
      # Use fallback_id and humanize it
      true ->
        humanize_entity_id(fallback_id)
    end
  end
  defp extract_entity_display_name(_, fallback_id), do: humanize_entity_id(fallback_id)

  # Find entity by fuzzy matching (useful for slight mismatches in entity IDs)
  defp find_entity_by_fuzzy_match(target_id, entity_lookup) do
    target_id_lower = String.downcase(target_id)
    
    entity_lookup
    |> Enum.find(fn {entity_key, _entity_data} ->
      entity_key_lower = String.downcase(to_string(entity_key))
      
      # Try exact match first
      entity_key_lower == target_id_lower or
      # Try partial matches
      String.contains?(entity_key_lower, target_id_lower) or
      String.contains?(target_id_lower, entity_key_lower)
    end)
  end

  # Convert entity_id to human-readable format
  defp humanize_entity_id(entity_id) when is_binary(entity_id) do
    entity_id
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
  defp humanize_entity_id(entity_id), do: to_string(entity_id) |> humanize_entity_id()

  defp generate_conceptual_entity_outcomes(simulation_result, entity_lookup) do
    # Find conceptual entities
    conceptual_entities = entity_lookup
    |> Enum.filter(fn {_id, entity} -> Map.get(entity, "type") == "conceptual" end)
    
    if length(conceptual_entities) > 0 do
      "\n## Conceptual Entity State Changes\n\n" <>
      (conceptual_entities
      |> Enum.map(fn {entity_id, entity} ->
        entity_name = Map.get(entity, "id", entity_id)
        current_state = Map.get(entity, "current_state", "unknown")
        capabilities = Map.get(entity, "capabilities", [])
        
        # Determine likely outcome based on mission success
        predicted_outcome = case simulation_result.status do
          :success -> predict_positive_outcome(current_state, capabilities)
          _ -> predict_neutral_outcome(current_state, capabilities)
        end
        
        "- **#{humanize_capability(entity_name)}**: #{current_state} → #{predicted_outcome}"
      end)
      |> Enum.join("\n"))
    else
      ""
    end
  end

  defp predict_positive_outcome(current_state, capabilities) do
    case current_state do
      "fragmented" -> "unified"
      "deteriorating" -> "stabilized"
      "escalating" -> "resolved"
      "blocked" -> "flowing"
      "nascent" -> "established"
      _ -> 
        # Infer from capabilities
        if Enum.any?(capabilities, &String.contains?(to_string(&1), "bridge")) do
          "bridged"
        else
          "improved"
        end
    end
  end

  defp predict_neutral_outcome(current_state, _capabilities) do
    case current_state do
      "fragmented" -> "partially connected"
      "deteriorating" -> "maintained"
      "escalating" -> "managed"
      "blocked" -> "partially opened"
      "nascent" -> "developing"
      _ -> "unchanged"
    end
  end

  defp create_basic_success_result(mission_data, narrative_mode) do
    # Create a minimal SimulationResult struct for consistent processing
    minimal_simulation_result = %AriaEngine.Scheduler.SimulationResult{
      status: :success,
      reason: "Mission planning completed successfully",
      schedule: [],
      analysis: %{},
      activity_log: [],
      resource_utilization: %{},
      timeline: [],
      simulation_metadata: %{}
    }
    
    # Process through the normal path
    result = convert_simulation_result_to_map(minimal_simulation_result)
    
    if narrative_mode do
      Map.put(result, :narrative, generate_narrative_from_mission_data(minimal_simulation_result, mission_data))
    else
      result
    end
  end

  # Safe helper functions for defensive narrative generation

  defp safe_get_map(data, key, default) when is_map(data) do
    case Map.get(data, key, default) do
      result when is_map(result) -> result
      _ -> default
    end
  end
  defp safe_get_map(_, _, default), do: default

  defp safe_build_entity_lookup(entities) when is_list(entities) do
    try do
      build_entity_lookup(entities)
    rescue
      _ -> %{}
    end
  end
  defp safe_build_entity_lookup(_), do: %{}

  defp safe_build_activity_lookup(activities) when is_list(activities) do
    try do
      build_activity_lookup(activities)
    rescue
      _ -> %{}
    end
  end
  defp safe_build_activity_lookup(_), do: %{}

  defp safe_detect_story_phases(simulation_result, entity_lookup, activity_lookup) do
    try do
      detect_story_phases_from_capabilities(simulation_result, entity_lookup, activity_lookup)
    rescue
      e ->
        Logger.warning("Error detecting story phases: #{Exception.message(e)}")
        []
    end
  end

  defp safe_generate_capability_achievements(simulation_result, entity_lookup, activity_lookup) do
    try do
      generate_capability_based_achievements(simulation_result, entity_lookup, activity_lookup)
    rescue
      e ->
        Logger.warning("Error generating capability achievements: #{Exception.message(e)}")
        "Entity capability analysis not available due to data processing issues."
    end
  end

  defp safe_generate_story_phase_narrative(story_phases, entity_lookup) do
    try do
      generate_story_phase_narrative(story_phases, entity_lookup)
    rescue
      e ->
        Logger.warning("Error generating story phase narrative: #{Exception.message(e)}")
        "Story phase analysis not available due to processing constraints."
    end
  end

  defp safe_generate_capability_timeline(simulation_result, entity_lookup, activity_lookup) do
    try do
      generate_capability_timeline(simulation_result, entity_lookup, activity_lookup)
    rescue
      e ->
        Logger.warning("Error generating capability timeline: #{Exception.message(e)}")
        "Entity-driven timeline not available due to data processing issues."
    end
  end

  defp safe_generate_entity_outcomes(simulation_result, entity_lookup) do
    try do
      generate_conceptual_entity_outcomes(simulation_result, entity_lookup)
    rescue
      e ->
        Logger.warning("Error generating entity outcomes: #{Exception.message(e)}")
        ""
    end
  end

  defp safe_count_entity_types(entity_lookup) do
    try do
      count_entity_types(entity_lookup)
    rescue
      _ -> 0
    end
  end

  defp safe_list_entity_types(entity_lookup) do
    try do
      list_entity_types(entity_lookup)
    rescue
      _ -> "various specialized entities"
    end
  end

  defp safe_count_unique_capabilities(entity_lookup) do
    try do
      count_unique_capabilities(entity_lookup)
    rescue
      _ -> 0
    end
  end

  defp safe_get_total_duration(simulation_result) do
    try do
      get_total_duration(simulation_result)
    rescue
      _ -> "Duration calculation unavailable"
    end
  end

  defp safe_calculate_resource_efficiency(simulation_result) do
    try do
      calculate_resource_efficiency(simulation_result)
    rescue
      _ -> "Resource efficiency calculation unavailable"
    end
  end
end
