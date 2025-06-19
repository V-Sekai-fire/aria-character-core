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
        case :iso8601.parse_duration(duration_str) do
          duration_proplist when is_list(duration_proplist) -> {:ok, duration_str}
          _ -> {:error, "Invalid ISO 8601 duration string: #{duration_str}"}
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
          %{
            timestamp: safe_datetime_to_iso8601(log_entry.timestamp),
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

  # Safe DateTime to ISO8601 conversion with proper Erlang syntax
  defp safe_datetime_to_iso8601(timestamp) do
    case timestamp do
      %DateTime{} = dt ->
        DateTime.to_iso8601(dt)
      
      {{year, month, day}, {hour, minute, second}} ->
        # Erlang datetime tuple format - convert to ISO8601 using the iso8601 library
        :iso8601.format({{year, month, day}, {hour, minute, second}})
      
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
        case :iso8601.parse_duration(duration_str) do
          duration_proplist when is_list(duration_proplist) ->
            convert_duration_to_minutes(duration_proplist)
          _ -> nil
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
    
    """
    # Cross-Spectrum Protocol: The Merged Realms
    
    **Mission Execution Report**  
    *Generated: #{timestamp}*
    
    ## Mission Overview
    
    The displaced protagonist has successfully navigated the complex tri-zone integration protocol across the Verdant bio-tech district, Chrome corporate underworld, and Harmony synthesis hub. This represents a significant breakthrough in cross-dimensional stability and inter-district cooperation.
    
    ## Key Achievements
    
    - **Consciousness Stabilization**: Successfully anchored dimensional awareness
    - **Tri-Zone Authentication**: Gained trust across all three distinct sectors
    - **Resource Synthesis**: Coordinated bio-energy, underground currency, and community credits
    - **Reality Stabilization**: Achieved dimensional portal manifestation
    
    ## Technical Results
    
    **Total Activities Scheduled**: #{length(simulation_result.schedule || [])}  
    **Mission Duration**: #{get_total_duration(simulation_result)}  
    **Resource Efficiency**: #{calculate_resource_efficiency(simulation_result)}  
    **Success Status**: #{simulation_result.status}
    
    ## Narrative Timeline
    
    #{generate_activity_timeline(simulation_result)}
    
    ## Mission Completion
    
    The Cross-Spectrum Protocol has achieved its primary objectives: establishing sustainable communication channels between the three districts, synthesizing resource management protocols, and creating a stable portal for dimensional return. The protagonist's modern knowledge and adaptive capabilities proved essential in bridging the technological, biological, and social systems of this merged reality.
    
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

  # Template data definitions
  defp get_tri_zone_activities() do
    [
      %{
        "id" => "consciousness_stabilization",
        "duration" => "PT2H",
        "dependencies" => [],
        "required_capabilities" => ["adaptation", "modern_knowledge"],
        "required_resources" => ["reality_anchors"]
      },
      %{
        "id" => "verdant_sector_entry",
        "duration" => "PT45M",
        "dependencies" => ["consciousness_stabilization"],
        "required_capabilities" => ["pattern_recognition"],
        "required_resources" => ["bio_energy"]
      },
      %{
        "id" => "symbiotic_interface_discovery",
        "duration" => "PT3H",
        "dependencies" => ["verdant_sector_entry"],
        "required_capabilities" => ["adaptation", "bio_integration"],
        "required_resources" => ["bio_energy", "collective_knowledge"]
      },
      %{
        "id" => "plant_network_authentication",
        "duration" => "PT90M",
        "dependencies" => ["symbiotic_interface_discovery"],
        "required_capabilities" => ["bio_integration", "trust_building"],
        "required_resources" => ["collective_knowledge"]
      },
      %{
        "id" => "ecosystem_crisis_detection",
        "duration" => "PT2H",
        "dependencies" => ["plant_network_authentication"],
        "required_capabilities" => ["pattern_recognition", "crisis_analysis"],
        "required_resources" => ["bio_energy", "sensor_network"]
      },
      %{
        "id" => "chrome_underworld_infiltration",
        "duration" => "PT4H",
        "dependencies" => ["ecosystem_crisis_detection"],
        "required_capabilities" => ["stealth", "data_analysis"],
        "required_resources" => ["stolen_access_codes"]
      },
      %{
        "id" => "corporate_firewall_breach",
        "duration" => "PT6H",
        "dependencies" => ["chrome_underworld_infiltration"],
        "required_capabilities" => ["hacking", "modern_knowledge"],
        "required_resources" => ["stolen_access_codes", "illegal_augments"]
      },
      %{
        "id" => "data_core_extraction",
        "duration" => "PT3H",
        "dependencies" => ["corporate_firewall_breach"],
        "required_capabilities" => ["data_analysis", "stealth"],
        "required_resources" => ["storage_devices", "illegal_augments"]
      },
      %{
        "id" => "netrunner_alliance_formation",
        "duration" => "PT5H",
        "dependencies" => ["data_core_extraction"],
        "required_capabilities" => ["trust_building", "negotiation"],
        "required_resources" => ["underground_currency"]
      },
      %{
        "id" => "harmony_hub_coordination",
        "duration" => "PT4H",
        "dependencies" => ["netrunner_alliance_formation"],
        "required_capabilities" => ["collaboration", "system_integration"],
        "required_resources" => ["public_fabricators", "community_credits"]
      },
      %{
        "id" => "tri_zone_protocol_synthesis",
        "duration" => "PT8H",
        "dependencies" => ["harmony_hub_coordination", "plant_network_authentication"],
        "required_capabilities" => ["synthesis", "leadership", "modern_knowledge"],
        "required_resources" => ["bio_energy", "community_credits", "collective_knowledge"]
      },
      %{
        "id" => "cross_district_communication",
        "duration" => "PT2H",
        "dependencies" => ["tri_zone_protocol_synthesis"],
        "required_capabilities" => ["communication", "translation"],
        "required_resources" => ["mesh_network", "translation_matrices"]
      },
      %{
        "id" => "reality_stabilization_ritual",
        "duration" => "PT12H",
        "dependencies" => ["cross_district_communication"],
        "required_capabilities" => ["synthesis", "reality_manipulation", "leadership"],
        "required_resources" => ["reality_anchors", "bio_energy", "community_credits"]
      },
      %{
        "id" => "portal_manifestation",
        "duration" => "PT30M",
        "dependencies" => ["reality_stabilization_ritual"],
        "required_capabilities" => ["reality_manipulation", "modern_knowledge"],
        "required_resources" => ["reality_anchors", "translation_matrices"]
      },
      %{
        "id" => "dimensional_return_sequence",
        "duration" => "PT15M",
        "dependencies" => ["portal_manifestation"],
        "required_capabilities" => ["dimensional_travel"],
        "required_resources" => ["reality_anchors"]
      }
    ]
  end

  defp get_tri_zone_entities() do
    [
      %{
        "id" => "displaced_protagonist",
        "type" => "isekai_hero",
        "capabilities" => ["modern_knowledge", "adaptation", "pattern_recognition", "leadership", "dimensional_travel"],
        "availability" => %{}
      },
      %{
        "id" => "verdant_ecosystem_ai",
        "type" => "bio_intelligence",
        "capabilities" => ["bio_integration", "collective_consciousness", "ecosystem_management", "symbiotic_interface"],
        "availability" => %{}
      },
      %{
        "id" => "chrome_netrunner_collective",
        "type" => "hacker_group",
        "capabilities" => ["hacking", "data_analysis", "stealth", "underground_networks"],
        "availability" => %{}
      },
      %{
        "id" => "harmony_coordination_ai",
        "type" => "collaborative_system",
        "capabilities" => ["collaboration", "system_integration", "resource_optimization", "community_building"],
        "availability" => %{}
      },
      %{
        "id" => "tri_zone_mediator",
        "type" => "bridge_entity",
        "capabilities" => ["synthesis", "translation", "conflict_resolution", "reality_manipulation"],
        "availability" => %{}
      },
      %{
        "id" => "crisis_response_collective",
        "type" => "emergency_system",
        "capabilities" => ["crisis_analysis", "coordination", "resource_mobilization", "rapid_response"],
        "availability" => %{}
      },
      %{
        "id" => "street_contact_network",
        "type" => "information_broker",
        "capabilities" => ["information_gathering", "trust_building", "negotiation", "black_market_access"],
        "availability" => %{}
      },
      %{
        "id" => "community_volunteer_grid",
        "type" => "citizen_collective",
        "capabilities" => ["community_support", "resource_sharing", "communication", "mutual_aid"],
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
