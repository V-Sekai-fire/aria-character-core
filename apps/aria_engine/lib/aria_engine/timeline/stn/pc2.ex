# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.STN.PC2 do
  @moduledoc false # This module is part of the internal STN implementation

  alias AriaEngine.Timeline.STN

  @type time_point :: String.t()
  @type constraint :: {number(), number()}
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}

  @doc """
  Applies the Path Consistency (PC-2) algorithm to maintain consistency.

  This is the core algorithm that ensures all temporal constraints are
  consistent with each other. It implements the O(n³) PC-2 algorithm.
  """
  @spec apply_pc2(STN.t()) :: STN.t()
  def apply_pc2(stn) do
    time_points = MapSet.to_list(stn.time_points)
    
    # Apply Floyd-Warshall-like algorithm for path consistency
    {updated_constraints, is_consistent} = 
      apply_pc2_iterations(time_points, stn.constraints)
    
    %{stn | constraints: updated_constraints, consistent: is_consistent}
  end

  # Core PC-2 algorithm implementation
  defp apply_pc2_iterations(time_points, constraints) do
    _n = length(time_points)
    
    # Initialize with existing constraints and zero self-constraints
    initial_constraints = initialize_constraints(time_points, constraints)
    
    # First check for direct cycle inconsistencies (critical for 2-point networks)
    case check_direct_cycle_consistency(time_points, initial_constraints) do
      :inconsistent ->
        {initial_constraints, false}
      
      :consistent ->
        # Apply three nested loops for path consistency (Floyd-Warshall style)
        {final_constraints, consistent} = 
          Enum.reduce_while(time_points, {initial_constraints, true}, fn k, {acc_constraints, acc_consistent} ->
            if not acc_consistent do
              {:halt, {acc_constraints, false}}
            else
              case apply_pc2_with_intermediate(time_points, acc_constraints, k) do
                {new_constraints, new_consistent} ->
                  {:cont, {new_constraints, new_consistent}}
              end
            end
          end)
        
    # Final check for consistency after all iterations
    final_consistent = Enum.all?(Map.values(final_constraints), fn {min, max} -> min <= max end)
    
    # NEW: Check for self-loop consistency (d(i,i) must be {0,0})
    self_loop_consistent = Enum.all?(time_points, fn tp ->
      Map.get(final_constraints, {tp, tp}) == {0, 0}
    end)

    {final_constraints, consistent and final_consistent and self_loop_consistent}
    end
  end

  defp check_direct_cycle_consistency(time_points, constraints) do
    # Check all pairs of time points for direct cycle inconsistencies
    Enum.reduce_while(time_points, :consistent, fn i, _acc ->
      result = Enum.reduce_while(time_points, :consistent, fn j, _inner_acc ->
        if i == j do
          {:cont, :consistent}
        else
          # Check if direct cycle i -> j -> i is inconsistent
          ij_constraint = Map.get(constraints, {i, j})
          ji_constraint = Map.get(constraints, {j, i})
          
          if ij_constraint && ji_constraint do
            case check_cycle_consistency(ij_constraint, ji_constraint) do
              :inconsistent -> {:halt, :inconsistent}
              :consistent -> {:cont, :consistent}
            end
          else
            {:cont, :consistent}
          end
        end
      end)
      
      case result do
        :inconsistent -> {:halt, :inconsistent}
        :consistent -> {:cont, :consistent}
      end
    end)
  end

  defp check_cycle_consistency({min1, max1}, {min2, max2}) do
    cycle_min = min1 + min2
    cycle_max = max1 + max2
    
    if cycle_min > 0 or cycle_max < 0 do
      :inconsistent
    else
      :consistent
    end
  end

  defp initialize_constraints(time_points, existing_constraints) do
    infinity = 1.0e18 # Represents positive infinity
    neg_infinity = -1.0e18 # Represents negative infinity

    # Initialize all pairs to {neg_infinity, infinity}
    all_pairs_constraints = 
      Enum.reduce(time_points, %{}, fn i, acc_i ->
        Enum.reduce(time_points, acc_i, fn j, acc_j ->
          Map.put(acc_j, {i, j}, {neg_infinity, infinity})
        end)
      end)

    # Set self-loops to {0, 0}
    self_constraints = 
      Enum.reduce(time_points, %{}, fn point, acc ->
        Map.put(acc, {point, point}, {0, 0})
      end)
    
    # Merge existing constraints, self-constraints, and all_pairs_constraints
    # Existing constraints take precedence, then self-constraints, then all_pairs
    Map.merge(all_pairs_constraints, Map.merge(self_constraints, existing_constraints))
  end

  defp apply_pc2_with_intermediate(time_points, constraints, k) do
    Enum.reduce_while(time_points, {constraints, true}, fn i, {acc_constraints_i, acc_consistent_i} ->
      if not acc_consistent_i do
        {:halt, {acc_constraints_i, false}}
      else
        {final_constraints_j, final_consistent_j} =
          Enum.reduce_while(time_points, {acc_constraints_i, acc_consistent_i}, fn j, {acc_constraints_j, acc_consistent_j} ->
            if not acc_consistent_j do
              {:halt, {acc_constraints_j, false}}
            else
              case update_constraint_via_path(acc_constraints_j, i, j, k) do
                {:inconsistent} ->
                  {:halt, {acc_constraints_j, false}}
                {:ok, new_constraints} ->
                  {:cont, {new_constraints, true}}
              end
            end
          end)
        {:cont, {final_constraints_j, final_consistent_j}}
      end
    end)
  end

  defp update_constraint_via_path(constraints, i, j, k) do
    # Get existing direct constraint i -> j (default to no constraint if not exists)
    direct_constraint = Map.get(constraints, {i, j})

    # Get path constraint i -> k -> j
    ik_constraint = Map.get(constraints, {i, k})
    kj_constraint = Map.get(constraints, {k, j})

    # Skip if either path constraint is missing
    if is_nil(ik_constraint) or is_nil(kj_constraint) do
      {:ok, constraints}
    else
      path_constraint = compose_constraints(ik_constraint, kj_constraint)

      # Intersect direct and path constraints
      new_constraint =
        if is_nil(direct_constraint) do
          path_constraint
        else
          intersect_constraints(direct_constraint, path_constraint)
        end

      case new_constraint do
        :inconsistent ->
          {:inconsistent}

        constraint ->
          # Only update if the new constraint is tighter than the direct constraint
          updated_constraints =
            if constraint != direct_constraint do
              Map.put(constraints, {i, j}, constraint)
            else
              constraints
            end
          {:ok, updated_constraints}
      end
    end
  end

  defp compose_constraints({min1, max1}, {min2, max2}) do
    composed = {min1 + min2, max1 + max2}
    composed
  end

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
end
