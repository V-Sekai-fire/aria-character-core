# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Internal.STN.MiniZincSolver do
  @moduledoc """
  MiniZinc-based STN solver that replaces the PC-2 algorithm.

  Converts STN constraints to MiniZinc format and uses the constraint solver
  to determine consistency and find solutions.
  """

  alias Timeline.Internal.STN
  alias AriaEngine.MiniZinc.Executor

  require Logger

  @doc """
  Solves an STN using MiniZinc constraint solver.

  Returns an updated STN with consistency information and potentially
  tightened constraints based on the MiniZinc solution.
  """
  @spec solve_stn(STN.t()) :: STN.t()
  def solve_stn(stn) do
    case convert_stn_to_minizinc(stn) do
      {:ok, template_vars} ->
        case Executor.exec("stn_temporal", template_vars: template_vars) do
          {:ok, %{status: :success, solution: solution, raw_output: _raw_output}} ->
            update_stn_with_solution(stn, solution)

          {:ok, %{status: :error}} ->
            %{stn | consistent: false}

          {:error, _reason} ->
            # Fall back to marking as inconsistent
            %{stn | consistent: false}
        end

      {:error, _reason} ->
        %{stn | consistent: false}
    end
  end

  @doc """
  Converts STN data structure to MiniZinc template variables.
  """
  @spec convert_stn_to_minizinc(STN.t()) :: {:ok, map()} | {:error, String.t()}
  def convert_stn_to_minizinc(stn) do
    time_points = MapSet.to_list(stn.time_points)

    if Enum.empty?(time_points) do
      {:error, "Empty STN - no time points to solve"}
    else
      # Create mapping from time point names to activity indices
      time_point_map =
        time_points
        |> Enum.with_index(1)
        |> Map.new(fn {point, index} -> {point, index} end)

      # Convert constraints to MiniZinc format
      constraints = convert_constraints(stn.constraints, time_point_map)

      # Extract durations from interval constraints (start->end with fixed duration)
      durations = extract_durations(stn.constraints, time_point_map)

      template_vars = %{
        num_activities: length(time_points),
        num_constraints: length(constraints),
        durations: durations,
        constraints: constraints,
        time_point_map: time_point_map
      }

      {:ok, template_vars}
    end
  end

  # Private functions

  defp convert_constraints(constraint_map, time_point_map) do
    constraint_map
    |> Enum.filter(fn {{from, to}, {min, max}} ->
      # Skip self-constraints and infinite constraints
      # Keep duration constraints and dependency constraints
      from != to and is_finite_constraint({min, max})
    end)
    |> Enum.map(fn {{from, to}, {min, max}} ->
      from_idx = Map.get(time_point_map, from)
      to_idx = Map.get(time_point_map, to)

      %{
        from_activity: from_idx,
        to_activity: to_idx,
        min_distance: round(min),
        max_distance: round(max)
      }
    end)
    |> Enum.filter(fn constraint ->
      # Ensure we have valid indices
      constraint.from_activity != nil and constraint.to_activity != nil
    end)
  end

  defp is_finite_constraint({min, max}) do
    # Check if constraint bounds are finite (not infinity)
    is_finite_number(min) and is_finite_number(max) and min <= max
  end

  defp is_finite_number(n) when is_number(n) do
    # Consider very large numbers as infinite
    abs(n) < 1.0e15
  end

  defp is_finite_number(_), do: false

  defp extract_durations(constraint_map, time_point_map) do
    # For each time point, try to find if it's a start point with a corresponding end point
    # and extract the duration from the constraint between them
    time_points = Map.keys(time_point_map)
    num_points = length(time_points)

    # Initialize all durations to 0
    durations = List.duplicate(0, num_points)

    # Look for start->end constraints that represent durations
    time_points
    |> Enum.reduce(durations, fn point, acc_durations ->
      case extract_duration_for_point(point, constraint_map, time_point_map) do
        nil ->
          acc_durations

        duration ->
          # Convert to 0-based index
          point_index = Map.get(time_point_map, point) - 1
          List.replace_at(acc_durations, point_index, duration)
      end
    end)
  end

  defp extract_duration_for_point(point, constraint_map, _time_point_map) do
    # Check if this is a start point (ends with "_start")
    if String.ends_with?(point, "_start") do
      # Find corresponding end point
      base_name = String.replace_suffix(point, "_start", "")
      end_point = base_name <> "_end"

      # Look for constraint from start to end
      case Map.get(constraint_map, {point, end_point}) do
        {min_duration, max_duration} when min_duration == max_duration ->
          # Fixed duration constraint
          round(min_duration)

        _ ->
          nil
      end
    else
      nil
    end
  end

  defp update_stn_with_solution(stn, solution) do
    # MiniZinc found a solution, so the STN is consistent
    consistent = solution[:status] != "UNSATISFIABLE"

    # Apply the solved start times back to the STN metadata for Timeline to use
    updated_stn = %{stn | consistent: consistent}

    if consistent and solution[:start_times] do
      # Store the solved start times in STN metadata for Timeline to apply
      solved_times = extract_solved_times(stn, solution)
      %{updated_stn | metadata: Map.put(updated_stn.metadata, :solved_times, solved_times)}
    else
      updated_stn
    end
  end

  defp extract_solved_times(stn, solution) do
    time_points = MapSet.to_list(stn.time_points)
    start_times = solution[:start_times] || []

    # Create mapping from time point names to activity indices
    time_point_map =
      time_points
      |> Enum.with_index(1)
      |> Map.new(fn {point, index} -> {point, index} end)

    # Create reverse mapping from indices to time point names
    index_to_point_map =
      time_point_map
      |> Enum.map(fn {point, index} -> {index, point} end)
      |> Map.new()

    # Map solved start times back to time point names
    start_times
    |> Enum.with_index(1)
    |> Enum.map(fn {start_time, index} ->
      case Map.get(index_to_point_map, index) do
        nil -> nil
        time_point -> {time_point, start_time}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end
end
