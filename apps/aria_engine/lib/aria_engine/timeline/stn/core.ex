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
end
