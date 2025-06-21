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
    Logger.debug("Converting plan to enhanced schedule")
    
    # Handle both EncapsulatedPlan struct and raw plan maps
    internal_plan = case encapsulated_plan do
      %{__struct__: HybridPlanner.DataStructures.EncapsulatedPlan} ->
        # It's a struct, use the proper API
        HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      
      %{nodes: _, root_id: _} ->
        # It's a raw plan map, use it directly
        Logger.debug("Using raw plan map directly")
        encapsulated_plan
        
      _ ->
        # Check if it has __struct__ key but is not the expected struct
        if Map.has_key?(encapsulated_plan, :__struct__) do
          Logger.error("Unknown struct type: #{inspect(encapsulated_plan.__struct__)}")
          raise "Unknown plan struct type: #{inspect(encapsulated_plan.__struct__)}"
        else
          Logger.error("Unknown plan format: #{inspect(encapsulated_plan)}")
          raise "Unknown plan format: #{inspect(encapsulated_plan)}"
        end
    end

    Logger.debug("Internal plan structure - keys: #{inspect(Map.keys(internal_plan))}")
    
    # Work directly with the solution tree structure instead of extracting primitive actions
    case internal_plan do
      %{nodes: nodes, root_id: root_id} ->
        # Convert solution tree to scheduled activities by traversing primitive nodes
        scheduled_activities = convert_solution_tree_to_scheduled_activities(
          nodes, 
          root_id, 
          activities, 
          entities, 
          resources
        )
        
        Logger.debug("Generated #{length(scheduled_activities)} scheduled activities")

        # Fix timing to respect dependencies
        case fix_timing_constraints(scheduled_activities, activities, base_datetime) do
          {:ok, scheduled_activities_with_proper_timing} ->
            scheduled_activities_with_proper_timing

          {:error, reason} ->
            raise "Failed to fix timing constraints: #{inspect(reason)}"
        end
        
      _ ->
        Logger.error("Unexpected internal plan format: #{inspect(internal_plan)}")
        raise "Unexpected internal plan format"
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
  Fix timing constraints to respect dependencies using Allen Relations and Timeline API.

  Uses Allen's Interval Algebra to properly express dependency relationships,
  then applies them as STN constraints through the Timeline API.
  
  Requires explicit base datetime to ensure deterministic scheduling behavior.
  Returns {:ok, activities} on success or {:error, reason} on failure.
  """
  def fix_timing_constraints(scheduled_activities, original_activities, base_datetime) do
    case validate_base_datetime(base_datetime) do
      {:ok, validated_datetime} ->
        do_fix_timing_constraints_with_allen_relations(scheduled_activities, original_activities, validated_datetime)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_base_datetime(nil), do: {:error, :missing_base_datetime}
  defp validate_base_datetime(%DateTime{} = dt), do: {:ok, dt}
  defp validate_base_datetime(_), do: {:error, :invalid_base_datetime}

  defp do_fix_timing_constraints_with_allen_relations(scheduled_activities, _original_activities, base_datetime) do
    require Logger
    
    Logger.error("🔧 PlanConverter: STARTING Allen Relations for dependency constraints")
    Logger.error("🔧 PlanConverter: Processing #{length(scheduled_activities)} activities")
    
    # Build Timeline.Interval structs with proper IDs
    {intervals, activity_id_map} = build_intervals_with_dependencies(scheduled_activities, base_datetime)
    
    Logger.error("🔧 PlanConverter: Created #{length(intervals)} intervals")
    
    # Create Timeline and add intervals
    timeline = Timeline.new()
    timeline_with_intervals = Enum.reduce(intervals, timeline, fn interval, acc_timeline ->
      Timeline.add_interval(acc_timeline, interval)
    end)
    
    Logger.error("🔧 PlanConverter: Added intervals to Timeline")
    
    # Apply Allen Relations as STN constraints
    timeline_with_constraints = apply_allen_dependency_constraints(
      timeline_with_intervals, 
      scheduled_activities, 
      activity_id_map
    )
    
    Logger.error("🔧 PlanConverter: Applied dependency constraints, solving Timeline...")
    
    # Solve Timeline for consistent timing
    solved_timeline = Timeline.solve(timeline_with_constraints)
    
    Logger.error("🔧 PlanConverter: Timeline solved, extracting timing information")
    
    # Extract timing and update activities
    result = extract_timing_from_solved_timeline(scheduled_activities, solved_timeline, activity_id_map)
    
    Logger.error("🔧 PlanConverter: COMPLETED Allen Relations processing")
    
    result
  end

  defp build_intervals_with_dependencies(scheduled_activities, base_datetime) do
    intervals_and_ids = 
      Enum.with_index(scheduled_activities)
      |> Enum.map(fn {activity, index} ->
        # Parse duration to get seconds
        duration_seconds = parse_activity_duration(activity)
        
        # Create start and end times (initially sequential, will be adjusted by Timeline)
        start_time = DateTime.add(base_datetime, index * 60, :second)
        end_time = DateTime.add(start_time, duration_seconds, :second)

        # Get activity ID
        activity_id = get_activity_id(activity)
        
        # Get dependencies
        dependencies = get_activity_dependencies(activity)
        
        # Create Timeline.Interval struct with explicit ID
        interval = Timeline.Interval.new(start_time, end_time,
          metadata: %{
            id: activity_id,
            dependencies: dependencies,
            original_activity: activity
          }
        )
        
        # Override the generated ID with our activity ID for STN constraint naming
        interval_with_id = %{interval | id: activity_id}
        
        {interval_with_id, activity_id}
      end)
    
    intervals = Enum.map(intervals_and_ids, fn {interval, _id} -> interval end)
    activity_id_map = Enum.into(intervals_and_ids, %{}, fn {interval, id} -> {id, interval} end)
    
    {intervals, activity_id_map}
  end

  defp apply_allen_dependency_constraints(timeline, scheduled_activities, activity_id_map) do
    require Logger
    
    # Debug: Log all available time points in the timeline
    time_points = Timeline.time_points(timeline)
    Logger.error("🔧 PlanConverter: Available time points in Timeline: #{inspect(time_points)}")
    
    # Debug: Log all activity IDs in the map
    activity_ids = Map.keys(activity_id_map)
    Logger.error("🔧 PlanConverter: Activity IDs in map: #{inspect(activity_ids)}")
    
    result_timeline = Enum.reduce(scheduled_activities, timeline, fn activity, acc_timeline ->
      dependencies = get_activity_dependencies(activity)
      activity_id = get_activity_id(activity)
      
      Logger.error("🔧 PlanConverter: Processing activity #{activity_id} with dependencies: #{inspect(dependencies)}")
      
      Enum.reduce(dependencies, acc_timeline, fn dep_id, inner_timeline ->
        # Get the intervals for dependency and current activity
        dep_interval = Map.get(activity_id_map, dep_id)
        activity_interval = Map.get(activity_id_map, activity_id)
        
        if dep_interval && activity_interval do
          # Apply Allen "before" relation: dependency must finish before activity starts
          # This translates to: dep_end <= activity_start with gap {0, 0} (immediate succession)
          dep_end_point = "#{dep_id}_end"
          activity_start_point = "#{activity_id}_start"
          
          Logger.error("🔧 PlanConverter: Applying Allen 'before' relation: #{dep_id} before #{activity_id}")
          Logger.error("🔧 PlanConverter: Constraint: #{dep_end_point} <= #{activity_start_point} with gap {0, 0}")
          
          # Check if the time points exist
          current_time_points = Timeline.time_points(inner_timeline)
          if dep_end_point in current_time_points and activity_start_point in current_time_points do
            Logger.error("🔧 PlanConverter: Time points exist, adding constraint")
            
            # Add the constraint and log the result
            # Use 10 seconds worth of STN units based on timeline's STN LOD resolution
            max_gap = 10 * inner_timeline.stn.lod_resolution
            constrained_timeline = Timeline.add_constraint(
              inner_timeline,
              dep_end_point,
              activity_start_point,
              {0, max_gap}  # Allen "before" relation: 0 to 10 second gap between dependency end and activity start
            )
            
            # Check if constraint was added successfully
            constraint_check = Timeline.get_constraint(constrained_timeline, dep_end_point, activity_start_point)
            Logger.error("🔧 PlanConverter: Constraint added successfully: #{inspect(constraint_check)}")
            
            constrained_timeline
          else
            Logger.error("🔧 PlanConverter: Missing time points - dep_end: #{dep_end_point in current_time_points}, activity_start: #{activity_start_point in current_time_points}")
            Logger.error("🔧 PlanConverter: Available points: #{inspect(current_time_points)}")
            inner_timeline
          end
        else
          Logger.error("🔧 PlanConverter: Missing interval for dependency #{dep_id} -> #{activity_id}")
          inner_timeline
        end
      end)
    end)
    
    # Log final constraint state
    final_time_points = Timeline.time_points(result_timeline)
    Logger.error("🔧 PlanConverter: Final timeline has #{length(final_time_points)} time points")
    
    result_timeline
  end

  defp extract_timing_from_solved_timeline(scheduled_activities, solved_timeline, _activity_id_map) do
    # Build duration map for preserving original durations
    duration_map = build_duration_map(scheduled_activities)
    
    # Extract timing from solved intervals
    time_map = 
      solved_timeline.intervals
      |> Enum.into(%{}, fn {interval_id, interval} ->
        # The interval_id should match our activity_id since we set it explicitly
        activity_id = interval_id
        start_time = interval.start_time
        
        # Calculate end_time based on start_time + duration to ensure duration is respected
        duration_seconds = Map.get(duration_map, activity_id, 0)
        end_time = Timex.add(start_time, Timex.Duration.from_seconds(duration_seconds))
        
        {activity_id, {start_time, end_time}}
      end)

    # Update scheduled_activities with computed times
    updated_activities =
      Enum.map(scheduled_activities, fn activity ->
        activity_id = get_activity_id(activity)
        
        case Map.get(time_map, activity_id) do
          {start_time, end_time} when not is_nil(start_time) and not is_nil(end_time) ->
            # Convert DateTime objects to ISO strings
            start_iso = DateTime.to_iso8601(start_time)
            end_iso = DateTime.to_iso8601(end_time)

            Map.put(activity, :start_time, start_iso)
            |> Map.put(:end_time, end_iso)

          _ ->
            # This should not happen with proper Allen Relations, but provide fallback
            require Logger
            Logger.error("🔧 PlanConverter: No timing found for activity #{activity_id}")
            
            # Use base datetime as fallback
            base_datetime = DateTime.utc_now()
            base_iso = DateTime.to_iso8601(base_datetime)
            Map.put(activity, :start_time, base_iso)
            |> Map.put(:end_time, base_iso)
        end
      end)

    {:ok, updated_activities}
  end

  # Helper functions for activity data extraction
  
  defp get_activity_id(activity) do
    if is_map(activity) and Map.has_key?(activity, "id") do
      Map.get(activity, "id")
    else
      Map.get(activity, :id)
    end
  end
  
  defp get_activity_dependencies(activity) do
    if Map.has_key?(activity, "dependencies") do
      Map.get(activity, "dependencies", [])
    else
      Map.get(activity, :dependencies, [])
    end
  end
  
  defp parse_activity_duration(activity) do
    duration_val = Map.get(activity, :duration) || Map.get(activity, "duration", "PT0S")
    
    case duration_val do
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
  end
  
  defp build_duration_map(scheduled_activities) do
    Enum.into(scheduled_activities, %{}, fn activity ->
      activity_id = get_activity_id(activity)
      duration_seconds = parse_activity_duration(activity)
      {activity_id, duration_seconds}
    end)
  end

  # Convert solution tree to scheduled activities by traversing primitive nodes directly.
  # This replaces the primitive actions extraction approach with direct tree traversal.
  defp convert_solution_tree_to_scheduled_activities(nodes, root_id, activities, entities, resources) do
    Logger.debug("Converting solution tree with #{map_size(nodes)} nodes, root: #{root_id}")
    
    # Find all primitive nodes (is_primitive: true) and sort them by their position in the tree
    primitive_nodes = 
      nodes
      |> Enum.filter(fn {_id, node} -> 
        Map.get(node, :is_primitive, false) == true 
      end)
      |> Enum.map(fn {_id, node} -> node end)
      |> Enum.sort_by(fn node -> Map.get(node, :id, "") end)  # Sort for consistent ordering
    
    Logger.debug("Found #{length(primitive_nodes)} primitive nodes")
    
    # Convert each primitive node to a scheduled activity
    primitive_nodes
    |> Enum.with_index()
    |> Enum.map(fn {node, index} ->
      task = Map.get(node, :task)
      Logger.debug("Processing primitive node #{index}: #{inspect(task)}")
      
      activity_id = extract_activity_id_from_task(task, index)
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
  end

  # Extract activity ID from a task (used for solution tree traversal).
  defp extract_activity_id_from_task(task, index) do
    Logger.debug("Extracting activity ID from task: #{inspect(task)}, index: #{index}")
    
    result = case task do
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
        Logger.warning("Task is nil at index #{index}")
        "unknown_action_#{index}"

      other ->
        Logger.warning("Unexpected task format: #{inspect(other)}")
        "unknown_action_#{index}"
    end
    
    Logger.debug("Extracted activity ID: #{inspect(result)}")
    result
  end

  # Private helper functions for duration parsing and activity conversion


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
    # Handle both string and atom keys for duration
    duration_val = Map.get(original_activity, :duration) || Map.get(original_activity, "duration")
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

    # Preserve the original duration instead of converting it
    # This ensures ISO 8601 durations like "PT2S" are maintained
    preserved_duration = duration_val || "PT0S"

    Map.merge(original_activity, %{
      start_time: fixed_start || index * 60,  # Default 1 minute spacing
      end_time: fixed_end || if(fixed_start, do: fixed_end, else: (index + 1) * 60),
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
      duration: preserved_duration  # Keep original ISO 8601 format
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


  # (Removed: iterative timing constraint code, now handled by Timelines STN)
end
