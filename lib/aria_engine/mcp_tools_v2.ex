# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPToolsV2 do
  @moduledoc """
  MCP tools interface with Membrane Framework pipeline integration.

  Provides MCP tools for pipeline management and individual strategy testing.
  This is the updated version that uses the Membrane pipeline architecture
  instead of direct scheduler calls.
  """

  require Logger
  
  alias AriaEngine.MCPToolsV2.PipelineManagement
  alias AriaEngine.MCPToolsV2.SchedulingHandlers
  alias AriaEngine.MCPToolsV2.ValidationHandlers
  alias AriaEngine.MCPToolsV2.SchemaDefinitions

  @type tool_result :: map()

  @tools [
    {:configure_pipeline_layout, "2.0.0"},
    {:setup_element_config, "2.0.0"},
    {:start_planning_pipeline, "2.0.0"},
    {:stop_planning_pipeline, "2.0.0"},
    {:get_pipeline_status, "2.0.0"},
    {:get_pipeline_metrics, "2.0.0"},
    # Updated to use pipeline
    {:schedule_activities, "2.0.0"},
    # New validation pipeline
    {:validate_scheduling_solutions, "2.0.0"},
    {:list_active_pipelines, "2.0.0"},
    {:send_pipeline_request, "2.0.0"}
  ]

  @doc """
  Get list of available MCP tools with their descriptions and schemas.
  """
  @spec get_tools() :: [map()]
  def get_tools() do
    Enum.map(@tools, fn {name, version} ->
      %{
        "name" => Atom.to_string(name),
        "version" => version,
        "description" => get_tool_description(name),
        "inputSchema" => get_input_schema(name)
      }
    end)
  end

  @doc """
  Handle MCP tool call with error handling and logging.
  """
  @spec handle_tool_call(atom() | String.t(), map()) :: tool_result()
  def handle_tool_call(tool_name, params) when is_atom(tool_name) do
    Logger.info("MCP tool call: #{tool_name} with params: #{inspect(params)}")

    try do
      execute_tool_handler(tool_name, params)
    rescue
      error ->
        handle_tool_execution_error(tool_name, params, error)
    end
  end

  def handle_tool_call(tool_name, params) when is_binary(tool_name) do
    handle_tool_call(String.to_atom(tool_name), params)
  end

  @doc """
  Public function interface for direct scheduling calls.
  """
  @spec schedule_activities(map()) :: tool_result()
  def schedule_activities(params) do
    SchedulingHandlers.handle_schedule_activities(params)
  end

  @doc """
  Public function interface for direct validation calls.
  """
  @spec validate_scheduling_solutions(map()) :: tool_result()
  def validate_scheduling_solutions(params) do
    ValidationHandlers.handle_validate_scheduling_solutions(params)
  end

  @doc """
  Generate a new validation problem for testing scaling behavior.
  Creates problems with 1-6 activities with proper dependency chains.
  """
  @spec generate_new_validation_problem(String.t()) :: map()
  def generate_new_validation_problem(problem_name) do
    # Random activity count between 1 and 6
    activity_count = Enum.random(1..6)
    
    # Generate unique problem ID
    problem_id = :rand.uniform(1_000_000)
    timestamp = DateTime.utc_now()
    
    # Create unique problem name with timestamp
    unique_name = "#{problem_name}_#{activity_count}act_#{problem_id}"
    
    # Generate activities based on count
    activities = generate_activities(activity_count)
    
    # Generate entities (max 3)
    entities = generate_entities(min(activity_count, 3))
    
    # Generate resources
    resources = generate_resources(activity_count)
    
    # Generate constraints
    constraints = generate_constraints(activity_count)
    
    # Determine complexity
    complexity = case activity_count do
      1 -> "trivial"
      2 -> "simple"
      3 -> "medium"
      4 -> "medium"
      5 -> "high"
      6 -> "high"
    end
    
    %{
      name: unique_name,
      activities: activities,
      entities: entities,
      resources: resources,
      constraints: constraints,
      metadata: %{
        complexity: complexity,
        problem_type: "scaling_task_chain",
        activity_count: activity_count,
        generated_at: timestamp,
        problem_id: problem_id,
        scaling_factor: activity_count
      }
    }
  end

  # Tool execution dispatcher

  @spec execute_tool_handler(atom(), map()) :: tool_result()
  defp execute_tool_handler(tool_name, params) do
    case tool_name do
      # Pipeline management tools
      :configure_pipeline_layout -> PipelineManagement.handle_configure_pipeline_layout(params)
      :setup_element_config -> PipelineManagement.handle_setup_element_config(params)
      :start_planning_pipeline -> PipelineManagement.handle_start_planning_pipeline(params)
      :stop_planning_pipeline -> PipelineManagement.handle_stop_planning_pipeline(params)
      :get_pipeline_status -> PipelineManagement.handle_get_pipeline_status(params)
      :get_pipeline_metrics -> PipelineManagement.handle_get_pipeline_metrics(params)
      :list_active_pipelines -> PipelineManagement.handle_list_active_pipelines(params)
      :send_pipeline_request -> PipelineManagement.handle_send_pipeline_request(params)
      
      # Scheduling tools
      :schedule_activities -> SchedulingHandlers.handle_schedule_activities(params)
      
      # Validation tools
      :validate_scheduling_solutions -> ValidationHandlers.handle_validate_scheduling_solutions(params)
      
      _ -> %{"error" => "Unknown tool: #{tool_name}"}
    end
  end

  @spec handle_tool_execution_error(atom(), map(), Exception.t()) :: tool_result()
  defp handle_tool_execution_error(tool_name, params, error) do
    Logger.error("Error in MCP tool #{tool_name}: #{inspect(error)}")

    %{
      "error" => "Tool execution failed: #{Exception.message(error)}",
      "details" => %{
        "tool" => Atom.to_string(tool_name),
        "params" => params
      }
    }
  end

  # Tool descriptions

  @spec get_tool_description(atom()) :: String.t()
  defp get_tool_description(:configure_pipeline_layout) do
    "Configure and create a new Membrane pipeline with specified topology and elements"
  end

  defp get_tool_description(:setup_element_config) do
    "Validate and setup configuration for pipeline elements"
  end

  defp get_tool_description(:start_planning_pipeline) do
    "Start a new planning pipeline with predefined topology"
  end

  defp get_tool_description(:stop_planning_pipeline) do
    "Stop an active planning pipeline"
  end

  defp get_tool_description(:get_pipeline_status) do
    "Get detailed status information for a specific pipeline"
  end

  defp get_tool_description(:get_pipeline_metrics) do
    "Get overall metrics for the pipeline manager"
  end

  defp get_tool_description(:schedule_activities) do
    "Schedule activities using Membrane pipeline architecture with multiple strategy options"
  end

  defp get_tool_description(:validate_scheduling_solutions) do
    "Validate scheduling solutions by comparing Hybrid solver with MiniZinc constraint solver"
  end

  defp get_tool_description(:list_active_pipelines) do
    "List all currently active pipelines"
  end

  defp get_tool_description(:send_pipeline_request) do
    "Send a request to a specific active pipeline"
  end

  # Input schema delegation

  @spec get_input_schema(atom()) :: map()
  def get_input_schema(:configure_pipeline_layout) do
    SchemaDefinitions.get_configure_pipeline_layout_schema()
  end

  def get_input_schema(:setup_element_config) do
    SchemaDefinitions.get_setup_element_config_schema()
  end

  def get_input_schema(:start_planning_pipeline) do
    SchemaDefinitions.get_start_planning_pipeline_schema()
  end

  def get_input_schema(:stop_planning_pipeline) do
    SchemaDefinitions.get_stop_planning_pipeline_schema()
  end

  def get_input_schema(:get_pipeline_status) do
    SchemaDefinitions.get_get_pipeline_status_schema()
  end

  def get_input_schema(:get_pipeline_metrics) do
    SchemaDefinitions.get_get_pipeline_metrics_schema()
  end

  def get_input_schema(:schedule_activities) do
    SchemaDefinitions.get_schedule_activities_schema()
  end

  def get_input_schema(:list_active_pipelines) do
    SchemaDefinitions.get_list_active_pipelines_schema()
  end

  def get_input_schema(:validate_scheduling_solutions) do
    SchemaDefinitions.get_validate_scheduling_solutions_schema()
  end

  def get_input_schema(:send_pipeline_request) do
    SchemaDefinitions.get_send_pipeline_request_schema()
  end

  # Helper functions for problem generation

  @spec generate_activities(integer()) :: [map()]
  defp generate_activities(1) do
    # Identity case - single activity
    [%{
      "id" => "identity_task",
      "name" => "Identity Task",
      "duration" => "PT30M",
      "required_capabilities" => ["basic"],
      "required_resources" => ["workstation_1"],
      "dependencies" => []
    }]
  end

  defp generate_activities(count) when count > 1 do
    # Generate dependency chain: task_1 -> task_2 -> task_3 -> ...
    for i <- 1..count do
      dependencies = if i == 1, do: [], else: ["task_#{i - 1}"]
      duration_minutes = 30 + i * 15  # 45, 60, 75, 90, 105
      
      %{
        "id" => "task_#{i}",
        "name" => "Task #{i}",
        "duration" => "PT#{duration_minutes}M",
        "required_capabilities" => ["basic"],
        "required_resources" => ["workstation_#{min(i, 3)}"],
        "dependencies" => dependencies
      }
    end
  end

  @spec generate_entities(integer()) :: [map()]
  defp generate_entities(count) do
    for i <- 1..count do
      %{
        "id" => "agent_#{i}",
        "type" => "agent",
        "capabilities" => ["basic", "advanced"],
        "availability" => "PT24H"
      }
    end
  end

  @spec generate_resources(integer()) :: map()
  defp generate_resources(1) do
    # Single activity: only workstation
    %{
      "workstation_1" => %{
        "type" => "computational",
        "capacity" => 1
      }
    }
  end

  defp generate_resources(count) when count > 1 do
    # Multi-activity: workstations + shared storage
    workstation_count = min(count, 3)
    
    workstations = for i <- 1..workstation_count, into: %{} do
      {"workstation_#{i}", %{
        "type" => "computational",
        "capacity" => 1
      }}
    end
    
    shared_storage = %{
      "shared_storage" => %{
        "type" => "storage",
        "capacity" => count
      }
    }
    
    Map.merge(workstations, shared_storage)
  end

  @spec generate_constraints(integer()) :: map()
  defp generate_constraints(1) do
    %{
      "max_concurrent_activities" => 1,
      "require_resources" => false,
      "simulation_mode" => true
    }
  end

  defp generate_constraints(count) when count > 1 do
    %{
      "max_concurrent_activities" => min(count, 3),
      "require_resources" => true,
      "simulation_mode" => true,
      "dependency_validation" => true
    }
  end
end
