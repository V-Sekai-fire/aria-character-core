# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN.Operations do
  @moduledoc """
  Core STN operations for interval and constraint management.

  This module handles the fundamental operations of Simple Temporal Networks:
  - Adding and removing intervals
  - Managing time points
  - Adding and updating constraints
  - Constraint intersection and validation
  """

  alias Timeline.Interval
  alias Timeline.Internal.STN

  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}

  @doc """
  Adds an interval to the STN with automatic unit conversion and LOD rescaling.

  This creates two time points (start and end) and adds the necessary
  temporal constraints. Then applies MiniZinc solver to maintain consistency.

  The interval's DateTime values are automatically converted to the STN's
  declared time units and rescaled according to the LOD level.
  """
  @spec add_interval(STN.t(), Interval.t()) :: STN.t()
  def add_interval(stn, interval) do
    start_point = "#{interval.id}_start"
    end_point = "#{interval.id}_end"

    duration =
      STN.Units.convert_datetime_duration_to_stn_units(
        interval.start_time,
        interval.end_time,
        stn.time_unit,
        stn.lod_level,
        stn.lod_resolution
      )

    # Ensure minimum duration of 1 STN unit
    duration = max(duration, 1)
    # Use exact duration constraint
    duration_constraint = {duration, duration}

    stn
    |> add_time_point(start_point)
    |> add_time_point(end_point)
    |> add_constraint(start_point, end_point, duration_constraint)
  end

  @doc """
  Updates an interval in the STN by removing the old one and adding the new one.
  """
  @spec update_interval(STN.t(), Interval.t()) :: STN.t()
  def update_interval(stn, interval) do
    stn |> remove_interval(interval.id) |> add_interval(interval)
  end

  @doc """
  Removes an interval from the STN.
  """
  @spec remove_interval(STN.t(), String.t()) :: STN.t()
  def remove_interval(stn, interval_id) do
    start_point = "#{interval_id}_start"
    end_point = "#{interval_id}_end"

    updated_constraints =
      stn.constraints
      |> Enum.reject(fn {{from, to}, _} ->
        from == start_point or to == start_point or from == end_point or to == end_point
      end)
      |> Map.new()

    updated_time_points =
      stn.time_points |> MapSet.delete(start_point) |> MapSet.delete(end_point)

    %{stn | time_points: updated_time_points, constraints: updated_constraints}
  end

  @doc """
  Adds a temporal constraint between two time points.

  The constraint represents the allowable distance between the time points
  as {min_distance, max_distance}. Supports :infinity for unbounded constraints.
  """
  @spec add_constraint(STN.t(), time_point(), time_point(), constraint()) :: STN.t()
  def add_constraint(stn, from_point, to_point, {min_dist, max_dist} = constraint)
      when (is_number(min_dist) or min_dist == :neg_infinity) and
             (is_number(max_dist) or max_dist == :infinity) do
    unless valid_constraint_bounds?(min_dist, max_dist) do
      raise ArgumentError, "Invalid constraint bounds: #{inspect(constraint)}"
    end

    stn = stn |> add_time_point(from_point) |> add_time_point(to_point)
    current_constraints = stn.constraints
    is_consistent = stn.consistent

    {updated_constraints_1, consistent_1} =
      update_single_constraint(current_constraints, {from_point, to_point}, constraint)

    reverse_constraint = {negate_constraint_value(max_dist), negate_constraint_value(min_dist)}

    {updated_constraints_2, consistent_2} =
      update_single_constraint(updated_constraints_1, {to_point, from_point}, reverse_constraint)

    final_consistent = is_consistent and consistent_1 and consistent_2

    # Debug logging
    if not final_consistent do
      require Logger

      Logger.debug(
        "Constraint inconsistency detected: #{from_point} -> #{to_point} #{inspect(constraint)}"
      )

      Logger.debug(
        "Initial consistent: #{is_consistent}, step1: #{consistent_1}, step2: #{consistent_2}"
      )

      Logger.debug("Reverse constraint: #{inspect(reverse_constraint)}")
    end

    updated_stn = %{stn | constraints: updated_constraints_2, consistent: final_consistent}
    updated_stn
  end

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
    # No self-constraint needed - distance from point to itself is implicitly zero
    %{stn | time_points: updated_time_points}
  end

  @doc """
  Gets all time points in the STN.
  """
  @spec time_points(STN.t()) :: [time_point()]
  def time_points(stn) do
    MapSet.to_list(stn.time_points)
  end

  # Private helper functions

  defp valid_constraint_bounds?(min_dist, max_dist) do
    case {min_dist, max_dist} do
      {:neg_infinity, :infinity} ->
        true

      {:neg_infinity, max_dist} when is_number(max_dist) ->
        true

      {min_dist, :infinity} when is_number(min_dist) ->
        true

      {min_dist, max_dist} when is_number(min_dist) and is_number(max_dist) ->
        min_dist <= max_dist

      _ ->
        false
    end
  end

  defp intersect_constraints({min1, max1}, {min2, max2}) do
    new_min = constraint_max(min1, min2)
    new_max = constraint_min(max1, max2)

    # Check for inconsistency: new_min > new_max means no valid intersection
    if constraint_greater_than?(new_min, new_max) do
      :inconsistent
    else
      {new_min, new_max}
    end
  end

  defp constraint_max(:neg_infinity, other) do
    other
  end

  defp constraint_max(other, :neg_infinity) do
    other
  end

  defp constraint_max(:infinity, _) do
    :infinity
  end

  defp constraint_max(_, :infinity) do
    :infinity
  end

  defp constraint_max(a, b) when is_number(a) and is_number(b) do
    max(a, b)
  end

  defp constraint_min(:infinity, other) do
    other
  end

  defp constraint_min(other, :infinity) do
    other
  end

  defp constraint_min(:neg_infinity, _) do
    :neg_infinity
  end

  defp constraint_min(_, :neg_infinity) do
    :neg_infinity
  end

  defp constraint_min(a, b) when is_number(a) and is_number(b) do
    min(a, b)
  end

  defp constraint_greater_than?(:infinity, _) do
    false
  end

  defp constraint_greater_than?(_, :neg_infinity) do
    false
  end

  defp constraint_greater_than?(:neg_infinity, _) do
    true
  end

  defp constraint_greater_than?(_, :infinity) do
    true
  end

  defp constraint_greater_than?(a, b) when is_number(a) and is_number(b) do
    a > b
  end

  defp negate_constraint_value(:infinity) do
    :neg_infinity
  end

  defp negate_constraint_value(:neg_infinity) do
    :infinity
  end

  defp negate_constraint_value(value) when is_number(value) do
    -value
  end

  defp update_single_constraint(constraints, key, new_constraint) do
    case Map.get(constraints, key) do
      nil ->
        {Map.put(constraints, key, new_constraint), true}

      existing_constraint ->
        case intersect_constraints(existing_constraint, new_constraint) do
          :inconsistent ->
            {constraints, false}

          intersected_constraint ->
            {Map.put(constraints, key, intersected_constraint), true}
        end
    end
  end
end
