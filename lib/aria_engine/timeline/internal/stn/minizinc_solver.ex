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
          {:ok, %{status: :success, solution: solution}} ->
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
      
      # Create dummy durations (all zero since we're solving for time points, not activities)
      durations = List.duplicate(0, length(time_points))
      
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

  defp update_stn_with_solution(stn, solution) do
    # MiniZinc found a solution, so the STN is consistent
    consistent = solution[:status] != "UNSATISFIABLE"
    
    # For now, we just update the consistency flag
    # In the future, we could use the solution to tighten constraints
    %{stn | consistent: consistent}
  end
end
