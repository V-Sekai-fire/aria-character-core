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
                  anyOf: [
                    %{
                      type: "string",
                      format: "duration",
                      description: "The activity's duration in ISO 8601 format (e.g., 'PT2H30M', 'PT90S')."
                    },
                    %{
                      type: "object",
                      properties: %{
                        start: %{
                          type: "string",
                          format: "date-time",
                          pattern: "Z|[+-][0-9]{2}:[0-9]{2}$",
                          description: "Start time in ISO 8601 format with timezone."
                        },
                        end: %{
                          type: "string",
                          format: "date-time",
                          pattern: "Z|[+-][0-9]{2}:[0-9]{2}$",
                          description: "End time in ISO 8601 format with timezone."
                        }
                      },
                      minProperties: 1,
                      description: "A time window for the activity. At least one of start or end must be present. Both are ISO 8601 datetime strings with mandatory timezone."
                    }
                  ],
                  description: "The duration of the activity, specified as an ISO 8601 duration string or a fixed/open interval (ISO 8601 datetimes with timezone)."
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
  
  This function now acts as a pure plan converter that transforms MCP input
  to HybridCoordinatorV2 format without executing the planning.
  """
  def handle_schedule_activities_tool_call(params) do
    try do
      # Use plan transformer to convert MCP input to planning parameters
      case AriaEngine.HybridPlanner.PlanTransformer.convert_to_planning_params(params) do
        {:ok, {domain, state, goals}} ->
          # Return the converted planning parameters in MCP format
          %{
            status: "success",
            reason: "MCP input successfully converted to planning format",
            coordinator_input: %{
              domain: domain,
              state: state,
              goals: goals
            },
            conversion_metadata: %{
              original_activities: length(Map.get(params, "activities", [])),
              converted_at: DateTime.utc_now() |> DateTime.to_iso8601(),
              input_format: "mcp_schedule_activities",
              output_format: "hybrid_coordinator_v2"
            },
            schedule: [],
            analysis: %{},
            resource_utilization: %{},
            timeline: [],
            simulation_metadata: %{}
          }
          
        {:error, reason} ->
          format_mcp_error(reason)
      end
    rescue
      e ->
        Logger.error("MCPTools error: #{Exception.message(e)}")
        format_mcp_error("Internal error: #{Exception.message(e)}")
    end
  end

  # Private helper functions for MCP format conversion
  
  # Convert plan result to MCP format using the format converter
  defp convert_plan_to_mcp_format(plan) do
    AriaEngine.MCP.FormatConverter.convert_plan_to_mcp_format(plan)
  end

  # Format error response in MCP format using the format converter
  defp format_mcp_error(reason) do
    AriaEngine.MCP.FormatConverter.format_mcp_error(reason)
  end
end
