# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.STN.Operations do
  @moduledoc false # This module is part of the internal STN implementation

  alias Timeline.STN
  alias Timeline.LodAdapter
  alias FlowAdapter

  @doc """
  Performs intersection operation on two STNs.
  """
  @spec intersection(STN.t(), STN.t()) :: STN.t()
  def intersection(stn1, stn2) do
    # Auto-rescale to compatible units and LOD if enabled
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    
    # Merge time points
    merged_points = MapSet.union(compatible_stn1.time_points, compatible_stn2.time_points)
    
    # Merge constraints (intersection of bounds - tighter constraints)
    merged_constraints = merge_constraints_intersection(compatible_stn1.constraints, compatible_stn2.constraints)
    
    %STN{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: compatible_stn1.consistent and compatible_stn2.consistent,
      segments: compatible_stn1.segments ++ compatible_stn2.segments,
      metadata: Map.merge(compatible_stn1.metadata, compatible_stn2.metadata),
      # Use compatible LOD settings
      time_unit: compatible_stn1.time_unit,
      lod_level: compatible_stn1.lod_level,
      lod_resolution: compatible_stn1.lod_resolution,
      auto_rescale: compatible_stn1.auto_rescale,
      datetime_conversion_unit: compatible_stn1.datetime_conversion_unit,
      max_timepoints: max(compatible_stn1.max_timepoints, compatible_stn2.max_timepoints),
      constant_work_enabled: compatible_stn1.constant_work_enabled or compatible_stn2.constant_work_enabled,
      dummy_constraints: Map.merge(compatible_stn1.dummy_constraints, compatible_stn2.dummy_constraints)
    }
    |> STN.PC2.apply_pc2()
  end

  @doc """
  Performs difference operation on two STNs.
  """
  @spec difference(STN.t(), STN.t()) :: STN.t()
  def difference(stn1, stn2) do
    # Auto-rescale to compatible units and LOD if enabled
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    
    # Keep time points from first STN, remove those in second
    merged_points = MapSet.difference(compatible_stn1.time_points, compatible_stn2.time_points)
    
    # For difference, we remove constraints that exist in stn2
    merged_constraints = merge_constraints_difference(compatible_stn1.constraints, compatible_stn2.constraints)
    
    %STN{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: compatible_stn1.consistent,
      segments: compatible_stn1.segments,
      metadata: compatible_stn1.metadata,
      # Use first STN's LOD settings
      time_unit: compatible_stn1.time_unit,
      lod_level: compatible_stn1.lod_level,
      lod_resolution: compatible_stn1.lod_resolution,
      auto_rescale: compatible_stn1.auto_rescale,
      datetime_conversion_unit: compatible_stn1.datetime_conversion_unit,
      max_timepoints: compatible_stn1.max_timepoints,
      constant_work_enabled: compatible_stn1.constant_work_enabled,
      dummy_constraints: compatible_stn1.dummy_constraints
    }
    |> STN.PC2.apply_pc2()
  end

  @doc """
  Splits an STN into multiple independent segments for parallel processing.
  """
  @spec split(STN.t(), pos_integer()) :: [STN.t()]
  def split(stn, num_segments), do: segment(stn, num_segments)

  @doc """
  Chains multiple STNs sequentially using temporal ordering constraints.
  """
  @spec chain([STN.t()]) :: STN.t()
  def chain([]), do: STN.new()
  def chain([single_stn]), do: single_stn
  def chain([first_stn | rest_stns]) do
    Enum.reduce(rest_stns, first_stn, fn stn, acc ->
      compose(acc, stn)
    end)
  end

  @doc """
  Bridge and compose STNs with different LOD levels using the LOD adapter.
  """
  @spec bridge_compose(STN.t(), STN.t(), :intersection | :union | :difference, keyword()) :: STN.t()
  def bridge_compose(%STN{} = stn1, %STN{} = stn2, operation, opts \\ [])
      when operation in [:intersection, :union, :difference] do
    
    # Check if we need Flow adapter for large operations
    total_constraints = map_size(stn1.constraints) + map_size(stn2.constraints)
    
    opts = 
      if total_constraints > 200 and not Keyword.has_key?(opts, :flow_config) do
        # Create Flow configuration for large operations
        {:ok, flow_config} = FlowAdapter.create_pipeline("stn_lod_bridge", 
          flow_control: :pull, 
          stages: System.schedulers_online(),
          demand_size: 10,
          convergence: true
        )
        Keyword.put(opts, :flow_config, flow_config)
      else
        opts
      end
    
    # Use LOD adapter for bridging and composition
    LodAdapter.bridge_and_compose(stn1, stn2, operation, opts)
  end

  @doc """
  Create a hierarchical chain of STNs across multiple LOD levels.
  """
  @spec lod_chain([STN.t()], keyword()) :: STN.t()
  def lod_chain(stns, opts \\ []) when is_list(stns) do
    case length(stns) do
      0 -> STN.new()
      1 -> hd(stns)
      _ -> 
        # Use LOD adapter for chaining
        LodAdapter.create_lod_chain(stns, :sequential, opts)
    end
  end

  @doc """
  Combines two STNs using union operation.
  """
  @spec union(STN.t(), STN.t()) :: STN.t()
  def union(stn1, stn2) do
    # Auto-rescale to compatible units and LOD if enabled
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    
    # Merge time points
    merged_points = MapSet.union(compatible_stn1.time_points, compatible_stn2.time_points)
    
    # Merge constraints (intersection of bounds)
    merged_constraints = merge_constraints_union(compatible_stn1.constraints, compatible_stn2.constraints)
    
    # Combine metadata
    merged_metadata = Map.merge(compatible_stn1.metadata, compatible_stn2.metadata)
    
    %STN{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: compatible_stn1.consistent and compatible_stn2.consistent,
      segments: compatible_stn1.segments ++ compatible_stn2.segments,
      metadata: merged_metadata,
      # Use the first STN's LOD settings as primary
      time_unit: compatible_stn1.time_unit,
      lod_level: compatible_stn1.lod_level,
      lod_resolution: compatible_stn1.lod_resolution,
      auto_rescale: compatible_stn1.auto_rescale,
      datetime_conversion_unit: compatible_stn1.datetime_conversion_unit,
      max_timepoints: max(compatible_stn1.max_timepoints, compatible_stn2.max_timepoints),
      constant_work_enabled: compatible_stn1.constant_work_enabled or compatible_stn2.constant_work_enabled,
      dummy_constraints: Map.merge(compatible_stn1.dummy_constraints, compatible_stn2.dummy_constraints)
    }
    |> STN.PC2.apply_pc2()
  end

  @doc """
  Composes two STNs sequentially.
  """
  @spec compose(STN.t(), STN.t()) :: STN.t()
  def compose(stn1, stn2) do
    # Create bridge constraints between STNs
    bridged_constraints = create_bridge_constraints(stn1, stn2)
    
    # Union the STNs with bridge constraints
    bridge_stn = %STN{
      time_points: MapSet.new(),
      constraints: bridged_constraints,
      consistent: true,
      segments: [],
      metadata: %{}
    }
    
    union(stn1, stn2)
    |> union(bridge_stn)
  end

  @doc """
  Performs parallel join of multiple STN segments.
  """
  @spec parallel_join([STN.t()]) :: STN.t()
  def parallel_join([]), do: STN.new()
  def parallel_join([single_stn]), do: single_stn
  def parallel_join(stns) do
    # Use Flow adapter for parallel processing of STN unions
    case length(stns) do
      count when count > 4 ->
        # Use Flow adapter for larger sets
        {:ok, flow_config} = FlowAdapter.create_pipeline("stn_parallel_join", 
          flow_control: :pull, 
          stages: System.schedulers_online(),
          demand_size: 2,
          convergence: true
        )
        
        _solved_segments = FlowAdapter.process_stn_compositions(flow_config,
          Enum.chunk_every(stns, 2, 2, [STN.new()]) |> Enum.map(&List.to_tuple/1),
          &union/2)
        |> Enum.reduce(&union/2)
        |> STN.PC2.apply_pc2()
      
      _ ->
        # Direct processing for small sets
        stns
        |> Enum.reduce(&union/2)
        |> STN.PC2.apply_pc2()
    end
  end

  @doc """
  Segments an STN into independent chunks for parallel processing.
  """
  @spec segment(STN.t(), pos_integer()) :: [STN.t()]
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

  defp create_segment(stn, chunk_points, _index) do
    time_points_set = MapSet.new(chunk_points)
    
    # Filter constraints relevant to this segment
    segment_constraints = 
      Enum.filter(stn.constraints, fn {{p1, p2}, _} ->
        MapSet.member?(time_points_set, p1) and MapSet.member?(time_points_set, p2)
      end) |> Map.new()
      
    %STN{
      time_points: time_points_set,
      constraints: segment_constraints,
      consistent: stn.consistent,
      time_unit: stn.time_unit,
      lod_level: stn.lod_level,
      lod_resolution: stn.lod_resolution
    }
  end

  @doc """
  Solves STN segments in parallel and merges results.
  """
  @spec parallel_solve(STN.t(), integer()) :: STN.t()
  def parallel_solve(stn, max_segments \\ System.schedulers_online()) do
    segments = segment(stn, max_segments)
    
    case length(segments) do
      1 -> 
        # Single segment, no need for parallel processing
        STN.PC2.apply_pc2(hd(segments))
      
      segment_count ->
        # Use Flow adapter for parallel segment solving
        {:ok, flow_config} = FlowAdapter.create_pipeline("stn_parallel_solve", 
          flow_control: :pull, 
          stages: min(segment_count, max_segments),
          demand_size: 1,
          convergence: false
        )
        
        solved_segments = FlowAdapter.process_stn_segments(flow_config, segments, &STN.PC2.apply_pc2/1)
        parallel_join(solved_segments)
    end
  end

  @doc """
  Solves the STN for consistency and computes shortest paths.
  """
  @spec solve(STN.t()) :: STN.t()
  def solve(stn) do
    STN.PC2.apply_pc2(stn)
  end

  # Private helper functions for composable operations

  defp merge_constraints_intersection(constraints1, constraints2) do
    # Merge constraint maps, taking intersection of bounds (tighter constraints)
    # This is the same as the general merge_constraints function
    Map.merge(constraints1, constraints2, fn _key, {min1, max1}, {min2, max2} ->
      # Intersection: tighter bounds win
      new_min = max(min1, min2)
      new_max = min(max1, max2)
      {new_min, new_max}
    end)
  end

  defp merge_constraints_difference(constraints1, constraints2) do
    # For difference operation: keep constraints from first STN, remove those in second
    # This filters out constraints that exist in the second STN
    constraints1
    |> Enum.reject(fn {key, _constraint} ->
         Map.has_key?(constraints2, key)
       end)
    |> Map.new()
  end

  defp merge_constraints_union(constraints1, constraints2) do
    # Merge constraint maps, taking union of bounds (looser constraints)
    Map.merge(constraints1, constraints2, fn _key, {min1, max1}, {min2, max2} ->
      # Union: looser bounds win
      new_min = min(min1, min2)
      new_max = max(max1, max2)
      {new_min, new_max}
    end)
  end

  defp create_bridge_constraints(_stn1, _stn2) do
    # Placeholder for inter-STN constraints
    %{}
  end

  defp ensure_compatible_stns(stn1, stn2) do
    # For now, we don't implement full LOD/unit conversion
    # This is a placeholder for future implementation of auto-rescaling
    # In the future, this would:
    # 1. Check if STNs have compatible time units and LOD levels
    # 2. Convert constraints to compatible units if needed
    # 3. Adjust LOD resolution if needed
    # 4. Return converted STNs
    
    {stn1, stn2}
  end
end
