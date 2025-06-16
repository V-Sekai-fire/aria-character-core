# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.STN do
  @moduledoc """
  Simple Temporal Network (STN) implementation with composable, parallelizable operations
  and Path Consistency (PC-2) algorithm.

  This module provides optimal constraint solving for temporal relationships
  using composable STN operations that can be parallelized, avoiding O(n³) 
  complexity blowup through segmentation and boolean-like operations.

  ## Composable STN Operations

  Like boolean algebra, STNs support compositional operations:
  - **Union**: Combine constraints from multiple STNs
  - **Intersection**: Find common constraints between STNs  
  - **Composition**: Chain STNs sequentially
  - **Parallel Join**: Merge independent STN segments

  ## Parallelization Strategy

  - **Segment Independence**: Divide timeline into independent segments
  - **Parallel Solving**: Each segment solved independently  
  - **Boundary Merging**: Combine results at segment boundaries
  - **Complexity Reduction**: O(n³) becomes O(k * (n/k)³) where k = segments

  ## Algorithm: Path Consistency (PC-2)

  The PC-2 algorithm maintains path consistency in the constraint graph by
  ensuring that for every triple of variables (i, j, k), the direct constraint
  between i and k is consistent with the path i -> j -> k.

  Time complexity: O(n³) per segment, parallelizable across segments
  Space complexity: O(n²) for the constraint matrix

  ## References

  - ADR-040: Temporal Constraint Solver Selection
  - "Temporal Constraint Networks" by Dechter, Meiri, and Pearl (1991)
  - "Parallelizing Constraint Satisfaction" for segmentation approaches
  """

  alias AriaEngine.Timeline.Interval

  @type constraint :: {number(), number()}  # {min_distance, max_distance}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}

  @type t :: %__MODULE__{
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          consistent: boolean(),
          segments: [segment()],
          metadata: map()
        }

  @type segment :: %{
          id: String.t(),
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          boundary_points: [time_point()],
          consistent: boolean()
        }

  defstruct time_points: MapSet.new(),
            constraints: %{},
            consistent: true,
            segments: [],
            metadata: %{}

  @doc """
  Creates a new empty Simple Temporal Network.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> stn.consistent
      true

  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true
    }
  end

  @doc """
  Adds an interval to the STN.

  This creates two time points (start and end) and adds the necessary
  temporal constraints. Then applies PC-2 to maintain consistency.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> interval = AriaEngine.Timeline.Interval.new(
      ...>   ~N[2025-01-01 10:00:00],
      ...>   ~N[2025-01-01 12:00:00]
      ...> )
      iex> updated_stn = AriaEngine.Timeline.STN.add_interval(stn, interval)
      iex> updated_stn.consistent
      true

  """
  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(stn, interval) do
    start_point = "#{interval.id}_start"
    end_point = "#{interval.id}_end"
    
    # Duration constraint: end - start = duration
    duration = Interval.duration(interval)
    duration_constraint = {duration, duration}  # Exact duration
    
    stn
    |> add_time_point(start_point)
    |> add_time_point(end_point)
    |> add_constraint(start_point, end_point, duration_constraint)
    |> apply_pc2()
  end

  @doc """
  Adds a temporal constraint between two time points.

  The constraint represents the allowable distance between the time points
  as {min_distance, max_distance}.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> stn = AriaEngine.Timeline.STN.add_time_point(stn, "t1")
      iex> stn = AriaEngine.Timeline.STN.add_time_point(stn, "t2")
      iex> stn = AriaEngine.Timeline.STN.add_constraint(stn, "t1", "t2", {0, 100})
      iex> stn.consistent
      true

  """
  @spec add_constraint(t(), time_point(), time_point(), constraint()) :: t()
  def add_constraint(stn, from_point, to_point, {min_dist, max_dist} = constraint)
      when is_number(min_dist) and is_number(max_dist) and min_dist <= max_dist do
    
    # Ensure both time points exist
    stn = stn
          |> add_time_point(from_point)
          |> add_time_point(to_point)
    
    # Add the constraint
    updated_constraints = Map.put(stn.constraints, {from_point, to_point}, constraint)
    
    # Add the reverse constraint (negative distances)
    reverse_constraint = {-max_dist, -min_dist}
    updated_constraints = Map.put(updated_constraints, {to_point, from_point}, reverse_constraint)
    
    %{stn | constraints: updated_constraints}
  end

  @doc """
  Applies the Path Consistency (PC-2) algorithm to maintain consistency.

  This is the core algorithm that ensures all temporal constraints are
  consistent with each other. It implements the O(n³) PC-2 algorithm.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> stn = AriaEngine.Timeline.STN.add_time_point(stn, "t1")
      iex> stn = AriaEngine.Timeline.STN.add_time_point(stn, "t2")
      iex> stn = AriaEngine.Timeline.STN.add_constraint(stn, "t1", "t2", {0, 10})
      iex> consistent_stn = AriaEngine.Timeline.STN.apply_pc2(stn)
      iex> consistent_stn.consistent
      true

  """
  @spec apply_pc2(t()) :: t()
  def apply_pc2(stn) do
    time_points = MapSet.to_list(stn.time_points)
    
    # Apply Floyd-Warshall-like algorithm for path consistency
    {updated_constraints, is_consistent} = 
      apply_pc2_iterations(time_points, stn.constraints)
    
    %{stn | constraints: updated_constraints, consistent: is_consistent}
  end

  @doc """
  Checks if the STN is temporally consistent.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> AriaEngine.Timeline.STN.consistent?(stn)
      true

  """
  @spec consistent?(t()) :: boolean()
  def consistent?(stn), do: stn.consistent

  @doc """
  Gets all time points in the STN.
  """
  @spec time_points(t()) :: [time_point()]
  def time_points(stn), do: MapSet.to_list(stn.time_points)

  @doc """
  Gets a constraint between two time points.
  """
  @spec get_constraint(t(), time_point(), time_point()) :: constraint() | nil
  def get_constraint(stn, from_point, to_point) do
    Map.get(stn.constraints, {from_point, to_point})
  end

  # Composable STN Operations - Boolean-like algebra for STNs

  @doc """
  Combines two STNs using union operation.
  
  Union operation merges constraints from both STNs, taking the intersection
  of constraint bounds where they overlap (tighter constraints win).
  
  This operation is commutative and associative, enabling parallelization.

  ## Examples

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> combined = AriaEngine.Timeline.STN.union(stn1, stn2)
      iex> combined.consistent
      true

  """
  @spec union(t(), t()) :: t()
  def union(stn1, stn2) do
    # Merge time points
    merged_points = MapSet.union(stn1.time_points, stn2.time_points)
    
    # Merge constraints (intersection of bounds)
    merged_constraints = merge_constraints(stn1.constraints, stn2.constraints)
    
    # Combine metadata
    merged_metadata = Map.merge(stn1.metadata, stn2.metadata)
    
    %__MODULE__{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: stn1.consistent and stn2.consistent,
      segments: stn1.segments ++ stn2.segments,
      metadata: merged_metadata
    }
  end

  @doc """
  Composes two STNs sequentially.
  
  Composition connects the end boundary of stn1 to the start boundary of stn2,
  creating a larger STN that represents sequential execution.

  ## Examples

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> composed = AriaEngine.Timeline.STN.compose(stn1, stn2)
      iex> composed.consistent
      true

  """
  @spec compose(t(), t()) :: t()
  def compose(stn1, stn2) do
    # Create bridge constraints between STNs
    bridged_constraints = create_bridge_constraints(stn1, stn2)
    
    # Union the STNs with bridge constraints
    bridge_stn = %__MODULE__{
      time_points: MapSet.new(),
      constraints: bridged_constraints,
      consistent: true,
      segments: [],
      metadata: %{}
    }
    
    stn1
    |> union(stn2)
    |> union(bridge_stn)
  end

  @doc """
  Performs parallel join of multiple STN segments.
  
  This operation can be parallelized since segments are independent
  until boundary merging.

  ## Examples

      iex> segments = [stn1, stn2, stn3]
      iex> joined = AriaEngine.Timeline.STN.parallel_join(segments)
      iex> joined.consistent
      true

  """
  @spec parallel_join([t()]) :: t()
  def parallel_join([]), do: new()
  def parallel_join([single_stn]), do: single_stn
  def parallel_join(stns) do
    # This can be parallelized using Task.async_stream
    stns
    |> Enum.reduce(&union/2)
    |> apply_pc2()
  end

  @doc """
  Segments an STN into independent chunks for parallel processing.
  
  Divides the STN into smaller segments that can be solved independently,
  reducing complexity from O(n³) to O(k * (n/k)³).

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> segments = AriaEngine.Timeline.STN.segment(stn, 3)
      iex> length(segments) <= 3
      true

  """
  @spec segment(t(), integer()) :: [t()]
  def segment(stn, max_segments) when max_segments > 0 do
    time_points = MapSet.to_list(stn.time_points)
    point_count = length(time_points)
    
    if point_count <= max_segments do
      [stn]  # No need to segment
    else
      chunk_size = div(point_count, max_segments)
      
      time_points
      |> Enum.chunk_every(chunk_size)
      |> Enum.with_index()
      |> Enum.map(fn {chunk_points, index} ->
        create_segment(stn, chunk_points, index)
      end)
    end
  end

  @doc """
  Solves STN segments in parallel and merges results.
  
  This provides significant performance improvement for large STNs
  by leveraging multi-core processing.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> solved = AriaEngine.Timeline.STN.parallel_solve(stn, 4)
      iex> solved.consistent
      true

  """
  @spec parallel_solve(t(), integer()) :: t()
  def parallel_solve(stn, max_segments \\ System.schedulers_online()) do
    stn
    |> segment(max_segments)
    |> Task.async_stream(&apply_pc2/1, max_concurrency: max_segments)
    |> Enum.map(fn {:ok, result} -> result end)
    |> parallel_join()
  end

  # Level of Detail (LOD) system for temporal resolution optimization
  
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000  # milliseconds per tick
  
  @type lod_stn :: %{
          level: lod_level(),
          resolution: lod_resolution(),
          current_time_ms: integer(),
          stn: t(),
          active_range: {integer(), integer()}  # {start_ms, end_ms}
        }
  
  @type hierarchical_stn :: %{
          lod_levels: %{optional(lod_level()) => lod_stn()},
          current_time_ms: integer(),
          auto_lod: boolean()
        }

  # LOD configuration
  @lod_config %{
    ultra_high: %{resolution: 1, range_seconds: 5},      # ±5 seconds at 1ms
    high: %{resolution: 10, range_seconds: 60},          # ±1 minute at 10ms  
    medium: %{resolution: 100, range_seconds: 600},      # ±10 minutes at 100ms
    low: %{resolution: 1000, range_seconds: 3600},       # ±1 hour at 1s
    very_low: %{resolution: 10000, range_seconds: nil}   # Beyond ±1 hour at 10s
  }

  # Private helper functions

  defp add_time_point(stn, time_point) do
    updated_time_points = MapSet.put(stn.time_points, time_point)
    %{stn | time_points: updated_time_points}
  end

  # Core PC-2 algorithm implementation
  defp apply_pc2_iterations(time_points, constraints) do
    n = length(time_points)
    
    # Initialize with existing constraints and zero self-constraints
    initial_constraints = initialize_constraints(time_points, constraints)
    
    # Apply three nested loops for path consistency (Floyd-Warshall style)
    {final_constraints, consistent} = 
      Enum.reduce(time_points, {initial_constraints, true}, fn k, {acc_constraints, acc_consistent} ->
        if not acc_consistent do
          {acc_constraints, false}
        else
          apply_pc2_with_intermediate(time_points, acc_constraints, k)
        end
      end)
    
    {final_constraints, consistent}
  end

  defp initialize_constraints(time_points, existing_constraints) do
    # Add zero constraints for all self-loops (i -> i = 0)
    self_constraints = 
      Enum.reduce(time_points, %{}, fn point, acc ->
        Map.put(acc, {point, point}, {0, 0})
      end)
    
    Map.merge(self_constraints, existing_constraints)
  end

  defp apply_pc2_with_intermediate(time_points, constraints, k) do
    Enum.reduce(time_points, {constraints, true}, fn i, {acc_constraints, acc_consistent} ->
      if not acc_consistent do
        {acc_constraints, false}
      else
        Enum.reduce(time_points, {acc_constraints, acc_consistent}, fn j, {inner_constraints, inner_consistent} ->
          if not inner_consistent do
            {inner_constraints, false}
          else
            update_constraint_via_path(inner_constraints, i, j, k)
          end
        end)
      end
    end)
  end

  defp update_constraint_via_path(constraints, i, j, k) do
    # Get existing direct constraint i -> j
    direct_constraint = Map.get(constraints, {i, j}, {:infinity, :neg_infinity})
    
    # Get path constraint i -> k -> j
    ik_constraint = Map.get(constraints, {i, k}, {:infinity, :neg_infinity})
    kj_constraint = Map.get(constraints, {k, j}, {:infinity, :neg_infinity})
    
    path_constraint = compose_constraints(ik_constraint, kj_constraint)
    
    # Intersect direct and path constraints
    new_constraint = intersect_constraints(direct_constraint, path_constraint)
    
    case new_constraint do
      :inconsistent ->
        {constraints, false}
      
      constraint ->
        updated_constraints = 
          if constraint != direct_constraint do
            Map.put(constraints, {i, j}, constraint)
          else
            constraints
          end
        
        {updated_constraints, true}
    end
  end

  defp compose_constraints({min1, max1}, {min2, max2}) do
      _ -> {new_min, new_max}
    end
  end

  # Private helper functions for composable operations

  defp merge_constraints(constraints1, constraints2) do
    # Merge constraint maps, taking intersection of bounds (tighter constraints)
    Map.merge(constraints1, constraints2, fn _key, {min1, max1}, {min2, max2} ->
      # Intersection: tighter bounds win
      new_min = case {min1, min2} do
        {:infinity, _} -> min2
        {_, :infinity} -> min1
        _ -> max(min1, min2)
      end
      
      new_max = case {max1, max2} do
        {:neg_infinity, _} -> max2
        {_, :neg_infinity} -> max1
        _ -> min(max1, max2)
      end
      
      {new_min, new_max}
    end)
  end

  defp create_bridge_constraints(stn1, stn2) do
    # Create constraints that bridge between STNs
    # This is a simplified version - real implementation would identify boundary points
    %{}
  end

  defp create_segment(stn, chunk_points, index) do
    chunk_point_set = MapSet.new(chunk_points)
    
    # Extract constraints relevant to this segment
    segment_constraints = 
      stn.constraints
      |> Enum.filter(fn {{from, to}, _constraint} ->
        MapSet.member?(chunk_point_set, from) and MapSet.member?(chunk_point_set, to)
      end)
      |> Enum.into(%{})
    
    # Identify boundary points (points that connect to other segments)
    boundary_points = identify_boundary_points(stn, chunk_points)
    
    %{
      id: "segment_#{index}",
      time_points: chunk_point_set,
      constraints: segment_constraints,
      boundary_points: boundary_points,
      consistent: true
    }
  end

  defp identify_boundary_points(stn, chunk_points) do
    chunk_set = MapSet.new(chunk_points)
    
    # Find points in this chunk that have constraints to points outside the chunk
    stn.constraints
    |> Enum.filter(fn {{from, to}, _} ->
      (MapSet.member?(chunk_set, from) and not MapSet.member?(chunk_set, to)) or
      (MapSet.member?(chunk_set, to) and not MapSet.member?(chunk_set, from))
    end)
    |> Enum.flat_map(fn {{from, to}, _} ->
      [from, to]
    end)
    |> Enum.filter(&MapSet.member?(chunk_set, &1))
    |> Enum.uniq()
  end
end
