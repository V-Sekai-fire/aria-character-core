# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.PlanConverter do
  @moduledoc """
  Converts planning results back to scheduler format.
  
  Handles the translation from hybrid planner results (encapsulated plans)
  back to scheduler concepts (schedules with timing and resource assignments).
  """
  
  require Logger
  
  @doc """
  Convert plan to enhanced schedule format.
  """
  def convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources, base_datetime) do
    # Extract primitive actions from the plan
    internal_plan = HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
    primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(internal_plan)
    
    # Convert actions to scheduled activities with proper timing and assignments
    scheduled_activities = primitive_actions
    |> Enum.with_index()
    |> Enum.map(fn {action_step, index} ->
      # Handle different action step formats
      activity_id = case action_step do
        {action_name, _args} when is_atom(action_name) -> 
          Atom.to_string(action_name)
        {action_name, _args} when is_binary(action_name) -> 
          action_name
        action_name when is_atom(action_name) -> 
          Atom.to_string(action_name)
        action_name when is_binary(action_name) -> 
          action_name
        other -> 
          Logger.warning("Unexpected action step format: #{inspect(other)}")
          "unknown_action_#{index}"
      end
      
      # Find original activity
      # Accept both "durative_<id>" and "<id>" as matches
      original_activity =
        Enum.find(activities, fn act ->
          act.id == activity_id or "durative_#{act.id}" == activity_id
        end)

      if original_activity do
        duration_val = Map.get(original_activity, :duration)
        # All actions are durative; "instantaneous" actions have duration 0 ("PT0S")
        {duration_sec, fixed_start, fixed_end, duration_str} =
          cond do
            is_map(duration_val) and Map.has_key?(duration_val, :start) and Map.has_key?(duration_val, :end) ->
              start_time = duration_val[:start] || duration_val["start"]
              end_time = duration_val[:end] || duration_val["end"]
              case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
                {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
                  {DateTime.diff(end_dt, start_dt), start_time, end_time, %{start: start_time, end: end_time}}
                _ ->
                  {0, start_time, end_time, %{start: start_time, end: end_time}}
              end
            is_binary(duration_val) ->
              case :iso8601.parse_duration(String.to_charlist(duration_val)) do
                parsed when is_list(parsed) ->
                  map = Enum.into(parsed, %{})
                  total_seconds = (map[:hours] || 0) * 3600 + (map[:minutes] || 0) * 60 + (map[:seconds] || 0)
                  if total_seconds < 0 do
                    {0, nil, nil, duration_val}
                  else
                    {AriaEngine.Utils.duration_struct_to_seconds(map), nil, nil, duration_val}
                  end
                _ -> {0, nil, nil, duration_val}
              end
            is_map(duration_val) ->
              {AriaEngine.Utils.duration_struct_to_seconds(duration_val), nil, nil, AriaEngine.Utils.duration_to_string(duration_val)}
            true ->
              {0, nil, nil, "PT0S"}
          end
        required_capabilities = Map.get(original_activity, :required_capabilities, [])
        required_resources = Map.get(original_activity, :required_resources, [])

        # Assign entities and resources with improved logic
        assigned_entity = assign_entity_for_activity(original_activity, entities)
        assigned_resources = assign_resources_for_activity(original_activity, resources)

        # Get the first required resource for compatibility with JSON generator
        primary_resource = case required_resources do
          [first_resource | _] -> first_resource
          [] -> nil
        end

        # Compute timing and output duration correctly for both ISO8601 and DateTime interval
        {output_duration, timing_seconds} =
          cond do
            is_map(duration_val) and (Map.has_key?(duration_val, "start") and Map.has_key?(duration_val, "end")) ->
              # DateTime interval as map with string keys
              start_time = duration_val["start"]
              end_time = duration_val["end"]
              case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
                {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
                  {%{"start" => start_time, "end" => end_time}, DateTime.diff(end_dt, start_dt)}
                _ ->
                  {%{"start" => start_time, "end" => end_time}, 0}
              end
            is_map(duration_val) and (Map.has_key?(duration_val, :start) and Map.has_key?(duration_val, :end)) ->
              # DateTime interval as map with atom keys
              start_time = duration_val[:start]
              end_time = duration_val[:end]
              case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
                {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
                  {%{start: start_time, end: end_time}, DateTime.diff(end_dt, start_dt)}
                _ ->
                  {%{start: start_time, end: end_time}, 0}
              end
            is_binary(duration_val) ->
              # Only parse if string, e.g. "PT0S"
              parsed =
                case duration_val do
                  "PT0S" -> %{hours: 0, minutes: 0, seconds: 0}
                  _ ->
                    case :iso8601.parse_duration(String.to_charlist(duration_val)) do
                      parsed when is_list(parsed) -> Enum.into(parsed, %{})
                      _ -> %{hours: 0, minutes: 0, seconds: 0}
                    end
                end
              {AriaEngine.Utils.duration_to_string(parsed), AriaEngine.Utils.duration_struct_to_seconds(parsed)}
            is_map(duration_val) and Map.has_key?(duration_val, :hours) and Map.has_key?(duration_val, :minutes) and Map.has_key?(duration_val, :seconds) ->
              # Duration struct
              {AriaEngine.Utils.duration_to_string(duration_val), AriaEngine.Utils.duration_struct_to_seconds(duration_val)}
            is_map(duration_val) ->
              # Not a duration struct or DateTime interval, treat as zero duration
              {AriaEngine.Utils.duration_to_string(%{hours: 0, minutes: 0, seconds: 0}), 0}
            true ->
              {"PT0S", 0}
          end

        Map.merge(original_activity, %{
          start_time: fixed_start || index * timing_seconds,
          end_time: fixed_end || (if fixed_start, do: fixed_end, else: (index + 1) * timing_seconds),
          scheduled: true,
          execution_order: index,
          assigned_entity: assigned_entity,
          assigned_resources: assigned_resources,
          # Add fields expected by JSON generator
          agent_id: if(assigned_entity, do: assigned_entity.id, else: nil),
          resource_id: primary_resource,
          resource_requirements: %{
            capabilities: required_capabilities,
            resources: required_resources
          },
          duration: output_duration
        })
      else
        # Return error if activity not found in original list
        raise "Activity #{activity_id} from plan not found in original activities list"
      end
    end)
    
    # Phase 2: Fix timing to respect dependencies
    case fix_timing_constraints(scheduled_activities, activities, base_datetime) do
      {:ok, scheduled_activities_with_proper_timing} ->
        scheduled_activities_with_proper_timing
      {:error, reason} ->
        raise "Failed to fix timing constraints: #{inspect(reason)}"
    end
  end
  
  @doc """
  Convert simulation results to schedule format.
  """
  def convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources, base_datetime) do
    # Similar to convert_plan_to_enhanced_schedule but with simulation state information
    schedule = convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources, base_datetime)
    
    # Enhance with simulation state data
    schedule
    |> Enum.map(fn activity ->
      activity_id = activity.id
      execution_time = AriaEngine.StateV2.get_fact(final_state, activity_id, "execution_time")
      
      Map.merge(activity, %{
        simulation_executed: true,
        simulation_execution_time: execution_time,
        simulation_state: "completed"
      })
    end)
  end
  
  @doc """
  Assign an entity to an activity based on required capabilities.
  """
  def assign_entity_for_activity(activity, entities) do
    required_capabilities = Map.get(activity, :required_capabilities, [])
    
    if Enum.empty?(required_capabilities) do
      nil
    else
      Enum.find(entities, fn entity ->
        Enum.all?(required_capabilities, fn cap ->
          Enum.member?(entity.capabilities || [], cap)
        end)
      end)
    end
  end
  
  @doc """
  Assign resources to an activity based on required resources.
  """
  def assign_resources_for_activity(activity, resources) do
    required_resources = Map.get(activity, :required_resources, [])
    
    required_resources
    |> Enum.map(fn resource_id ->
      Enum.find(resources, fn resource -> resource.id == resource_id end)
    end)
    |> Enum.filter(& &1)
  end
  
  @doc """
  Fix timing constraints to respect dependencies using Timeline API.
  
  Requires explicit base datetime to ensure deterministic scheduling behavior.
  Returns {:ok, activities} on success or {:error, reason} on failure.
  """
  def fix_timing_constraints(scheduled_activities, original_activities, base_datetime) do
    case validate_base_datetime(base_datetime) do
      {:ok, validated_datetime} ->
        do_fix_timing_constraints(scheduled_activities, original_activities, validated_datetime)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_base_datetime(nil), do: {:error, :missing_base_datetime}
  defp validate_base_datetime(%DateTime{} = dt), do: {:ok, dt}
  defp validate_base_datetime(_), do: {:error, :invalid_base_datetime}

  defp do_fix_timing_constraints(scheduled_activities, original_activities, base_datetime) do
    
    # Build Timeline.Interval structs
    intervals =
      Enum.with_index(scheduled_activities)
      |> Enum.map(fn {activity, index} ->
        # Parse duration to get seconds
        duration_seconds = case Map.get(activity, :duration, "PT0S") do
          duration_str when is_binary(duration_str) ->
            case :iso8601.parse_duration(String.to_charlist(duration_str)) do
              parsed when is_list(parsed) ->
                map = Enum.into(parsed, %{})
                (map[:hours] || 0) * 3600 + (map[:minutes] || 0) * 60 + (map[:seconds] || 0)
              _ -> 0
            end
          duration_map when is_map(duration_map) ->
            (duration_map[:hours] || 0) * 3600 + (duration_map[:minutes] || 0) * 60 + (duration_map[:seconds] || 0)
          _ -> 0
        end
        
        # Create start and end times (initially sequential, will be adjusted by Timeline)
        start_time = DateTime.add(base_datetime, index * 60, :second)  # Space activities 1 minute apart initially
        end_time = DateTime.add(start_time, duration_seconds, :second)
        
        # Create Timeline.Interval struct
        Timeline.Interval.new(start_time, end_time, [
          metadata: %{
            id: activity.id,
            dependencies: Map.get(activity, :dependencies, []),
            original_activity: activity
          }
        ])
      end)

    # Create Timeline using cold boot order - let Timeline handle STN initialization
    timeline = Timeline.new()
    
    # Add intervals to Timeline
    timeline_with_intervals = Timeline.add_intervals(timeline, intervals)

    # Add dependency constraints using Timeline API
    timeline_with_constraints = Enum.reduce(scheduled_activities, timeline_with_intervals, fn activity, acc_timeline ->
      dependencies = Map.get(activity, :dependencies, [])
      
      Enum.reduce(dependencies, acc_timeline, fn dep_id, inner_timeline ->
        # Add constraint that dependency must finish before this activity starts
        # Timeline expects constraints in seconds (external API), converts to 1ms internally
        Timeline.add_constraint(
          inner_timeline,
          "#{dep_id}_end",
          "#{activity.id}_start", 
          {0, 86400}  # Dependency end must be <= activity start (with 0 to 24 hours gap in seconds)
        )
      end)
    end)

    # Solve Timeline for consistent timing
    solved_timeline = Timeline.solve(timeline_with_constraints)

    # Extract timing for each activity from solved Timeline
    time_map = 
      solved_timeline.intervals
      |> Enum.into(%{}, fn {_interval_id, interval} ->
        activity_id = interval.metadata[:id]
        {activity_id, {interval.start_time, interval.end_time}}
      end)

    # Update scheduled_activities with computed times
    updated_activities = Enum.map(scheduled_activities, fn activity ->
      case Map.get(time_map, activity.id) do
        {start_time, end_time} when not is_nil(start_time) and not is_nil(end_time) ->
          # Convert DateTime back to seconds offset from base
          start_offset = DateTime.diff(start_time, base_datetime, :second)
          end_offset = DateTime.diff(end_time, base_datetime, :second)
          
          Map.put(activity, :start_time, start_offset)
          |> Map.put(:end_time, end_offset)
        _ ->
          Map.put(activity, :start_time, 0)
          |> Map.put(:end_time, 0)
      end
    end)
    
    {:ok, updated_activities}
  end
  
  # (Removed: iterative timing constraint code, now handled by Timelines STN)
  
end
