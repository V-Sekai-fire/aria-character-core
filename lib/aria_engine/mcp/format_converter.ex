# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.FormatConverter do
  @moduledoc """
  Converts HybridCoordinatorV2 plan results to MCP format.
  
  Handles the conversion between internal planning representations
  and the external MCP tool response format.
  """

  require Logger

  @doc """
  Convert HybridCoordinatorV2 plan result to MCP format.
  """
  def convert_plan_to_mcp_format(plan) do
    try do
      %{
        status: "success",
        reason: "Planning completed successfully",
        schedule: extract_schedule_from_plan(plan),
        analysis: extract_analysis_from_plan(plan),
        resource_utilization: %{},
        timeline: extract_timeline_from_plan(plan),
        simulation_metadata: extract_metadata_from_plan(plan)
      }
    rescue
      e ->
        Logger.error("Error converting plan to MCP format: #{Exception.message(e)}")
        format_mcp_error("Plan conversion error: #{Exception.message(e)}")
    end
  end

  @doc """
  Format error response in MCP format.
  """
  def format_mcp_error(reason) do
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

  # Extract schedule information from plan
  defp extract_schedule_from_plan(plan) do
    case Map.get(plan, :solution_tree) do
      nil -> []
      solution_tree -> convert_solution_tree_to_schedule(solution_tree)
    end
  end

  # Extract analysis information from plan
  defp extract_analysis_from_plan(plan) do
    metadata = Map.get(plan, :metadata, %{})
    temporal_constraints = Map.get(plan, :temporal_constraints, %{})
    
    %{
      planning_time: Map.get(metadata, :planning_time),
      domain_name: Map.get(metadata, :domain_name),
      goals_count: length(Map.get(metadata, :goals, [])),
      temporal_constraints_count: map_size(temporal_constraints),
      strategy_info: Map.get(metadata, :strategy_coordinator, %{})
    }
  end

  # Extract timeline information from plan
  defp extract_timeline_from_plan(plan) do
    case Map.get(plan, :temporal_constraints) do
      nil -> []
      constraints -> convert_temporal_constraints_to_timeline(constraints)
    end
  end

  # Extract metadata from plan
  defp extract_metadata_from_plan(plan) do
    metadata = Map.get(plan, :metadata, %{})
    
    %{
      created_at: Map.get(metadata, :planning_time, System.system_time(:millisecond)),
      domain_name: Map.get(metadata, :domain_name),
      planner_type: "HybridCoordinatorV2",
      api_version: "1.0.0"
    }
  end

  # Convert solution tree to schedule format
  defp convert_solution_tree_to_schedule(solution_tree) do
    try do
      extract_primitive_actions_from_tree(solution_tree)
      |> Enum.with_index()
      |> Enum.map(fn {{action_name, args}, index} ->
        %{
          id: "action_#{index}",
          action: action_name,
          arguments: args || [],
          start_time: index * 60, # Simple sequential timing
          duration: 60, # Default 1 minute duration
          status: "planned"
        }
      end)
    rescue
      e ->
        Logger.warning("Error converting solution tree to schedule: #{Exception.message(e)}")
        []
    end
  end

  # Extract primitive actions from solution tree
  defp extract_primitive_actions_from_tree(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        Enum.flat_map(children, &extract_primitive_actions_from_tree/1)
      
      %{task: {action_name, args}, status: :primitive} ->
        [{action_name, args}]
      
      %{task: task} when is_tuple(task) ->
        [task]
      
      _ ->
        []
    end
  end

  # Convert temporal constraints to timeline format
  defp convert_temporal_constraints_to_timeline(constraints) do
    try do
      constraints
      |> Enum.take(10) # Limit to first 10 for brevity
      |> Enum.with_index()
      |> Enum.map(fn {{constraint_type, constraint_data}, index} ->
        %{
          id: "constraint_#{index}",
          type: constraint_type,
          data: constraint_data,
          timestamp: System.system_time(:millisecond)
        }
      end)
    rescue
      e ->
        Logger.warning("Error converting temporal constraints to timeline: #{Exception.message(e)}")
        []
    end
  end
end
