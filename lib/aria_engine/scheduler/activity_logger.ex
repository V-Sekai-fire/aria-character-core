# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.ActivityLogger do
  @moduledoc """
  Generates activity logs and timelines from scheduled activities.
  
  Creates detailed logs of activity execution, resource usage, and
  timeline visualizations for both planning and simulation modes.
  """
  
  require Logger
  
  alias AriaEngine.Scheduler.ActivityLogEntry
  
  @doc """
  Generate activity log from schedule.
  
  ## Parameters
  
  - `schedule` - List of scheduled activities
  - `entities` - List of entities (currently unused but kept for compatibility)
  - `opts` - Optional parameters:
    - `:mission_start` - Optional mission start time (DateTime.t())
    
  When mission_start is provided, generates absolute timestamps.
  When mission_start is nil, generates duration-based formatting.
  """
  def generate_activity_log(schedule, _entities, opts \\ []) do
    mission_start = Keyword.get(opts, :mission_start)
    
    schedule
    |> Enum.with_index()
    |> Enum.map(fn {activity, index} ->
      # Calculate relative minutes from mission start
      relative_minutes = case Map.get(activity, :start_time) do
        start_time when is_integer(start_time) ->
          start_time
        _ ->
          # Fallback: use execution order with realistic spacing (30 minutes apart)
          index * 30
      end
      
      # Generate timestamp and duration formatting
      {timestamp, mission_duration} = format_activity_time(relative_minutes, mission_start)
      
      %ActivityLogEntry{
        timestamp: timestamp,
        mission_duration: mission_duration,
        relative_minutes: relative_minutes,
        activity_id: Map.get(activity, :id),
        entity_id: case Map.get(activity, :assigned_entity) do
          %{id: id} -> id
          _ -> nil
        end,
        event_type: :started,
        resource_snapshot: %{
          assigned_resources: Map.get(activity, :assigned_resources, []),
          resource_requirements: Map.get(activity, :resource_requirements, %{})
        },
        state_changes: [],
        metadata: %{
          execution_order: Map.get(activity, :execution_order),
          start_time: Map.get(activity, :start_time),
          end_time: Map.get(activity, :end_time),
          duration_minutes: Map.get(activity, :duration, 0)
        }
      }
    end)
  end
  
  @doc """
  Generate simulation activity log.
  
  ## Parameters
  
  - `schedule` - List of scheduled activities
  - `entities` - List of entities (currently unused but kept for compatibility) 
  - `final_state` - Final state from simulation
  - `opts` - Optional parameters:
    - `:mission_start` - Optional mission start time (DateTime.t())
  """
  def generate_simulation_activity_log(schedule, _entities, final_state, opts \\ []) do
    mission_start = Keyword.get(opts, :mission_start)
    
    schedule
    |> Enum.map(fn activity ->
      execution_time = AriaEngine.StateV2.get_fact(final_state, Map.get(activity, :id), "execution_time")
      
      # Use end_time for simulation completion timing
      relative_minutes = case Map.get(activity, :end_time) do
        end_time when is_integer(end_time) -> end_time
        _ -> Map.get(activity, :start_time, 0)
      end
      
      # Generate timestamp and duration formatting  
      {timestamp, mission_duration} = format_activity_time(relative_minutes, mission_start)
      
      %ActivityLogEntry{
        timestamp: timestamp,
        mission_duration: mission_duration,
        relative_minutes: relative_minutes,
        activity_id: Map.get(activity, :id),
        entity_id: case Map.get(activity, :assigned_entity) do
          %{id: id} -> id
          _ -> nil
        end,
        event_type: :completed,
        resource_snapshot: %{
          assigned_resources: Map.get(activity, :assigned_resources, []),
          resource_requirements: Map.get(activity, :resource_requirements, %{}),
          simulation_state: Map.get(activity, :simulation_state)
        },
        state_changes: [],
        metadata: %{
          execution_order: Map.get(activity, :execution_order),
          start_time: Map.get(activity, :start_time),
          end_time: Map.get(activity, :end_time),
          simulation_executed: true,
          simulation_execution_time: execution_time
        }
      }
    end)
  end
  
  @doc """
  Generate timeline from schedule.
  """
  def generate_timeline(schedule, _entities, _resources) do
    schedule
    |> Enum.map(fn activity ->
      start_time = Map.get(activity, :start_time, 0)
      end_time = Map.get(activity, :end_time, 0)
      
      %{
        activity_id: Map.get(activity, :id),
        start_time: start_time,
        end_time: end_time,
        duration: end_time - start_time,
        entity: case Map.get(activity, :assigned_entity) do
          %{id: id} -> id
          _ -> nil
        end,
        resources: Enum.map(Map.get(activity, :assigned_resources, []), fn res -> 
          case res do
            %{id: id} -> id
            _ -> res
          end
        end),
        status: "scheduled"
      }
    end)
  end

  # Private helper functions

  @doc false
  defp format_activity_time(relative_minutes, mission_start) do
    case mission_start do
      %DateTime{} = start_time ->
        # When mission start time is known, calculate absolute timestamp
        timestamp = DateTime.add(start_time, relative_minutes * 60, :second)
        {timestamp, nil}
      
      nil ->
        # When mission start time is unknown, use duration-based formatting
        mission_duration = format_mission_duration(relative_minutes)
        {nil, mission_duration}
    end
  end

  @doc false
  defp format_mission_duration(minutes) when minutes < 60 do
    "Mission Minute #{minutes}"
  end

  defp format_mission_duration(minutes) when minutes < 1440 do
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)
    
    if remaining_minutes == 0 do
      "Mission Hour #{hours}:00"
    else
      "Mission Hour #{hours}:#{String.pad_leading(to_string(remaining_minutes), 2, "0")}"
    end
  end

  defp format_mission_duration(minutes) do
    days = div(minutes, 1440)
    remaining_minutes = rem(minutes, 1440)
    hours = div(remaining_minutes, 60)
    mins = rem(remaining_minutes, 60)
    
    if hours == 0 and mins == 0 do
      "Mission Day #{days}, 00:00"
    else
      "Mission Day #{days}, #{String.pad_leading(to_string(hours), 2, "0")}:#{String.pad_leading(to_string(mins), 2, "0")}"
    end
  end
end
