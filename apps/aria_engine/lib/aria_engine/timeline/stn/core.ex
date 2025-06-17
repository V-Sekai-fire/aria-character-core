defmodule AriaEngine.Timeline.STN.Core do
  @moduledoc false # This module is part of the internal STN implementation

  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.STN

  @type constraint :: {number(), number()}  # {min_distance, max_distance}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}

  @doc """
  Adds an interval to the STN with automatic unit conversion and LOD rescaling.

  This creates two time points (start and end) and adds the necessary
  temporal constraints. Then applies PC-2 to maintain consistency.
  
  The interval's DateTime values are automatically converted to the STN's
  declared time units and rescaled according to the LOD level.
  """
  @spec add_interval(STN.t(), Interval.t()) :: STN.t()
  def add_interval(stn, interval) do
    start_point = "#{interval.id}_start"
    end_point = "#{interval.id}_end"
    
    # Convert DateTime to STN units with LOD rescaling
    duration = STN.Units.convert_datetime_duration_to_stn_units(
      interval.start_time, 
      interval.end_time, 
      stn.time_unit,
      stn.lod_level,
      stn.lod_resolution
    )
    
    duration_constraint = {duration, duration}  # Exact duration
    
    stn
    |> add_time_point(start_point)
    |> add_time_point(end_point)
    |> add_constraint(start_point, end_point, duration_constraint)
    |> STN.PC2.apply_pc2()
  end

  @doc """
  Updates an interval in the STN by removing the old one and adding the new one.
  """
  @spec update_interval(STN.t(), Interval.t()) :: STN.t()
  def update_interval(stn, interval) do
    stn
    |> remove_interval(interval.id)
    |> add_interval(interval)
  end

  @doc """
  Removes an interval from the STN.
  """
  @spec remove_interval(STN.t(), String.t()) :: STN.t()
  def remove_interval(stn, interval_id) do
    start_point = "#{interval_id}_start"
    end_point = "#{interval_id}_end"
    
    # Remove constraints involving these time points
    updated_constraints = 
      stn.constraints
      |> Enum.reject(fn {{from, to}, _} -> 
           from == start_point or to == start_point or
           from == end_point or to == end_point
         end)
      |> Map.new()
    
    # Remove time points
    updated_time_points = 
      stn.time_points
      |> MapSet.delete(start_point)
      |> MapSet.delete(end_point)
    
    %{stn | 
      time_points: updated_time_points,
      constraints: updated_constraints
    }
    |> STN.PC2.apply_pc2()
  end

  @doc """
  Adds a durative action to the STN, creating time points for its start and end,
  and adding a duration constraint.
  """
  @spec add_durative_action(STN.t(), AriaEngine.Domain.DurativeAction.t()) :: STN.t()
  def add_durative_action(stn, durative_action) do
    start_point = "#{durative_action.name}_start"
    end_point = "#{durative_action.name}_end"

    duration_constraint = case durative_action.duration do
      {:fixed, duration} -> {duration, duration}
      {:range, min_duration, max_duration} -> {min_duration, max_duration}
    end
    
    stn
    |> add_time_point(start_point)
    |> add_time_point(end_point)
    |> add_constraint(start_point, end_point, duration_constraint)
    |> STN.PC2.apply_pc2()
  end

  @doc """
  Adds a temporal constraint between two time points.

  The constraint represents the allowable distance between the time points
  as {min_distance, max_distance}.
  """
  @spec add_constraint(STN.t(), time_point(), time_point(), constraint()) :: STN.t()
  def add_constraint(stn, from_point, to_point, {min_dist, max_dist} = constraint)
      when is_number(min_dist) and is_number(max_dist) and min_dist <= max_dist do
    
    # Ensure both time points exist
    stn = stn
          |> add_time_point(from_point)
          |> add_time_point(to_point)
    
    # Start with the current constraints and assume consistency
    current_constraints = stn.constraints
    is_consistent = stn.consistent

    # Update forward constraint
    {updated_constraints_1, consistent_1} = 
      update_single_constraint(current_constraints, {from_point, to_point}, constraint)

    # Update reverse constraint
    reverse_constraint = {-max_dist, -min_dist}
    {updated_constraints_2, consistent_2} = 
      update_single_constraint(updated_constraints_1, {to_point, from_point}, reverse_constraint)

    # Combine consistency flags - if ANY intersection fails, the whole STN is inconsistent
    final_consistent = is_consistent and consistent_1 and consistent_2

    # Create the updated STN with the final consistency state
    updated_stn = %{stn | constraints: updated_constraints_2, consistent: final_consistent}

    # Apply PC-2 only if still consistent, otherwise return the inconsistent STN
    if final_consistent do
      STN.PC2.apply_pc2(updated_stn)
    else
      updated_stn
    end
  end

  @doc """
  Checks if the STN is temporally consistent.
  """
  @spec consistent?(STN.t()) :: boolean()
  def consistent?(stn), do: stn.consistent

  @doc """
  Gets all time points in the STN.
  """
  @spec time_points(STN.t()) :: [time_point()]
  def time_points(stn), do: MapSet.to_list(stn.time_points)

  @doc """
  Gets a constraint between two time points.
  """
  @spec get_constraint(STN.t(), time_point(), time_point()) :: constraint() | nil
  def get_constraint(stn, from_point, to_point) do
    Map.get(stn.constraints, {from_point, to_point})
  end

  @doc """
  Adds a time point to the STN.
  """
  @spec add_time_point(STN.t(), time_point()) :: STN.t()
  def add_time_point(stn, time_point) do
    updated_time_points = MapSet.put(stn.time_points, time_point)
    
    # Add self-constraint for the new time point
    updated_constraints = Map.put(stn.constraints, {time_point, time_point}, {0, 0})
    
    %{stn | 
      time_points: updated_time_points,
      constraints: updated_constraints
    }
  end

  @doc """
  Gets all intervals currently stored in the STN.
  
  Returns a list of interval representations with their time bounds.
  Each interval is returned as %{id: interval_id, start_time: number, end_time: number, metadata: map}
  where times are in the STN's time units.
  """
  @spec get_intervals(STN.t()) :: [%{id: String.t(), start_time: number(), end_time: number(), metadata: map()}]
  def get_intervals(stn) do
    # Find interval pairs by looking for matching _start and _end time points
    stn.time_points
    |> MapSet.to_list()
    |> Enum.filter(&String.ends_with?(&1, "_start"))
    |> Enum.map(fn start_point ->
      interval_id = String.replace_suffix(start_point, "_start", "")
      end_point = "#{interval_id}_end"
      
      if MapSet.member?(stn.time_points, end_point) do
        # Extract time bounds from constraints
        case get_interval_bounds(stn, start_point, end_point) do
          {:ok, start_time, end_time} ->
            %{
              id: interval_id,
              start_time: start_time,
              end_time: end_time,
              metadata: Map.get(stn.metadata, interval_id, %{})
            }
          {:error, _} -> nil
        end
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Finds intervals that overlap with the given time range.
  
  Returns intervals that have any overlap with [query_start, query_end].
  Times should be in the same units as the STN.
  """
  @spec get_overlapping_intervals(STN.t(), number(), number()) :: [%{id: String.t(), start_time: number(), end_time: number(), metadata: map()}]
  def get_overlapping_intervals(stn, query_start, query_end) when query_start <= query_end do
    get_intervals(stn)
    |> Enum.filter(fn interval ->
      # Check for overlap: intervals overlap if start1 <= end2 and start2 <= end1
      interval.start_time <= query_end and query_start <= interval.end_time
    end)
  end

  @doc """
  Finds free time slots of the specified duration within the given time window.
  
  Returns a list of available slots as %{start_time: number, end_time: number}.
  Each slot has exactly the requested duration and fits within [window_start, window_end].
  """
  @spec find_free_slots(STN.t(), number(), number(), number()) :: [%{start_time: number(), end_time: number()}]
  def find_free_slots(stn, duration, window_start, window_end) 
      when duration > 0 and window_start <= window_end and (window_end - window_start) >= duration do
    
    # Get all intervals sorted by start time
    occupied_intervals = 
      get_intervals(stn)
      |> Enum.filter(fn interval ->
        # Only consider intervals that overlap with our search window
        interval.start_time <= window_end and window_start <= interval.end_time
      end)
      |> Enum.sort_by(& &1.start_time)
    
    # Find gaps between occupied intervals
    find_gaps_in_timeline(occupied_intervals, window_start, window_end, duration)
  end

  @doc """
  Checks if a new interval conflicts with existing intervals in the STN.
  
  Returns a list of conflicting intervals, or empty list if no conflicts.
  """
  @spec check_interval_conflicts(STN.t(), number(), number()) :: [%{id: String.t(), start_time: number(), end_time: number(), metadata: map()}]
  def check_interval_conflicts(stn, new_start, new_end) when new_start <= new_end do
    get_overlapping_intervals(stn, new_start, new_end)
  end

  @doc """
  Finds the next available time slot for the given duration after the specified start time.
  
  Returns {:ok, start_time, end_time} for the first available slot,
  or {:error, reason} if no slot is available within a reasonable search window.
  """
  @spec find_next_available_slot(STN.t(), number(), number()) :: {:ok, number(), number()} | {:error, atom()}
  def find_next_available_slot(stn, duration, earliest_start) when duration > 0 do
    # Search within a reasonable window (e.g., 30 days in STN time units)
    search_window = convert_to_stn_time_units(30 * 24 * 3600 * 1000, stn.time_unit)  # 30 days in milliseconds
    window_end = earliest_start + search_window
    
    case find_free_slots(stn, duration, earliest_start, window_end) do
      [] -> 
        {:error, :no_available_slot}
      [first_slot | _] ->
        {:ok, first_slot.start_time, first_slot.end_time}
    end
  end

  # Private helper functions
  defp intersect_constraints({min1, max1}, {min2, max2}) do
    new_min = max(min1, min2)
    new_max = min(max1, max2)

    # Check for inconsistency
    if new_min > new_max do
      :inconsistent
    else
      {new_min, new_max}
    end
  end

  # Helper function to update a single constraint
  defp update_single_constraint(constraints, key, new_constraint) do
    case Map.get(constraints, key) do
      nil ->
        {Map.put(constraints, key, new_constraint), true}
      existing_constraint ->
        case intersect_constraints(existing_constraint, new_constraint) do
          :inconsistent ->
            # When local intersection fails, add the new constraint anyway
            # PC2 will detect the global inconsistency through path consistency
            {Map.put(constraints, key, new_constraint), false}
          intersected_constraint ->
            {Map.put(constraints, key, intersected_constraint), true}
        end
    end
  end

  # Helper function to extract actual time bounds from STN constraints
  defp get_interval_bounds(stn, start_point, end_point) do
    # For intervals, we need to extract the absolute times from constraints
    # This is a simplified approach - in a full implementation, we'd solve for actual times
    case get_constraint(stn, start_point, end_point) do
      {duration, duration} when is_number(duration) ->
        # For now, assume start_time is 0 and calculate end_time from duration
        # In a real implementation, we'd need to solve the constraint network
        # to get absolute times or work with relative constraints
        {:ok, 0, duration}
      {min_duration, max_duration} when is_number(min_duration) and is_number(max_duration) ->
        # Use the average for approximate scheduling
        avg_duration = (min_duration + max_duration) / 2
        {:ok, 0, avg_duration}
      nil ->
        {:error, :no_constraint}
      _ ->
        {:error, :invalid_constraint}
    end
  end

  # Helper function to find gaps in timeline between occupied intervals
  defp find_gaps_in_timeline(occupied_intervals, window_start, window_end, required_duration) do
    # Sort intervals by start time and merge overlapping ones
    merged_intervals = merge_overlapping_intervals(occupied_intervals)
    
    # Find gaps between merged intervals
    gaps = []
    
    # Check gap before first interval
    gaps = case merged_intervals do
      [] -> 
        # Entire window is free
        if window_end - window_start >= required_duration do
          [%{start_time: window_start, end_time: window_start + required_duration}]
        else
          []
        end
      [first | _] ->
        if first.start_time > window_start and (first.start_time - window_start) >= required_duration do
          [%{start_time: window_start, end_time: window_start + required_duration} | gaps]
        else
          gaps
        end
    end
    
    # Check gaps between intervals
    gaps = Enum.reduce(Enum.zip(merged_intervals, Enum.drop(merged_intervals, 1)), gaps, fn {current, next}, acc ->
      gap_start = current.end_time
      gap_end = next.start_time
      gap_size = gap_end - gap_start
      
      if gap_size >= required_duration do
        slot = %{start_time: gap_start, end_time: gap_start + required_duration}
        [slot | acc]
      else
        acc
      end
    end)
    
    # Check gap after last interval
    gaps = case List.last(merged_intervals) do
      nil -> gaps  # Already handled empty case above
      last_interval ->
        if last_interval.end_time < window_end and (window_end - last_interval.end_time) >= required_duration do
          slot = %{start_time: last_interval.end_time, end_time: last_interval.end_time + required_duration}
          [slot | gaps]
        else
          gaps
        end
    end
    
    # Sort gaps by start time
    Enum.sort_by(gaps, & &1.start_time)
  end

  # Helper function to merge overlapping intervals
  defp merge_overlapping_intervals([]), do: []
  defp merge_overlapping_intervals(intervals) do
    sorted_intervals = Enum.sort_by(intervals, & &1.start_time)
    
    Enum.reduce(sorted_intervals, [], fn current, acc ->
      case acc do
        [] -> 
          [current]
        [last | rest] ->
          if current.start_time <= last.end_time do
            # Overlapping - merge them
            merged = %{last | end_time: max(last.end_time, current.end_time)}
            [merged | rest]
          else
            # No overlap - add current interval
            [current | acc]
          end
      end
    end)
    |> Enum.reverse()
  end

  # Helper function to convert time values to STN time units
  defp convert_to_stn_time_units(time_value_ms, target_unit) do
    case target_unit do
      :microsecond -> time_value_ms * 1000
      :millisecond -> time_value_ms
      :second -> div(time_value_ms, 1000)
      :minute -> div(time_value_ms, 60_000)
      :hour -> div(time_value_ms, 3_600_000)
      :day -> div(time_value_ms, 86_400_000)
      _ -> time_value_ms  # Default to milliseconds
    end
  end
end
