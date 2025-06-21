# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPToolsV2.SchedulingHandlers do
  @moduledoc """
  Scheduling request handlers for MCP interface.
  
  Handles activity scheduling requests, train scheduling, and real scheduler integration.
  """

  require Logger

  @type scheduling_result :: %{
          schedule: list(),
          analysis: map(),
          resource_utilization: map(),
          timeline: list()
        }

  @type simulation_metadata :: %{
          real_solver: boolean(),
          solver: String.t(),
          problem_type: String.t(),
          activities_count: integer(),
          entities_count: integer(),
          resources_count: integer()
        }

  @doc """
  Schedule activities using Membrane pipeline architecture with multiple strategy options.
  """
  @spec handle_schedule_activities(map()) :: map()
  def handle_schedule_activities(params) do
    # Check if this is a trains05 scheduling request
    schedule_name = params["schedule_name"] || ""

    if String.contains?(schedule_name, "trains05") or String.contains?(schedule_name, "train") do
      # Use real train scheduling with hybrid coordinator
      handle_train_scheduling_request(params)
    else
      # Use real scheduler for other requests
      handle_real_scheduling_request(params)
    end
  end

  @doc """
  Handle train scheduling requests using hybrid coordinator.
  """
  @spec handle_train_scheduling_request(map()) :: map()
  def handle_train_scheduling_request(_params) do
    Logger.info("🚂 Processing trains05 scheduling request with real hybrid coordinator")

    # Convert trains05.dzn to schedule_activities format
    train_data = AriaEngine.TrainSchedulingConverter.convert_trains05_to_schedule_activities()

    # Call real scheduler with train data
    case call_real_scheduler(train_data) do
      {:ok, result} ->
        %{
          "status" => "success",
          "message" => "Train schedule generated using hybrid coordinator",
          "schedule" => format_schedule_result(result),
          "analysis" => format_analysis_result(result),
          "resource_utilization" => format_resource_utilization(result),
          "timeline" => format_timeline_result(result),
          "simulation_metadata" => %{
            "real_solver" => true,
            "solver" => "hybrid_coordinator_v2",
            "problem_type" => "trains05_scheduling",
            "activities_count" => length(train_data["activities"]),
            "entities_count" => length(train_data["entities"]),
            "resources_count" => map_size(train_data["resources"])
          }
        }

      {:error, reason} ->
        Logger.error("🚂 Train scheduling failed: #{reason}")

        %{
          "status" => "error",
          "error" => "Train scheduling failed: #{reason}",
          "fallback_used" => false
        }
    end
  end

  @doc """
  Handle general scheduling requests using real scheduler.
  """
  @spec handle_real_scheduling_request(map()) :: map()
  def handle_real_scheduling_request(params) do
    Logger.info("📋 Processing general scheduling request with real scheduler")

    # Call real scheduler with provided params
    case call_real_scheduler(params) do
      {:ok, result} ->
        %{
          "status" => "success",
          "message" => "Schedule generated using real scheduler",
          "schedule" => format_schedule_result(result),
          "analysis" => format_analysis_result(result),
          "resource_utilization" => format_resource_utilization(result),
          "timeline" => format_timeline_result(result),
          "simulation_metadata" => %{
            "real_solver" => true,
            "solver" => "aria_engine_scheduler",
            "activities_count" => length(params["activities"] || []),
            "entities_count" => length(params["entities"] || []),
            "resources_count" => map_size(params["resources"] || %{})
          }
        }

      {:error, reason} ->
        Logger.error("📋 General scheduling failed: #{reason}")

        %{
          "status" => "error",
          "error" => "Scheduling failed: #{reason}",
          "fallback_used" => false
        }
    end
  end

  @doc """
  Call the real scheduler with provided parameters.
  """
  @spec call_real_scheduler(map()) :: {:ok, scheduling_result()} | {:error, String.t()}
  def call_real_scheduler(params) do
    # Extract parameters for scheduler
    schedule_name = params["schedule_name"] || "default_schedule"
    activities = params["activities"] || []
    entities = params["entities"] || []
    resources = params["resources"] || %{}
    constraints = params["constraints"] || %{}
    simulation_options = params["simulation_options"] || %{}

    simulation_mode = simulation_options["simulation_mode"] || false
    verbose = simulation_options["verbose"] || 1
    activity_log = simulation_options["log_activities"] || false

    Logger.info("🔧 Calling AriaEngine.Scheduler.Core.schedule_with_enhanced_features")

    Logger.info(
      "🔧 Schedule: #{schedule_name}, Activities: #{length(activities)}, Entities: #{length(entities)}"
    )

    Logger.info("🔧 Activities type: #{inspect(activities |> Enum.take(1))}")
    Logger.info("🔧 Entities type: #{inspect(entities |> Enum.take(1))}")

    # Ensure activities is a list
    activities_list = if is_list(activities), do: activities, else: []
    entities_list = if is_list(entities), do: entities, else: []

    # Call the real scheduler
    AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
      schedule_name,
      activities_list,
      entities_list,
      resources,
      constraints,
      simulation_mode,
      activity_log,
      verbose
    )
  end

  # Result formatting functions

  @spec format_schedule_result(any()) :: list()
  defp format_schedule_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{schedule: schedule} -> schedule
      %{schedule: schedule} -> schedule
      _ -> []
    end
  end

  @spec format_analysis_result(any()) :: map()
  defp format_analysis_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{analysis: analysis} -> analysis
      %{analysis: analysis} -> analysis
      _ -> %{}
    end
  end

  @spec format_resource_utilization(any()) :: map()
  defp format_resource_utilization(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{resource_utilization: utilization} -> utilization
      %{resource_utilization: utilization} -> utilization
      _ -> %{}
    end
  end

  @spec format_timeline_result(any()) :: list()
  defp format_timeline_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{simulation_metadata: metadata} ->
        Map.get(metadata, :timeline, [])

      %{timeline: timeline} ->
        timeline

      _ ->
        []
    end
  end
end
