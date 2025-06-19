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
  """
  def generate_activity_log(schedule, _entities) do
    schedule
    |> Enum.map(fn activity ->
      %ActivityLogEntry{
        timestamp: DateTime.utc_now(),
        activity_id: activity.id,
        entity_id: if(activity.assigned_entity, do: activity.assigned_entity.id, else: nil),
        event_type: :completed,
        resource_snapshot: %{
          assigned_resources: activity.assigned_resources || [],
          resource_requirements: activity.resource_requirements || %{}
        },
        state_changes: [],
        metadata: %{
          execution_order: activity.execution_order,
          start_time: activity.start_time,
          end_time: activity.end_time
        }
      }
    end)
  end
  
  @doc """
  Generate simulation activity log.
  """
  def generate_simulation_activity_log(schedule, _entities, final_state) do
    schedule
    |> Enum.map(fn activity ->
      execution_time = AriaEngine.StateV2.get_fact(final_state, activity.id, "execution_time")
      
      %ActivityLogEntry{
        timestamp: execution_time || DateTime.utc_now(),
        activity_id: activity.id,
        entity_id: if(activity.assigned_entity, do: activity.assigned_entity.id, else: nil),
        event_type: :completed,
        resource_snapshot: %{
          assigned_resources: activity.assigned_resources || [],
          resource_requirements: activity.resource_requirements || %{},
          simulation_state: activity.simulation_state
        },
        state_changes: [],
        metadata: %{
          execution_order: activity.execution_order,
          start_time: activity.start_time,
          end_time: activity.end_time,
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
      %{
        activity_id: activity.id,
        start_time: activity.start_time,
        end_time: activity.end_time,
        duration: activity.end_time - activity.start_time,
        entity: if(activity.assigned_entity, do: activity.assigned_entity.id, else: nil),
        resources: Enum.map(activity.assigned_resources || [], fn res -> res.id end),
        status: "scheduled"
      }
    end)
  end
end
