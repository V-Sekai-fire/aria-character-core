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
  alias FlowAdapter
  
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000
  @type conversion_direction :: :upscale | :downscale | :same_level
  
  # LOD level to resolution mapping
  @lod_resolutions %{
    ultra_high: 1,
    high: 10, 
    medium: 100,
    low: 1000,
    very_low: 10000
  }
  
  # Time unit conversion factors (to microseconds)
  @time_unit_factors %{
    microsecond: 1,
    millisecond: 1_000,
    second: 1_000_000,
    minute: 60_000_000,
    hour: 3_600_000_000,
    day: 86_400_000_000
  }
  
  # LOD level hierarchy (ordered from finest to coarsest)
  @lod_hierarchy [:ultra_high, :high, :medium, :low, :very_low]
  
  @doc """
  Convert an STN from one LOD level to another with optional unit conversion.
  
  ## Parameters
  
  - `stn` - Source STN to convert
  - `target_lod` - Target LOD level (:ultra_high | :high | :medium | :low | :very_low)
  - `target_unit` - Optional target time unit (defaults to source unit)
  - `opts` - Conversion options
  
  ## Options
  
  - `:preserve_precision` - Whether to preserve constraint precision during conversion (default: false)
  - `:rounding_strategy` - How to handle fractional values (:floor | :ceil | :round, default: :round)
  - `:flow_config` - Flow adapter configuration for parallel processing
  
  ## Examples
  
      # Upscale from high-resolution to planning resolution
      planning_stn = LodAdapter.convert_lod(real_time_stn, :low, :second)
      
      # Downscale for detailed execution
      detailed_stn = LodAdapter.convert_lod(plan_stn, :high, :millisecond, 
        rounding_strategy: :floor)
  """
  def convert_lod(%Timeline{} = timeline, target_lod, target_unit \\ nil, opts \\ []) do
    target_unit = target_unit || timeline.time_unit
    conversion_direction = determine_conversion_direction(timeline.lod_level, target_lod)
    
    # Calculate scaling factors
    lod_scale_factor = calculate_lod_scale_factor(timeline.lod_level, target_lod)
    unit_scale_factor = calculate_unit_scale_factor(timeline.time_unit, target_unit)
    total_scale_factor = lod_scale_factor * unit_scale_factor
    
    # Apply conversion based on direction and complexity
    case {conversion_direction, map_size(timeline.constraints)} do
      {_direction, constraint_count} when constraint_count > 100 ->
        # Use Flow adapter for large constraint networks
        convert_lod_parallel(timeline, target_lod, target_unit, total_scale_factor, opts)
        
      {_direction, _small_count} ->
        # Direct conversion for small networks
        convert_lod_direct(timeline, target_lod, target_unit, total_scale_factor, opts)
    end
  end
  
  @doc """
  Bridge two STNs with different LOD levels for composition operations.
  
  This function automatically converts both STNs to a compatible LOD level
  and unit system before performing the specified boolean operation.
  
  ## Parameters
  
  - `stn1` - First STN
  - `stn2` - Second STN  
  - `operation` - Boolean operation (:intersection | :union | :difference)
  - `opts` - Bridging options
  
  ## Options
  
  - `:target_lod` - Explicit target LOD level (auto-determined if not specified)
  - `:target_unit` - Explicit target time unit (auto-determined if not specified)
  - `:bridging_strategy` - How to choose target LOD (:finest | :coarsest | :median, default: :median)
  - `:flow_config` - Flow adapter configuration for parallel processing
  
  ## Examples
  
      # Automatic bridging for intersection
      result = LodAdapter.bridge_and_compose(detailed_stn, plan_stn, :intersection)
      
      # Explicit target LOD
      result = LodAdapter.bridge_and_compose(stn1, stn2, :union, 
        target_lod: :medium, target_unit: :millisecond)
  """
  def bridge_and_compose(%Timeline{} = timeline1, %Timeline{} = timeline2, operation, opts \\ [])
      when operation in [:intersection, :union, :difference] do
    
    # Determine optimal target LOD and unit
    {target_lod, target_unit} = determine_bridge_target(timeline1.stn, timeline2.stn, opts)
    
    # Convert both STNs to compatible format
    flow_config = Keyword.get(opts, :flow_config)
    
    {converted_stn1, converted_stn2} = 
      if flow_config && (requires_parallel_conversion?(timeline1.stn) || requires_parallel_conversion?(timeline2.stn)) do
        # Use Flow adapter for parallel conversion
        bridge_stns_parallel(timeline1.stn, timeline2.stn, target_lod, target_unit, flow_config, opts)
      else
        # Direct conversion
        {
          convert_lod(timeline1, target_lod, target_unit, opts),
          convert_lod(timeline2, target_lod, target_unit, opts)
        }
      end
    
    # Perform the boolean operation
    apply_boolean_operation(converted_stn1, converted_stn2, operation)
  end
  
  @doc """
  Create a chain of STNs across multiple LOD levels with automatic bridging.
  
  This enables temporal planning that spans from high-level strategic constraints
  down to detailed execution timing constraints.
  
  ## Parameters
  
  - `stns` - List of STNs at various LOD levels
  - `composition_pattern` - How to chain STNs (:sequential | :hierarchical | :mesh)
  - `opts` - Chaining options
  
  ## Examples
  
      # Sequential chaining from strategic to tactical to execution
      chain = LodAdapter.create_lod_chain([strategic_stn, tactical_stn, execution_stn], 
        :sequential, flow_config: flow_config)
  """
  def create_lod_chain(stns, composition_pattern \\ :sequential, opts \\ [])
  
  def create_lod_chain(stns, :sequential, opts) when is_list(stns) do
    flow_config = Keyword.get(opts, :flow_config)
    
    # Sort STNs by LOD level (coarsest to finest)
    sorted_stns = sort_stns_by_lod(stns)
    
    if flow_config do
      chain_stns_parallel(sorted_stns, flow_config, opts)
    else
      chain_stns_sequential(sorted_stns, opts)
    end
  end
  
  def create_lod_chain(stns, :hierarchical, opts) when is_list(stns) do
    # Group STNs by LOD level and create hierarchical relationships
    grouped_stns = group_stns_by_lod(stns)
    create_hierarchical_lod_structure(grouped_stns, opts)
  end
  
  @doc """
  Automatically rescale an STN to maintain optimal performance characteristics
  based on constraint density and LOD requirements.
  
  This implements the constant work pattern from ADR-081 by potentially
  adjusting LOD levels to maintain predictable performance.
  """
  def auto_rescale(%Timeline.Internal.STN{} = stn, performance_target \\ :balanced, opts \\ []) do
    constraint_density = calculate_constraint_density(stn)
    optimal_lod = determine_optimal_lod(constraint_density, performance_target)
    
    if optimal_lod != stn.lod_level do
      convert_lod(stn, optimal_lod, nil, opts)
    else
      stn
    end
  end
  
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
  
  defp convert_lod_direct(%Timeline.Internal.STN{} = stn, target_lod, target_unit, scale_factor, opts) do
    rounding_strategy = Keyword.get(opts, :rounding_strategy, :round)
    
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
    %Timeline.Internal.STN{stn | 
      lod_level: target_lod,
      time_unit: target_unit,
      lod_resolution: @lod_resolutions[target_lod],
      constraints: scaled_constraints,
      dummy_constraints: scaled_dummy_constraints,
      consistent: false  # Will need re-solving after scaling
    }
  end
  
  defp convert_lod_parallel(%Timeline.Internal.STN{} = stn, target_lod, target_unit, scale_factor, opts) do
    flow_config = Keyword.get(opts, :flow_config)
    
    # Use Flow adapter for parallel constraint scaling
    if flow_config do
      rounding_strategy = Keyword.get(opts, :rounding_strategy, :round)
      constraint_chunks = chunk_constraints(stn.constraints, flow_config.stages)
      
      scaled_constraint_chunks = 
        FlowAdapter.process_stn_segments(flow_config, constraint_chunks, fn chunk ->
          chunk
          |> Enum.map(fn {key, constraint} ->
               {key, scale_constraint(constraint, scale_factor, rounding_strategy)}
             end)
          |> Map.new()
        end)
      
      scaled_constraints = Enum.reduce(scaled_constraint_chunks, %{}, &Map.merge/2)
      
      %Timeline.Internal.STN{stn | 
        lod_level: target_lod,
        time_unit: target_unit,
        lod_resolution: @lod_resolutions[target_lod],
        constraints: scaled_constraints,
        consistent: false
      }
    else
      # Fallback to direct conversion
      convert_lod_direct(stn, target_lod, target_unit, scale_factor, opts)
    end
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
  
  defp bridge_stns_parallel(stn1, stn2, target_lod, target_unit, flow_config, opts) do
    # Use Flow adapter to convert both STNs in parallel
    conversion_tasks = [
      {stn1, target_lod, target_unit, opts},
      {stn2, target_lod, target_unit, opts}
    ]
    
    results = FlowAdapter.process_stn_segments(flow_config, conversion_tasks, 
      fn {stn, t_lod, t_unit, t_opts} ->
        convert_lod(stn, t_lod, t_unit, t_opts)
      end)
    
    List.to_tuple(results)
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
  
  defp chain_stns_sequential(stns, _opts) do
    # Simple sequential chaining - each STN constrains the next
    Enum.reduce(stns, nil, fn
      stn, nil -> stn
      stn, acc -> bridge_and_compose(acc, stn, :intersection)
    end)
  end
  
  defp chain_stns_parallel(stns, flow_config, opts) do
    # Use Flow adapter for parallel chaining operations
    chain_operations = 
      stns
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.with_index()
    
    FlowAdapter.process_stn_compositions(flow_config, chain_operations,
      fn {{stn1, stn2}, _index} ->
        bridge_and_compose(stn1, stn2, :intersection, opts)
      end)
    |> List.last()  # Return final chained result
  end
  
  defp create_hierarchical_lod_structure(grouped_stns, _opts) do
    # Create a hierarchical structure where coarser levels constrain finer levels
    @lod_hierarchy
    |> Enum.reverse()  # Start with coarsest
    |> Enum.reduce(nil, fn lod_level, acc ->
         case {Map.get(grouped_stns, lod_level), acc} do
           {nil, acc} -> acc  # No STNs at this level
           {level_stns, nil} -> combine_stns_at_level(level_stns)
           {level_stns, parent} -> 
             level_combined = combine_stns_at_level(level_stns)
             bridge_and_compose(parent, level_combined, :intersection)
         end
       end)
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
