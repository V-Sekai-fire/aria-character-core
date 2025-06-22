# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineGraph.Scheduler do
  @moduledoc """
  Handles scheduling and routine management for entities in the timeline graph.

  This module implements Enhanced Scheduling for Phase 1 of ADR-085, enabling NPCs to 
  follow complex, time-sensitive routines like work shifts, meal times, and sleep cycles.
  """

  alias Timeline
  alias Timeline.Interval
  alias TimelineGraph.TimeConverter

  @type entity_id :: String.t()
  @type priority :: :low | :medium | :high | :critical

  @doc """
  Schedules a routine activity for an agent with priority and deadline handling.

  This implements Enhanced Scheduling for Phase 1 of ADR-085, enabling NPCs to 
  follow complex, time-sensitive routines like work shifts, meal times, and sleep cycles.

  ## Examples

  ```elixir
  # Schedule daily work routine
  {:ok, updated_graph} = TimelineGraph.Scheduler.schedule_routine(
    timeline_graph,
    "guard",
    :work_shift,
    start_time: ~U[2025-06-17 08:00:00Z],
    duration_hours: 8,
    priority: :high,
    repeat: :daily
  )

  # Schedule meal break with deadline
  {:ok, updated_graph} = TimelineGraph.Scheduler.schedule_routine(
    timeline_graph,
    "chef",
    :lunch_prep,
    start_time: ~U[2025-06-17 11:30:00Z],
    deadline: ~U[2025-06-17 12:00:00Z],
    priority: :medium
  )
  ```
  """
  @spec schedule_routine(map(), entity_id(), atom(), keyword()) :: {:ok, map()} | {:error, term()}
  def schedule_routine(timeline_graph, entity_id, routine_type, opts) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
        duration_hours = Keyword.get(opts, :duration_hours, 1)
        priority = Keyword.get(opts, :priority, :medium)
        deadline = Keyword.get(opts, :deadline)
        repeat = Keyword.get(opts, :repeat, :none)

        # Calculate end time
        end_time = DateTime.add(start_time, duration_hours * 3600, :second)

        # Create routine interval with metadata
        routine_interval =
          Interval.new(
            start_time,
            end_time,
            metadata: %{
              type: :scheduled_routine,
              routine_type: routine_type,
              priority: priority,
              deadline: deadline,
              repeat: repeat,
              entity_id: entity_id
            }
          )

        # Add to timeline with conflict detection
        case detect_schedule_conflicts(entity_timeline.timeline, routine_interval) do
          [] ->
            # No conflicts, add routine
            updated_timeline = Timeline.add_interval(entity_timeline.timeline, routine_interval)

            updated_entity_timeline = %{
              entity_timeline
              | timeline: updated_timeline,
                last_growth: DateTime.utc_now()
            }

            updated_timeline_graph = %{
              timeline_graph
              | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
            }

            {:ok, updated_timeline_graph}

          conflicts ->
            # Handle conflicts based on priority
            resolve_schedule_conflicts(timeline_graph, entity_id, routine_interval, conflicts)
        end
    end
  end

  @doc """
  Resolves schedule conflicts for an entity based on priority and deadline handling.

  Implements intelligent conflict resolution:
  - Higher priority activities override lower priority ones
  - Activities with deadlines get precedence over flexible ones
  - Attempts to reschedule conflicting lower-priority activities
  """
  @spec resolve_schedule_conflicts(map(), entity_id(), Interval.t(), [Interval.t()]) ::
          {:ok, map()} | {:error, term()}
  def resolve_schedule_conflicts(timeline_graph, entity_id, new_routine, conflicts) do
    entity_timeline = Map.get(timeline_graph.entities, entity_id)
    new_priority = get_in(new_routine.metadata, [:priority])
    new_deadline = get_in(new_routine.metadata, [:deadline])

    # Analyze conflicts to determine resolution strategy
    {can_override, reschedulable} =
      Enum.split_with(conflicts, fn conflict ->
        conflict_priority = get_in(conflict.metadata, [:priority])
        conflict_deadline = get_in(conflict.metadata, [:deadline])

        # Override if new routine has higher priority or has deadline while conflict doesn't
        priority_higher?(new_priority, conflict_priority) or
          (new_deadline != nil and conflict_deadline == nil)
      end)

    # Remove overridden activities
    updated_timeline =
      Enum.reduce(can_override, entity_timeline.timeline, fn conflict, timeline ->
        Timeline.remove_interval(timeline, conflict.id)
      end)

    # Add new routine
    updated_timeline = Timeline.add_interval(updated_timeline, new_routine)

    # Attempt to reschedule reschedulable activities
    final_timeline =
      Enum.reduce(reschedulable, updated_timeline, fn activity, timeline ->
        case find_next_available_slot(timeline, activity) do
          {:ok, rescheduled_activity} ->
            Timeline.add_interval(timeline, rescheduled_activity)

          {:error, _} ->
            # Could not reschedule - activity is dropped
            timeline
        end
      end)

    updated_entity_timeline = %{
      entity_timeline
      | timeline: final_timeline,
        last_growth: DateTime.utc_now()
    }

    updated_timeline_graph = %{
      timeline_graph
      | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
    }

    {:ok, updated_timeline_graph}
  end

  @doc """
  Gets the current scheduled routines for an entity within a time window.

  ## Examples

  ```elixir
  # Get today's schedule for a guard
  start_of_day = DateTime.beginning_of_day(DateTime.utc_now())
  end_of_day = DateTime.end_of_day(DateTime.utc_now())

  routines = TimelineGraph.Scheduler.get_scheduled_routines(
    timeline_graph, 
    "guard", 
    start_of_day,
    end_of_day
  )
  ```
  """
  @spec get_scheduled_routines(map(), entity_id(), DateTime.t(), DateTime.t()) ::
          [Interval.t()] | {:error, term()}
  def get_scheduled_routines(timeline_graph, entity_id, start_time, end_time) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        # Convert DateTime to STN time units
        stn_start = TimeConverter.datetime_to_stn_time(start_time, entity_timeline.timeline.stn.time_unit)
        stn_end = TimeConverter.datetime_to_stn_time(end_time, entity_timeline.timeline.stn.time_unit)

        # Get overlapping intervals from STN
        overlapping_intervals = Timeline.Internal.STN.Core.get_overlapping_intervals(
          entity_timeline.timeline.stn, 
          stn_start, 
          stn_end
        )

        # Filter for scheduled routines and convert back to Interval format
        overlapping_intervals
        |> Enum.filter(fn interval ->
          get_in(interval.metadata, [:type]) == :scheduled_routine
        end)
        |> Enum.map(fn stn_interval ->
          # Convert STN times back to DateTime
          start_dt = TimeConverter.convert_from_stn_time(stn_interval.start_time, entity_timeline.timeline.stn.time_unit)
          end_dt = TimeConverter.convert_from_stn_time(stn_interval.end_time, entity_timeline.timeline.stn.time_unit)
          
          Interval.new(start_dt, end_dt, metadata: stn_interval.metadata)
        end)
    end
  end

  @doc """
  Cancels a scheduled routine by routine type and optional time range.
  """
  @spec cancel_routine(map(), entity_id(), atom(), keyword()) :: {:ok, map()} | {:error, term()}
  def cancel_routine(timeline_graph, entity_id, routine_type, opts \\ []) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        start_time = Keyword.get(opts, :start_time)
        end_time = Keyword.get(opts, :end_time)

        # Find matching routines to cancel
        intervals_to_remove = find_matching_routines(entity_timeline.timeline, routine_type, start_time, end_time)

        # Remove the intervals
        updated_timeline =
          Enum.reduce(intervals_to_remove, entity_timeline.timeline, fn interval, timeline ->
            Timeline.remove_interval(timeline, interval.id)
          end)

        updated_entity_timeline = %{
          entity_timeline
          | timeline: updated_timeline,
            last_growth: DateTime.utc_now()
        }

        updated_timeline_graph = %{
          timeline_graph
          | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
        }

        {:ok, updated_timeline_graph}
    end
  end

  @doc """
  Gets all active routines for an entity at the current time.
  """
  @spec get_active_routines(map(), entity_id()) :: [Interval.t()] | {:error, term()}
  def get_active_routines(timeline_graph, entity_id) do
    now = DateTime.utc_now()
    get_scheduled_routines(timeline_graph, entity_id, now, now)
  end

  @doc """
  Checks if an entity has any schedule conflicts in a given time range.
  """
  @spec has_schedule_conflicts?(map(), entity_id(), DateTime.t(), DateTime.t()) :: boolean()
  def has_schedule_conflicts?(timeline_graph, entity_id, start_time, end_time) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        false

      entity_timeline ->
        # Create a test interval to check for conflicts
        test_interval = Interval.new(start_time, end_time, metadata: %{type: :test})
        conflicts = detect_schedule_conflicts(entity_timeline.timeline, test_interval)
        length(conflicts) > 0
    end
  end

  # Private helper functions

  defp detect_schedule_conflicts(timeline, new_interval) do
    start_time = get_in(new_interval.metadata, [:start_time])
    end_time = get_in(new_interval.metadata, [:end_time])

    # Convert DateTime to STN time units if necessary
    {stn_start, stn_end} =
      case {start_time, end_time} do
        {%DateTime{} = start_dt, %DateTime{} = end_dt} ->
          # Convert DateTime to milliseconds since epoch, then to STN units
          start_ms = DateTime.to_unix(start_dt, :millisecond)
          end_ms = DateTime.to_unix(end_dt, :millisecond)

          {TimeConverter.convert_to_stn_time(start_ms, timeline.time_unit),
           TimeConverter.convert_to_stn_time(end_ms, timeline.time_unit)}

        {start_num, end_num} when is_number(start_num) and is_number(end_num) ->
          {start_num, end_num}

        _ ->
          # Fallback: use start_time and end_time from Interval if available
          if new_interval.start_time && new_interval.end_time do
            start_ms = DateTime.to_unix(new_interval.start_time, :millisecond)
            end_ms = DateTime.to_unix(new_interval.end_time, :millisecond)

            {TimeConverter.convert_to_stn_time(start_ms, timeline.time_unit),
             TimeConverter.convert_to_stn_time(end_ms, timeline.time_unit)}
          else
            # Fallback for malformed intervals - 10 second range using LOD resolution
            {0, 10 * timeline.stn.lod_resolution}
          end
      end

    # Use STN Core to find conflicts
    conflicts = Timeline.Internal.STN.Core.check_interval_conflicts(timeline, stn_start, stn_end)

    # Convert back to Interval format for compatibility
    Enum.map(conflicts, fn conflict ->
      Interval.new(
        # Convert back from STN time units to DateTime
        TimeConverter.convert_from_stn_time(conflict.start_time, timeline.time_unit),
        TimeConverter.convert_from_stn_time(conflict.end_time, timeline.time_unit),
        metadata: conflict.metadata
      )
    end)
  end

  defp priority_higher?(priority1, priority2) do
    priority_values = %{
      :low => 1,
      :medium => 2,
      :high => 3,
      :critical => 4
    }

    Map.get(priority_values, priority1, 0) > Map.get(priority_values, priority2, 0)
  end

  defp find_next_available_slot(timeline, activity) do
    # Extract duration and start time from activity
    duration =
      case get_in(activity.metadata, [:duration_hours]) do
        hours when is_number(hours) ->
          # Convert hours to STN time units
          # hours to milliseconds to STN units
          TimeConverter.convert_duration_to_stn_time(hours * 3600 * 1000, timeline.time_unit)

        _ ->
          # Default 1 hour duration
          TimeConverter.convert_duration_to_stn_time(3600 * 1000, timeline.time_unit)
      end

    earliest_start =
      case get_in(activity.metadata, [:start_time]) do
        %DateTime{} = dt ->
          TimeConverter.convert_to_stn_time(DateTime.to_unix(dt, :millisecond), timeline.time_unit)

        num when is_number(num) ->
          num

        _ ->
          # Default to current time in STN units
          now_ms = DateTime.to_unix(DateTime.utc_now(), :millisecond)
          TimeConverter.convert_to_stn_time(now_ms, timeline.time_unit)
      end

    # Use STN Core to find next available slot
    case Timeline.Internal.STN.Core.find_next_available_slot(timeline, duration, earliest_start) do
      {:ok, slot_start, slot_end} ->
        # Convert back to DateTime format
        start_dt = TimeConverter.convert_from_stn_time(slot_start, timeline.time_unit)
        end_dt = TimeConverter.convert_from_stn_time(slot_end, timeline.time_unit)

        # Return rescheduled activity
        {:ok, Interval.new(start_dt, end_dt, metadata: activity.metadata)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_matching_routines(timeline, routine_type, start_time, end_time) do
    # Get all intervals from the STN
    all_intervals = Timeline.Internal.STN.Core.get_intervals(timeline.stn)

    # Filter for matching routine type
    matching_intervals = 
      all_intervals
      |> Enum.filter(fn interval ->
        get_in(interval.metadata, [:type]) == :scheduled_routine and
        get_in(interval.metadata, [:routine_type]) == routine_type
      end)

    # Apply time range filter if specified
    case {start_time, end_time} do
      {nil, nil} ->
        # No time filter - return all matching routines
        convert_stn_intervals_to_timeline_intervals(matching_intervals, timeline.stn.time_unit)

      {%DateTime{} = start_dt, nil} ->
        # Filter for routines starting after start_time
        stn_start = TimeConverter.datetime_to_stn_time(start_dt, timeline.stn.time_unit)
        
        matching_intervals
        |> Enum.filter(fn interval -> interval.start_time >= stn_start end)
        |> convert_stn_intervals_to_timeline_intervals(timeline.stn.time_unit)

      {nil, %DateTime{} = end_dt} ->
        # Filter for routines ending before end_time
        stn_end = TimeConverter.datetime_to_stn_time(end_dt, timeline.stn.time_unit)
        
        matching_intervals
        |> Enum.filter(fn interval -> interval.end_time <= stn_end end)
        |> convert_stn_intervals_to_timeline_intervals(timeline.stn.time_unit)

      {%DateTime{} = start_dt, %DateTime{} = end_dt} ->
        # Filter for routines within the time range
        stn_start = TimeConverter.datetime_to_stn_time(start_dt, timeline.stn.time_unit)
        stn_end = TimeConverter.datetime_to_stn_time(end_dt, timeline.stn.time_unit)
        
        matching_intervals
        |> Enum.filter(fn interval ->
          # Check for overlap: intervals overlap if start1 <= end2 and start2 <= end1
          interval.start_time <= stn_end and stn_start <= interval.end_time
        end)
        |> convert_stn_intervals_to_timeline_intervals(timeline.stn.time_unit)

      _ ->
        # Invalid time parameters
        []
    end
  end

  defp convert_stn_intervals_to_timeline_intervals(stn_intervals, time_unit) do
    Enum.map(stn_intervals, fn stn_interval ->
      start_dt = TimeConverter.convert_from_stn_time(stn_interval.start_time, time_unit)
      end_dt = TimeConverter.convert_from_stn_time(stn_interval.end_time, time_unit)
      
      Interval.new(start_dt, end_dt, metadata: stn_interval.metadata)
    end)
  end
end
