# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN.Consistency do
  @moduledoc """
  STN consistency validation and classification.

  This module handles:
  - Temporal consistency checking
  - Mathematical consistency validation
  - STN classification (simple vs complex)
  - Constraint validation helpers
  """

  alias Timeline.Internal.STN

  @type constraint :: {number(), number()}
  @type time_point :: String.t()

  @doc """
  Determines if an STN contains only simple constraints that don't require MiniZinc solving.

  Simple STNs contain only:
  1. Basic interval constraints with fixed durations
  2. Small range constraints (simple adjacency)
  3. Limited number of time points for performance

  These STNs can be handled efficiently with Elixir-side consistency checking
  without requiring complex temporal reasoning via MiniZinc.
  """
  @spec simple_stn?(STN.t()) :: boolean()
  def simple_stn?(stn) do
    # Limit to reasonable size for simple processing
    point_count = MapSet.size(stn.time_points)

    if point_count > 15 do
      false
    else
      # Check if all constraints are simple
      Enum.all?(stn.constraints, fn {{from, to}, {min, max}} ->
        is_simple_constraint?(from, to, min, max)
      end)
    end
  end

  @doc """
  Checks if the STN is temporally consistent.
  """
  @spec consistent?(STN.t() | {:error, :unsatisfiable}) :: boolean()
  def consistent?({:error, :unsatisfiable}), do: false

  def consistent?(stn) do
    stn.consistent
  end

  @doc """
  Validates mathematical consistency of STN constraints.

  An STN is mathematically consistent if:
  1. No constraint contradictions exist (min ≤ max)
  2. Bilateral constraints are mathematical inverses
  3. All bounds are mathematically sound
  """
  @spec mathematically_consistent?(STN.t()) :: boolean()
  def mathematically_consistent?(stn) do
    no_contradictions?(stn.constraints) and
      bilateral_consistency?(stn.constraints) and
      all_bounds_valid?(stn.constraints)
  end

  # Private helper functions

  defp is_simple_constraint?(from, to, min, max) do
    cond do
      # Fixed duration interval (simple)
      from != to and min == max and is_number(min) and min > 0 ->
        true

      # Small range constraint (simple adjacency)
      from != to and is_number(min) and is_number(max) and
        abs(max - min) <= 2 and min >= 0 ->
        true

      # Any other constraint type (complex - needs MiniZinc)
      true ->
        false
    end
  end

  # Mathematical consistency validation helpers

  defp no_contradictions?(constraints) do
    Enum.all?(constraints, fn {_key, {min, max}} ->
      # Basic mathematical constraint: min ≤ max
      valid_constraint_bounds?(min, max)
    end)
  end

  defp bilateral_consistency?(constraints) do
    Enum.all?(constraints, fn {{from, to}, {min, max}} ->
      case Map.get(constraints, {to, from}) do
        {rev_min, rev_max} ->
          # Reverse constraint must be mathematical inverse
          mathematically_inverse?(min, max, rev_min, rev_max)

        nil ->
          # Missing reverse constraint is acceptable for simple STNs
          true
      end
    end)
  end

  defp all_bounds_valid?(constraints) do
    Enum.all?(constraints, fn {_key, {min, max}} ->
      valid_numeric_bounds?(min, max)
    end)
  end

  defp mathematically_inverse?(min, max, rev_min, rev_max) do
    # For constraint A→B: {min, max}, reverse B→A should be {-max, -min}
    expected_rev_min = negate_constraint_value(max)
    expected_rev_max = negate_constraint_value(min)

    constraint_equal?(rev_min, expected_rev_min) and
      constraint_equal?(rev_max, expected_rev_max)
  end

  defp constraint_equal?(:infinity, :infinity), do: true
  defp constraint_equal?(:neg_infinity, :neg_infinity), do: true
  defp constraint_equal?(a, b) when is_number(a) and is_number(b), do: a == b
  defp constraint_equal?(_, _), do: false

  defp valid_numeric_bounds?(min, max) do
    case {min, max} do
      {a, b} when is_number(a) and is_number(b) -> a <= b
      {:neg_infinity, _} -> true
      {_, :infinity} -> true
      _ -> false
    end
  end

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

  defp negate_constraint_value(:infinity) do
    :neg_infinity
  end

  defp negate_constraint_value(:neg_infinity) do
    :infinity
  end

  defp negate_constraint_value(value) when is_number(value) do
    -value
  end
end
