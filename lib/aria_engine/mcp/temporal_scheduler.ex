# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.TemporalScheduler do
  @moduledoc """
  MCP server for temporal scheduling using Critical Path Method (CPM).
  
  Handles scheduling of activities with:
  - Temporal constraints and dependencies
  - Resource allocation and conflicts
  - State fluents that change over time
  - Critical path analysis and optimization
  
  Suitable for any domain requiring temporal planning with resource constraints.
  Currently returns "impossible" for all scheduling requests while the
  Critical Path Method solver is under development.
  """
  
  use GenServer
  require Logger
  
  @type activity :: %{
    id: String.t(),
    name: String.t(),
    duration: float(),
    dependencies: [String.t()],
    resources: [String.t()],
    fluents: map()
  }
  
  @type schedule_request :: %{
    schedule_name: String.t(),
    activities: [activity()],
    resources: map(),
    constraints: map()
  }
  
  @type schedule_response :: %{
    status: String.t(),
    reason: String.t(),
    schedule: [map()],
    analysis: map()
  }

  # MCP Server State
  defstruct [:name, :version, :capabilities]

  ## Public API

  @doc """
  Start the TemporalScheduler MCP server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Handle MCP tool call for schedule_activities.
  """
  def handle_tool_call("schedule_activities", params) do
    GenServer.call(__MODULE__, {:schedule_activities, params})
  end

  @doc """
  Get MCP server capabilities and tool definitions.
  """
  def get_capabilities do
    GenServer.call(__MODULE__, :get_capabilities)
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      name: "TemporalScheduler",
      version: "1.0.0",
      capabilities: %{
        tools: [
          %{
            name: "schedule_activities",
            description: "Create temporal schedule using Critical Path Method with resource and constraint analysis",
            parameters: %{
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
                      id: %{type: "string", description: "Unique activity identifier"},
                      name: %{type: "string", description: "Human-readable activity name"},
                      duration: %{type: "number", description: "Activity duration in time units"},
                      dependencies: %{
                        type: "array",
                        description: "List of activity IDs that must complete before this activity",
                        items: %{type: "string"}
                      },
                      resources: %{
                        type: "array", 
                        description: "List of required resources",
                        items: %{type: "string"}
                      },
                      fluents: %{
                        type: "object",
                        description: "State changes caused by this activity"
                      }
                    },
                    required: ["id", "name", "duration"]
                  }
                },
                resources: %{
                  type: "object",
                  description: "Available resources and their constraints"
                },
                constraints: %{
                  type: "object", 
                  description: "Scheduling constraints and limits"
                }
              },
              required: ["schedule_name", "activities"]
            }
          }
        ]
      }
    }
    
    Logger.info("TemporalScheduler MCP server started")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_capabilities, _from, state) do
    {:reply, state.capabilities, state}
  end

  @impl true
  def handle_call({:schedule_activities, params}, _from, state) do
    response = process_schedule_request(params)
    {:reply, response, state}
  end

  ## Private Functions

  @spec process_schedule_request(map()) :: schedule_response()
  defp process_schedule_request(params) do
    case validate_schedule_request(params) do
      {:ok, request} ->
        analysis = analyze_schedule_structure(request)
        create_impossible_response(request, analysis)
      
      {:error, reason} ->
        %{
          status: "error",
          reason: "Invalid schedule request: #{reason}",
          schedule: [],
          analysis: %{}
        }
    end
  end

  @spec validate_schedule_request(map()) :: {:ok, schedule_request()} | {:error, String.t()}
  defp validate_schedule_request(params) do
    with {:ok, schedule_name} <- get_required_field(params, "schedule_name"),
         {:ok, activities} <- get_required_field(params, "activities"),
         {:ok, validated_activities} <- validate_activities(activities) do
      
      request = %{
        schedule_name: schedule_name,
        activities: validated_activities,
        resources: Map.get(params, "resources", %{}),
        constraints: Map.get(params, "constraints", %{})
      }
      
      {:ok, request}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_required_field(params, field) do
    case Map.get(params, field) do
      nil -> {:error, "Missing required field: #{field}"}
      value -> {:ok, value}
    end
  end

  defp validate_activities(activities) when is_list(activities) do
    validated = Enum.map(activities, &validate_activity/1)
    
    case Enum.find(validated, fn
      {:error, _} -> true
      _ -> false
    end) do
      nil -> {:ok, Enum.map(validated, fn {:ok, activity} -> activity end)}
      {:error, reason} -> {:error, reason}
    end
  end
  defp validate_activities(_), do: {:error, "Activities must be a list"}

  defp validate_activity(activity) when is_map(activity) do
    with {:ok, id} <- get_required_field(activity, "id"),
         {:ok, name} <- get_required_field(activity, "name"),
         {:ok, duration} <- get_required_field(activity, "duration") do
      
      validated_activity = %{
        id: id,
        name: name,
        duration: duration,
        dependencies: Map.get(activity, "dependencies", []),
        resources: Map.get(activity, "resources", []),
        fluents: Map.get(activity, "fluents", %{})
      }
      
      {:ok, validated_activity}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  defp validate_activity(_), do: {:error, "Activity must be a map"}

  @spec analyze_schedule_structure(schedule_request()) :: map()
  defp analyze_schedule_structure(request) do
    activities = request.activities
    
    %{
      method: "Critical Path Method (CPM)",
      activities_analyzed: length(activities),
      dependencies_found: count_dependencies(activities),
      resource_conflicts: detect_resource_conflicts(activities, request.resources),
      circular_dependencies: detect_circular_dependencies(activities),
      critical_path_length: 0,
      issues: generate_analysis_issues(request),
      suggestions: generate_suggestions(request)
    }
  end

  defp count_dependencies(activities) do
    activities
    |> Enum.map(& &1.dependencies)
    |> List.flatten()
    |> length()
  end

  defp detect_resource_conflicts(activities, resources) do
    # Simple resource conflict detection
    resource_usage = 
      activities
      |> Enum.flat_map(& &1.resources)
      |> Enum.frequencies()
    
    available_resources = Map.keys(resources)
    
    resource_usage
    |> Enum.count(fn {resource, usage_count} ->
      resource_limit = get_in(resources, [resource, "capacity"]) || 1
      usage_count > resource_limit or resource not in available_resources
    end)
  end

  defp detect_circular_dependencies(activities) do
    # Simple circular dependency detection
    # In a real implementation, this would use graph algorithms
    activity_ids = MapSet.new(activities, & &1.id)
    
    invalid_deps = 
      activities
      |> Enum.flat_map(& &1.dependencies)
      |> Enum.reject(&(&1 in activity_ids))
      |> length()
    
    if invalid_deps > 0, do: 1, else: 0
  end

  defp generate_analysis_issues(request) do
    issues = ["Critical Path Method solver not yet implemented"]
    
    issues = if detect_resource_conflicts(request.activities, request.resources) > 0 do
      ["Resource allocation conflicts detected" | issues]
    else
      issues
    end
    
    issues = if detect_circular_dependencies(request.activities) > 0 do
      ["Invalid activity dependencies found" | issues]
    else
      issues
    end
    
    issues
  end

  defp generate_suggestions(request) do
    suggestions = []
    
    suggestions = if detect_resource_conflicts(request.activities, request.resources) > 0 do
      ["Review resource capacity and allocation" | suggestions]
    else
      suggestions
    end
    
    suggestions = if detect_circular_dependencies(request.activities) > 0 do
      ["Verify all activity dependencies reference valid activity IDs" | suggestions]
    else
      suggestions
    end
    
    suggestions = if length(request.activities) > 20 do
      ["Consider breaking large schedules into smaller phases" | suggestions]
    else
      suggestions
    end
    
    if length(suggestions) == 0 do
      ["Schedule structure appears valid - awaiting CPM solver implementation"]
    else
      suggestions
    end
  end

  @spec create_impossible_response(schedule_request(), map()) :: schedule_response()
  defp create_impossible_response(request, analysis) do
    %{
      status: "impossible",
      reason: "No feasible schedule found using Critical Path Method analysis",
      schedule: [],
      analysis: Map.put(analysis, :schedule_name, request.schedule_name)
    }
  end

  ## MCP Protocol Functions

  @doc """
  Start MCP server in stdio mode for external MCP clients.
  """
  def start_mcp_stdio do
    spawn(fn -> mcp_stdio_loop() end)
  end

  defp mcp_stdio_loop do
    case IO.gets("") do
      :eof -> 
        :ok
      line ->
        case Jason.decode(String.trim(line)) do
          {:ok, request} ->
            response = handle_mcp_request(request)
            IO.puts(Jason.encode!(response))
          {:error, _} ->
            error_response = %{
              jsonrpc: "2.0",
              error: %{code: -32700, message: "Parse error"},
              id: nil
            }
            IO.puts(Jason.encode!(error_response))
        end
        mcp_stdio_loop()
    end
  end

  defp handle_mcp_request(%{"method" => "initialize"} = request) do
    %{
      jsonrpc: "2.0",
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: get_capabilities(),
        serverInfo: %{
          name: "TemporalScheduler",
          version: "1.0.0"
        }
      },
      id: Map.get(request, "id")
    }
  end

  defp handle_mcp_request(%{"method" => "tools/call", "params" => params} = request) do
    tool_name = Map.get(params, "name")
    tool_params = Map.get(params, "arguments", %{})
    
    result = case tool_name do
      "schedule_activities" ->
        handle_tool_call("schedule_activities", tool_params)
      _ ->
        %{error: "Unknown tool: #{tool_name}"}
    end
    
    %{
      jsonrpc: "2.0",
      result: %{content: [%{type: "text", text: Jason.encode!(result)}]},
      id: Map.get(request, "id")
    }
  end

  defp handle_mcp_request(%{"method" => "tools/list"} = request) do
    capabilities = get_capabilities()
    
    %{
      jsonrpc: "2.0",
      result: %{tools: capabilities.tools},
      id: Map.get(request, "id")
    }
  end

  defp handle_mcp_request(request) do
    %{
      jsonrpc: "2.0",
      error: %{code: -32601, message: "Method not found"},
      id: Map.get(request, "id")
    }
  end
end
