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
  def convert_plan_to_enhanced_schedule(
        encapsulated_plan,
        activities,
        entities,
        resources,
        base_datetime
      ) do
    # Extract primitive actions from the plan
    internal_plan =
      HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)

    Logger.debug("Internal plan: #{inspect(internal_plan)}")
    
    primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(internal_plan)
    
    Logger.debug("Primitive actions: #{inspect(primitive_actions)}")
    Logger.debug("Number of primitive actions: #{length(primitive_actions)}")

    # Convert actions to scheduled activities with proper timing and assignments
    scheduled_activities =
      primitive_actions
      |> Enum.with_index()
      |> Enum.map(fn {action_step, index} ->
        Logger.debug("Processing action_step #{index}: #{inspect(action_step)}")
        activity_id = extract_activity_id(action_step, index)
        Logger.debug("Extracted activity_id: #{inspect(activity_id)}")
        original_activity = find_original_activity(activities, activity_id)
        Logger.debug("Found original_activity: #{inspect(original_activity != nil)}")

        if original_activity do
          convert_activity_to_scheduled(original_activity, entities, resources, index)
        else
          Logger.error("Activity #{inspect(activity_id)} from plan not found in original activities list")
          Logger.debug("Available activities: #{inspect(Enum.map(activities, &Map.get(&1, "id")))}")
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
  def convert_simulation_to_schedule(
        encapsulated_plan,
        final_state,
        activities,
        entities,
        resources,
        base_datetime
      ) do
    # Similar to convert_plan_to_enhanced_schedule but with simulation state information
    schedule =
      convert_plan_to_enhanced_schedule(
        encapsulated_plan,
        activities,
        entities,
        resources,
        base_datetime
      )

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

  defp do_fix_timing_constraints(scheduled_activities, _original_activities, base_datetime) do
    # Build Timeline.Interval structs
    intervals =
      Enum.with_index(scheduled_activities)
      |> Enum.map(fn {activity, index} ->
        # Parse duration to get seconds
        duration_seconds =
          case Map.get(activity, :duration, "PT0S") do
            duration_str when is_binary(duration_str) ->
              case :iso8601.parse_duration(String.to_charlist(duration_str)) do
                parsed when is_list(parsed) ->
                  map = Enum.into(parsed, %{})
                  (map[:hours] || 0) * 3600 + (map[:minutes] || 0) * 60 + (map[:seconds] || 0)

                _ ->
                  0
              end

            duration_map when is_map(duration_map) ->
              (duration_map[:hours] || 0) * 3600 + (duration_map[:minutes] || 0) * 60 +
                (duration_map[:seconds] || 0)

            _ ->
              0
          end

        # Create start and end times (initially sequential, will be adjusted by Timeline)
        # Space activities 1 minute apart initially
        start_time = DateTime.add(base_datetime, index * 60, :second)
        end_time = DateTime.add(start_time, duration_seconds, :second)

        # Create Timeline.Interval struct
        activity_id = if is_map(activity) and Map.has_key?(activity, "id") do
          Map.get(activity, "id")
        else
          Map.get(activity, :id)
        end
        
        dependencies = if Map.has_key?(activity, "dependencies") do
          Map.get(activity, "dependencies", [])
        else
          Map.get(activity, :dependencies, [])
        end
        
        Timeline.Interval.new(start_time, end_time,
          metadata: %{
            id: activity_id,
            dependencies: dependencies,
            original_activity: activity
          }
        )
      end)

    # Create Timeline using cold boot order - let Timeline handle STN initialization
    timeline = Timeline.new()

    # Add intervals to Timeline
    timeline_with_intervals = Enum.reduce(intervals, timeline, fn interval, acc_timeline ->
      Timeline.add_interval(acc_timeline, interval)
    end)

    # Add dependency constraints using Timeline API
    timeline_with_constraints =
      Enum.reduce(scheduled_activities, timeline_with_intervals, fn activity, acc_timeline ->
        dependencies = if Map.has_key?(activity, "dependencies") do
          Map.get(activity, "dependencies", [])
        else
          Map.get(activity, :dependencies, [])
        end

        activity_id = if is_map(activity) and Map.has_key?(activity, "id") do
          Map.get(activity, "id")
        else
          Map.get(activity, :id)
        end

        Enum.reduce(dependencies, acc_timeline, fn dep_id, inner_timeline ->
          # Add constraint that dependency must finish before this activity starts
          # Timeline expects constraints in seconds (external API), converts to 1ms internally
          Timeline.add_constraint(
            inner_timeline,
            "#{dep_id}_end",
            "#{activity_id}_start",
            # Dependency end must be <= activity start (with 0 to 24 hours gap in seconds)
            {0, 86_400}
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
    updated_activities =
      Enum.map(scheduled_activities, fn activity ->
        activity_id = if is_map(activity) and Map.has_key?(activity, "id") do
          Map.get(activity, "id")
        else
          Map.get(activity, :id)
        end
        
        case Map.get(time_map, activity_id) do
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

  # Private helper functions for duration parsing and activity conversion

  defp extract_activity_id(action_step, index) do
    Logger.debug("Extracting activity ID from action_step: #{inspect(action_step)}, index: #{index}")
    
    result = case action_step do
      {action_name, _args} when is_atom(action_name) ->
        action_name_str = Atom.to_string(action_name)
        # Handle durative action names by removing the "durative_" prefix
        if String.starts_with?(action_name_str, "durative_") do
          String.replace_prefix(action_name_str, "durative_", "")
        else
          action_name_str
        end

      {action_name, _args} when is_binary(action_name) ->
        # Handle durative action names by removing the "durative_" prefix
        if String.starts_with?(action_name, "durative_") do
          String.replace_prefix(action_name, "durative_", "")
        else
          action_name
        end

      action_name when is_atom(action_name) ->
        action_name_str = Atom.to_string(action_name)
        # Handle durative action names by removing the "durative_" prefix
        if String.starts_with?(action_name_str, "durative_") do
          String.replace_prefix(action_name_str, "durative_", "")
        else
          action_name_str
        end

      action_name when is_binary(action_name) ->
        # Handle durative action names by removing the "durative_" prefix
        if String.starts_with?(action_name, "durative_") do
          String.replace_prefix(action_name, "durative_", "")
        else
          action_name
        end

      nil ->
        Logger.warning("Action step is nil at index #{index}")
        "unknown_action_#{index}"

      other ->
        Logger.warning("Unexpected action step format: #{inspect(other)}")
        "unknown_action_#{index}"
    end
    
    Logger.debug("Extracted activity ID: #{inspect(result)}")
    result
  end

  defp find_original_activity(activities, activity_id) do
    Enum.find(activities, fn act ->
      actual_id = if is_map(act) and Map.has_key?(act, "id") do
        Map.get(act, "id")
      else
        Map.get(act, :id)
      end
      actual_id == activity_id or "durative_#{actual_id}" == activity_id
    end)
  end

  defp convert_activity_to_scheduled(original_activity, entities, resources, index) do
    duration_val = Map.get(original_activity, :duration)
    {_duration_sec, fixed_start, fixed_end, _duration_str} = parse_duration_info(duration_val)

    required_capabilities = Map.get(original_activity, :required_capabilities, [])
    required_resources = Map.get(original_activity, :required_resources, [])

    # Assign entities and resources with improved logic
    assigned_entity = assign_entity_for_activity(original_activity, entities)
    assigned_resources = assign_resources_for_activity(original_activity, resources)

    # Get the first required resource for compatibility with JSON generator
    primary_resource =
      case required_resources do
        [first_resource | _] -> first_resource
        [] -> nil
      end

    # Compute timing and output duration correctly for both ISO8601 and DateTime interval
    {output_duration, timing_seconds} = compute_output_duration(duration_val)

    Map.merge(original_activity, %{
      start_time: fixed_start || index * timing_seconds,
      end_time: fixed_end || if(fixed_start, do: fixed_end, else: (index + 1) * timing_seconds),
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
  end

  defp parse_duration_info(duration_val) do
    cond do
      is_datetime_interval_with_atoms?(duration_val) ->
        parse_datetime_interval_atoms(duration_val)

      is_datetime_interval_with_strings?(duration_val) ->
        parse_datetime_interval_strings(duration_val)

      is_binary(duration_val) ->
        parse_iso8601_duration(duration_val)

      is_map(duration_val) ->
        parse_duration_struct(duration_val)

      true ->
        {0, nil, nil, "PT0S"}
    end
  end

  defp is_datetime_interval_with_atoms?(duration_val) do
    is_map(duration_val) and Map.has_key?(duration_val, :start) and
      Map.has_key?(duration_val, :end)
  end

  defp is_datetime_interval_with_strings?(duration_val) do
    is_map(duration_val) and Map.has_key?(duration_val, "start") and
      Map.has_key?(duration_val, "end")
  end

  defp parse_datetime_interval_atoms(duration_val) do
    start_time = duration_val[:start]
    end_time = duration_val[:end]

    case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
      {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
        {DateTime.diff(end_dt, start_dt), start_time, end_time,
         %{start: start_time, end: end_time}}

      _ ->
        {0, start_time, end_time, %{start: start_time, end: end_time}}
    end
  end

  defp parse_datetime_interval_strings(duration_val) do
    start_time = duration_val["start"]
    end_time = duration_val["end"]

    case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
      {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
        {DateTime.diff(end_dt, start_dt), start_time, end_time,
         %{start: start_time, end: end_time}}

      _ ->
        {0, start_time, end_time, %{start: start_time, end: end_time}}
    end
  end

  defp parse_iso8601_duration(duration_val) do
    case :iso8601.parse_duration(String.to_charlist(duration_val)) do
      parsed when is_list(parsed) ->
        map = Enum.into(parsed, %{})
        total_seconds = (map[:hours] || 0) * 3600 + (map[:minutes] || 0) * 60 + (map[:seconds] || 0)

        if total_seconds < 0 do
          {0, nil, nil, duration_val}
        else
          {AriaEngine.Utils.duration_struct_to_seconds(map), nil, nil, duration_val}
        end

      _ ->
        {0, nil, nil, duration_val}
    end
  end

  defp parse_duration_struct(duration_val) do
    {AriaEngine.Utils.duration_struct_to_seconds(duration_val), nil, nil,
     AriaEngine.Utils.duration_to_string(duration_val)}
  end

  defp compute_output_duration(duration_val) do
    cond do
      is_datetime_interval_with_strings?(duration_val) ->
        compute_datetime_interval_strings(duration_val)

      is_datetime_interval_with_atoms?(duration_val) ->
        compute_datetime_interval_atoms(duration_val)

      is_binary(duration_val) ->
        compute_iso8601_output(duration_val)

      is_duration_struct?(duration_val) ->
        compute_duration_struct_output(duration_val)

      is_map(duration_val) ->
        compute_zero_duration_output()

      true ->
        {"PT0S", 0}
    end
  end

  defp is_duration_struct?(duration_val) do
    is_map(duration_val) and Map.has_key?(duration_val, :hours) and
      Map.has_key?(duration_val, :minutes) and Map.has_key?(duration_val, :seconds)
  end

  defp compute_datetime_interval_strings(duration_val) do
    start_time = duration_val["start"]
    end_time = duration_val["end"]

    case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
      {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
        {%{"start" => start_time, "end" => end_time}, DateTime.diff(end_dt, start_dt)}

      _ ->
        {%{"start" => start_time, "end" => end_time}, 0}
    end
  end

  defp compute_datetime_interval_atoms(duration_val) do
    start_time = duration_val[:start]
    end_time = duration_val[:end]

    case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
      {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
        {%{start: start_time, end: end_time}, DateTime.diff(end_dt, start_dt)}

      _ ->
        {%{start: start_time, end: end_time}, 0}
    end
  end

  defp compute_iso8601_output(duration_val) do
    parsed =
      case duration_val do
        "PT0S" ->
          %{hours: 0, minutes: 0, seconds: 0}

        _ ->
          case :iso8601.parse_duration(String.to_charlist(duration_val)) do
            parsed when is_list(parsed) -> Enum.into(parsed, %{})
            _ -> %{hours: 0, minutes: 0, seconds: 0}
          end
      end

    {AriaEngine.Utils.duration_to_string(parsed),
     AriaEngine.Utils.duration_struct_to_seconds(parsed)}
  end

  defp compute_duration_struct_output(duration_val) do
    {AriaEngine.Utils.duration_to_string(duration_val),
     AriaEngine.Utils.duration_struct_to_seconds(duration_val)}
  end

  defp compute_zero_duration_output do
    {AriaEngine.Utils.duration_to_string(%{hours: 0, minutes: 0, seconds: 0}), 0}
  end

  # (Removed: iterative timing constraint code, now handled by Timelines STN)
end
