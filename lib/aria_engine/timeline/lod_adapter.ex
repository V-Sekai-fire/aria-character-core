# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.LodAdapter do
  @moduledoc """
  Level of Detail (LOD) adapter for Simple Temporal Networks (STNs).
  
  This adapter handles rescaling, bridging, and conversion between different
  LOD levels and time units for STN operations. It enables STNs with different
  temporal resolutions to be composed together seamlessly.
  
  ## LOD Architecture
  
  The LOD system provides hierarchical temporal resolution levels:
  
  - **Ultra High** (1:1): Microsecond precision, real-time constraints
  - **High** (1:10): Millisecond precision, immediate response constraints  
  - **Medium** (1:100): Centisecond precision, interactive constraints
  - **Low** (1:1000): Second precision, planning constraints
  - **Very Low** (1:10000): Tensecond precision, strategic constraints
  
  ## Unit Conversion Support
  
  Supports automatic conversion between time units:
  - `:microsecond` → `:millisecond` → `:second` → `:minute` → `:hour` → `:day`
  
  ## Bridging Operations
  
  - **Upscale**: Convert from fine-grained to coarse-grained LOD
  - **Downscale**: Convert from coarse-grained to fine-grained LOD  
  - **Cross-LOD Composition**: Enable STN operations across different LOD levels
  - **Automatic Rescaling**: Transparent unit/resolution conversion
  
  ## Integration with Flow Adapter
  
  All parallel operations use FlowAdapter for consistent
  performance characteristics and avoid direct Task.async_stream usage.
  
  ## References
  
  - ADR-081: AWS Constant Work Pattern for STN Solving
  - ADR-034: Definitive Temporal Planner Architecture
  """
  
  alias Timeline
  # alias AriaEngine.ConvergenceFlow
  
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low | :galactic | :cosmic
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day | :week | :month | :year | :decade | :century | :millennium | :megayear
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000 | 100000 | 1000000
  @type conversion_direction :: :upscale | :downscale | :same_level
  
  # LOD level to resolution mapping
  @lod_resolutions %{
    ultra_high: 1,
    high: 10, 
    medium: 100,
    low: 1000,
    very_low: 10000,
    galactic: 100000,
    cosmic: 1000000
  }
  
  # Time unit conversion factors (to microseconds)
  @time_unit_factors %{
    microsecond: 1,
    millisecond: 1_000,
    second: 1_000_000,
    minute: 60_000_000,
    hour: 3_600_000_000,
    day: 86_400_000_000,
    week: 604_800_000_000,
    month: 2_629_800_000_000,
    year: 31_557_600_000_000,
    decade: 315_576_000_000_000,
    century: 3_155_760_000_000_000,
    millennium: 31_557_600_000_000_000,
    megayear: 31_557_600_000_000_000_000
  }
  
  # LOD level hierarchy (ordered from finest to coarsest)
  @lod_hierarchy [:ultra_high, :high, :medium, :low, :very_low, :galactic, :cosmic]
  
  # Private functions
  
  defp determine_conversion_direction(source_lod, target_lod) do
    source_idx = Enum.find_index(@lod_hierarchy, &(&1 == source_lod))
    target_idx = Enum.find_index(@lod_hierarchy, &(&1 == target_lod))
    
    cond do
      source_idx < target_idx -> :upscale    # finer to coarser
      source_idx > target_idx -> :downscale  # coarser to finer  
      true -> :same_level
    end
  end
  
  defp calculate_lod_scale_factor(source_lod, target_lod) do
    source_resolution = @lod_resolutions[source_lod]
    target_resolution = @lod_resolutions[target_lod]
    target_resolution / source_resolution
  end
  
  defp calculate_unit_scale_factor(source_unit, target_unit) do
    source_factor = @time_unit_factors[source_unit]
    target_factor = @time_unit_factors[target_unit]
    source_factor / target_factor
  end
  
  defp convert_lod_direct(%Timeline{} = timeline, target_lod, target_unit, scale_factor, opts) do
    rounding_strategy = Keyword.get(opts, :rounding_strategy, :round)
    stn = timeline.stn
    
    # Scale all constraints by the calculated factor
    scaled_constraints = 
      stn.constraints
      |> Enum.map(fn {key, {min_dist, max_dist}} ->
           {key, scale_constraint({min_dist, max_dist}, scale_factor, rounding_strategy)}
         end)
      |> Map.new()
    
    # Scale dummy constraints if constant work is enabled
    scaled_dummy_constraints = 
      if stn.constant_work_enabled do
        stn.dummy_constraints
        |> Enum.map(fn {key, {min_dist, max_dist}} ->
             {key, scale_constraint({min_dist, max_dist}, scale_factor, rounding_strategy)}
           end)
        |> Map.new()
      else
        stn.dummy_constraints
      end
    
    # Update STN with new LOD parameters
    updated_stn = %Timeline.Internal.STN{stn | 
      lod_level: target_lod,
      time_unit: target_unit,
      lod_resolution: @lod_resolutions[target_lod],
      constraints: scaled_constraints,
      dummy_constraints: scaled_dummy_constraints,
      consistent: false  # Will need re-solving after scaling
    }
    
    # Return updated Timeline
    %Timeline{timeline | stn: updated_stn}
  end
  
  defp scale_constraint({min_dist, max_dist}, scale_factor, rounding_strategy) do
    scaled_min = apply_rounding(min_dist * scale_factor, rounding_strategy)
    scaled_max = apply_rounding(max_dist * scale_factor, rounding_strategy)
    {scaled_min, scaled_max}
  end
  
  defp apply_rounding(value, :floor), do: Float.floor(value)
  defp apply_rounding(value, :ceil), do: Float.ceil(value)  
  defp apply_rounding(value, :round), do: Float.round(value)
  
  defp determine_bridge_target(%Timeline.Internal.STN{} = stn1, %Timeline.Internal.STN{} = stn2, opts) do
    case {Keyword.get(opts, :target_lod), Keyword.get(opts, :target_unit)} do
      {nil, nil} ->
        # Auto-determine optimal target
        bridging_strategy = Keyword.get(opts, :bridging_strategy, :median)
        auto_determine_bridge_target(stn1, stn2, bridging_strategy)
      
      {target_lod, nil} ->
        # LOD specified, auto-determine unit
        target_unit = determine_optimal_unit([stn1.time_unit, stn2.time_unit])
        {target_lod, target_unit}
      
      {nil, target_unit} ->  
        # Unit specified, auto-determine LOD
        target_lod = determine_optimal_lod_for_stns([stn1, stn2])
        {target_lod, target_unit}
      
      {target_lod, target_unit} ->
        # Both specified
        {target_lod, target_unit}
    end
  end
  
  defp auto_determine_bridge_target(%Timeline.Internal.STN{} = stn1, %Timeline.Internal.STN{} = stn2, strategy) do
    lod_levels = [stn1.lod_level, stn2.lod_level]
    time_units = [stn1.time_unit, stn2.time_unit]
    
    target_lod = case strategy do
      :finest -> 
        Enum.min_by(lod_levels, &lod_level_to_index/1)
      :coarsest -> 
        Enum.max_by(lod_levels, &lod_level_to_index/1)
      :median -> 
        determine_median_lod(lod_levels)
    end
    
    target_unit = determine_optimal_unit(time_units)
    
    {target_lod, target_unit}
  end
  
  defp lod_level_to_index(lod_level) do
    Enum.find_index(@lod_hierarchy, &(&1 == lod_level))
  end
  
  defp determine_median_lod(lod_levels) do
    indices = Enum.map(lod_levels, &lod_level_to_index/1)
    median_index = Enum.sum(indices) / length(indices) |> Float.round() |> trunc()
    Enum.at(@lod_hierarchy, median_index)
  end
  
  defp determine_optimal_unit(time_units) do
    # Choose the most precise unit that can represent both without loss
    unit_factors = Enum.map(time_units, &@time_unit_factors[&1])
    min_factor = Enum.min(unit_factors)
    
    @time_unit_factors
    |> Enum.find(fn {_unit, factor} -> factor == min_factor end)
    |> elem(0)
  end
  
  defp determine_optimal_lod_for_stns(stns) do
    # Choose LOD based on average constraint density
    avg_density = 
      stns
      |> Enum.map(&calculate_constraint_density/1)
      |> Enum.sum()
      |> Kernel./(length(stns))
    
    determine_optimal_lod(avg_density, :balanced)
  end
  
  defp requires_parallel_conversion?(%Timeline.Internal.STN{} = stn) do
    map_size(stn.constraints) > 100 || stn.constant_work_enabled
  end
  
  defp apply_boolean_operation(%Timeline.Internal.STN{} = stn1, %Timeline.Internal.STN{} = stn2, :intersection) do
    Timeline.Internal.STN.intersection(stn1, stn2)
  end
  
  defp apply_boolean_operation(%Timeline.Internal.STN{} = stn1, %Timeline.Internal.STN{} = stn2, :union) do
    Timeline.Internal.STN.union(stn1, stn2)
  end
  
  defp apply_boolean_operation(%Timeline.Internal.STN{} = stn1, %Timeline.Internal.STN{} = stn2, :difference) do
    Timeline.Internal.STN.difference(stn1, stn2)  
  end
  
  defp sort_stns_by_lod(stns) do
    Enum.sort_by(stns, fn stn -> lod_level_to_index(stn.lod_level) end, :desc)
  end
  
  defp group_stns_by_lod(stns) do
    Enum.group_by(stns, fn stn -> stn.lod_level end)
  end
  
  defp combine_stns_at_level([stn]), do: stn
  defp combine_stns_at_level(stns) when is_list(stns) do
    Enum.reduce(stns, fn stn, acc -> Timeline.Internal.STN.intersection(acc, stn) end)
  end
  
  defp calculate_constraint_density(%Timeline.Internal.STN{} = stn) do
    timepoint_count = MapSet.size(stn.time_points)
    constraint_count = map_size(stn.constraints)
    
    if timepoint_count > 1 do
      max_constraints = timepoint_count * (timepoint_count - 1)
      constraint_count / max_constraints
    else
      0.0
    end
  end
  
  defp determine_optimal_lod(density, performance_target) do
    case {density, performance_target} do
      {d, :performance} when d > 0.8 -> :very_low    # High density, prioritize speed
      {d, :performance} when d > 0.6 -> :low
      {d, :performance} when d > 0.4 -> :medium
      {d, :performance} when d > 0.2 -> :high
      {_d, :performance} -> :ultra_high
      
      {d, :precision} when d < 0.2 -> :ultra_high    # Low density, prioritize precision
      {d, :precision} when d < 0.4 -> :high
      {d, :precision} when d < 0.6 -> :medium
      {d, :precision} when d < 0.8 -> :low
      {_d, :precision} -> :very_low
      
      {d, :balanced} when d < 0.3 -> :high           # Balanced approach
      {d, :balanced} when d < 0.7 -> :medium
      {_d, :balanced} -> :low
    end
  end
  
  defp chunk_constraints(constraints, chunk_count) do
    constraint_list = Map.to_list(constraints)
    chunk_size = div(length(constraint_list), chunk_count) + 1
    Enum.chunk_every(constraint_list, chunk_size)
  end
end
