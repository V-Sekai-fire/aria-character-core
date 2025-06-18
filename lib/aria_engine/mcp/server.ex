# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.Server do
  @moduledoc """
  Aria Engine MCP Server using GenServer for direct control.
  
  Provides temporal scheduling and planning capabilities through the Model Context Protocol.
  Integrates with the hybrid temporal planner to provide sophisticated scheduling solutions.
  """
  
  use GenServer
  require Logger
  
  defstruct [:tools, :capabilities]
  
  ## Public API
  
  @doc """
  Start the MCP server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end
  
  @doc """
  Execute a tool by name with given arguments.
  """
  def execute_tool(server_pid, tool_name, arguments) do
    GenServer.call(server_pid, {:execute_tool, tool_name, arguments})
  end
  
  ## GenServer Callbacks
  
  @impl true
  def init(_opts) do
    state = %__MODULE__{
      tools: %{
        "schedule_activities" => AriaEngine.MCP.Tools.ScheduleActivities
      },
      capabilities: %{
        tools: %{}
      }
    }
    
    Logger.info("Aria Engine MCP Server started")
    {:ok, state}
  end
  
  @impl true
  def handle_call({:execute_tool, tool_name, arguments}, _from, state) do
    case Map.get(state.tools, tool_name) do
      nil ->
        {:reply, {:error, "Unknown tool: #{tool_name}"}, state}
      
      tool_module ->
        # Create a mock frame for the tool execution
        frame = %{}
        
        case tool_module.execute(arguments, frame) do
          {:ok, result, _frame} -> 
            {:reply, {:ok, result}, state}
          {:error, reason} -> 
            {:reply, {:error, reason}, state}
          {:reply, %Hermes.Server.Response{content: content}, _frame} ->
            # Handle Hermes response format - extract JSON from text content
            case content do
              [%{"text" => json_text, "type" => "text"}] ->
                case Jason.decode(json_text) do
                  {:ok, parsed_result} -> {:reply, {:ok, parsed_result}, state}
                  {:error, _} -> {:reply, {:error, "Invalid JSON response"}, state}
                end
              _ ->
                {:reply, {:error, "Unexpected response format"}, state}
            end
          result when is_map(result) ->
            # Handle direct result return
            {:reply, {:ok, result}, state}
        end
    end
  end
  
  @impl true
  def handle_call(:get_capabilities, _from, state) do
    {:reply, state.capabilities, state}
  end
  
  @impl true
  def handle_call(:get_tools, _from, state) do
    tools = [
      %{
        name: "schedule_activities",
        description: "Create temporal schedule using Critical Path Method with comprehensive hybrid planning",
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
                  }
                },
                required: ["id", "duration"]
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
    
    {:reply, tools, state}
  end
end
