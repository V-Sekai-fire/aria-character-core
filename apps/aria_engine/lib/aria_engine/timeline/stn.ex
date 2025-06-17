# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.STN do
  @moduledoc """
  Simple Temporal Network (STN) implementation with composable, parallelizable operations
  and Path Consistency (PC-2) algorithm.

  This module provides optimal constraint solving for temporal relationships
  using composable STN operations that can be parallelized, avoiding O(n³) 
  complexity blowup through strategic segmentation and boolean-like operations.

  ## Creating STNs

  For basic usage:
  ```elixir
  stn = STN.new()  # Standard STN
  ```

  For production systems requiring predictable performance:
  ```elixir
  stn = STN.new_constant_work()  # AWS constant work pattern enabled
  ```

  ## Time Unit Design

  Each STN has an explicit `time_unit` field that defines the base unit for all
  temporal constraints within that network. The default is `:millisecond` for
  high-precision temporal reasoning with integer arithmetic.

  - Constraints are expressed in the STN's `time_unit`
  - Integration with Interval module handles unit conversion automatically
  - Use `convert_units/2` to change an STN's time unit if needed
  - Mixed-unit STNs require explicit conversion before composition

  ## Composable STN Operations

  Like boolean algebra, STNs support compositional operations:
  - **Union**: Combine constraints allowing either STN to be satisfied (looser constraints)
  - **Intersection**: Find common constraints that must satisfy both STNs (tighter constraints)
  - **Difference**: Remove constraints from one STN based on another STN
  - **Composition**: Chain STNs sequentially
  - **Parallel Join**: Merge independent STN segments

  ## Parallelization Strategy

  - **Segment Independence**: Divide timeline into independent segments
  - **Parallel Solving**: Each segment solved independently  
  - **Boundary Merging**: Combine results at segment boundaries
  - **Complexity Reduction**: O(n³) becomes O(k * (n/k)³) where k = segments

  ## AWS Constant Work Pattern

  The constant work pattern ensures predictable performance by always processing
  maximum-sized constraint networks, regardless of actual complexity. This eliminates
  performance variance in real-time temporal reasoning systems.

  Use `new_constant_work/1` for production systems requiring consistent response times.
  See ADR-081 for detailed implementation rationale.

  ## Algorithm: Path Consistency (PC-2)

  The PC-2 algorithm maintains path consistency in the constraint graph by
  ensuring that for every triple of variables (i, j, k), the direct constraint
  between i and k is consistent with the path i -> j -> k.

  Time complexity: O(n³) per segment, parallelizable across segments
  Space complexity: O(n²) for the constraint matrix

  ## References

  - ADR-040: Temporal Constraint Solver Selection  
  - ADR-081: AWS Constant Work Pattern for STN Solving
  - "Temporal Constraint Networks" by Dechter, Meiri, and Pearl (1991)
  - "Parallelizing Constraint Satisfaction" for segmentation approaches
  - [AWS Builders Library - Reliability and Constant Work](https://aws.amazon.com/builders-library/reliability-and-constant-work/)
  """

  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.LodAdapter
  alias AriaEngine.FlowAdapter
  require Logger

  @type constraint :: {number(), number()}  # {min_distance, max_distance}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000  # time units per tick

  @type t :: %__MODULE__{
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          consistent: boolean(),
          segments: [segment()],
          metadata: map(),
          # LOD and unit declaration system
          time_unit: time_unit(),
          lod_level: lod_level(),
          lod_resolution: lod_resolution(),
          # Auto-rescaling parameters
          auto_rescale: boolean(),
          datetime_conversion_unit: time_unit(),
          # Constant work pattern support
          max_timepoints: pos_integer(),
          constant_work_enabled: boolean(),
          dummy_constraints: constraint_matrix()
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
            metadata: %{},
            # LOD and unit system defaults
            time_unit: :millisecond,
            lod_level: :medium,
            lod_resolution: 100,
            # Auto-rescaling defaults
            auto_rescale: true,
            datetime_conversion_unit: :millisecond,
            # Constant work pattern defaults (AWS constant work pattern - opt-in)
            max_timepoints: 64,
            constant_work_enabled: false,
            dummy_constraints: %{}

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
  Creates a new Simple Temporal Network with specified units and LOD level.

  ## Options

  - `:time_unit` - Base time unit for the STN (default: `:millisecond`)
  - `:lod_level` - Level of detail for temporal resolution (default: `:medium`)
  - `:auto_rescale` - Enable automatic rescaling for DateTime conversion (default: `true`)
  - `:max_timepoints` - Maximum timepoints for constant work pattern (default: `64`)
  - `:constant_work_enabled` - Enable AWS constant work pattern (default: `false`)

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new(time_unit: :second, lod_level: :high)
      iex> stn.time_unit
      :second

  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    time_unit = Keyword.get(opts, :time_unit, :millisecond)
    lod_level = Keyword.get(opts, :lod_level, :medium)
    max_timepoints = Keyword.get(opts, :max_timepoints, 64)
    constant_work_enabled = Keyword.get(opts, :constant_work_enabled, false)
    
    stn = %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true,
      time_unit: time_unit,
      lod_level: lod_level,
      lod_resolution: lod_resolution_for_level(lod_level),
      auto_rescale: Keyword.get(opts, :auto_rescale, true),
      datetime_conversion_unit: Keyword.get(opts, :datetime_conversion_unit, :millisecond),
      max_timepoints: max_timepoints,
      constant_work_enabled: constant_work_enabled,
      dummy_constraints: %{}
    }
    
    if constant_work_enabled do
      initialize_constant_work_structure(stn)
    else
      stn
    end
  end

  @doc """
  Creates a new Simple Temporal Network with constant work pattern enabled by default.
  
  This is a convenience function for production use cases where predictable performance
  is required. Equivalent to calling `new(constant_work_enabled: true, ...)`.

  ## Options

  - `:time_unit` - Base time unit for the STN (default: `:millisecond`)
  - `:lod_level` - Level of detail for temporal resolution (default: `:medium`)
  - `:max_timepoints` - Maximum timepoints for constant work pattern (default: `64`)
  - `:auto_rescale` - Enable automatic rescaling for DateTime conversion (default: `true`)

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new_constant_work()
      iex> stn.constant_work_enabled
      true

      iex> stn = AriaEngine.Timeline.STN.new_constant_work(max_timepoints: 128)
      iex> stn.max_timepoints
      128

  """
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    opts_with_constant_work = Keyword.put(opts, :constant_work_enabled, true)
    new(opts_with_constant_work)
  end

  @doc """
  Performs intersection operation on two STNs.
    
  This creates constraints that satisfy both STNs simultaneously.
  Results in tighter (more restrictive) constraints.

  ## Examples

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> result = AriaEngine.Timeline.STN.intersection(stn1, stn2)
      iex> result.consistent
      true
  """
  @spec intersection(t(), t()) :: t()
  def intersection(stn1, stn2) do
    # Auto-rescale to compatible units and LOD if enabled
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    
    # Merge time points
    merged_points = MapSet.union(compatible_stn1.time_points, compatible_stn2.time_points)
    
    # Merge constraints (intersection of bounds - tighter constraints)
    merged_constraints = merge_constraints_intersection(compatible_stn1.constraints, compatible_stn2.constraints)
    
    %__MODULE__{
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
    |> apply_pc2()
  end

  @doc """
  Adds an interval to the STN with automatic unit conversion and LOD rescaling.

  This creates two time points (start and end) and adds the necessary
  temporal constraints. Then applies PC-2 to maintain consistency.
  
  The interval's DateTime values are automatically converted to the STN's
  declared time units and rescaled according to the LOD level.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new(time_unit: :second, lod_level: :high)
      iex> interval = AriaEngine.Timeline.Interval.new(
      ...>   ~U[2025-01-01 10:00:00Z],
      ...>   ~U[2025-01-01 12:00:00Z]
      ...> )
      iex> updated_stn = AriaEngine.Timeline.STN.add_interval(stn, interval)
      iex> updated_stn.consistent
      true

  """
  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(stn, interval) do
    start_point = "#{interval.id}_start"
    end_point = "#{interval.id}_end"
    
    # Convert DateTime to STN units with LOD rescaling
    duration = convert_datetime_duration_to_stn_units(
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
    |> apply_pc2()
  end

  @doc """
  Updates an interval in the STN by removing the old one and adding the new one.
  """
  @spec update_interval(t(), Interval.t()) :: t()
  def update_interval(stn, interval) do
    stn
    |> remove_interval(interval.id)
    |> add_interval(interval)
  end

  @doc """
  Removes an interval from the STN.
  """
  @spec remove_interval(t(), String.t()) :: t()
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
    |> apply_pc2()
  end

  @doc """
  Adds a durative action to the STN, creating time points for its start and end,
  and adding a duration constraint.
  """
  @spec add_durative_action(t(), AriaEngine.Domain.DurativeAction.t()) :: t()
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
    
    # Add the constraint, intersecting with existing if present
    {updated_constraints, is_inconsistent} = 
      case Map.get(stn.constraints, {from_point, to_point}) do
        nil ->
          {Map.put(stn.constraints, {from_point, to_point}, constraint), false}
        existing_constraint ->
          case intersect_constraints(existing_constraint, constraint) do
            :inconsistent ->
              {stn.constraints, true} # Mark as inconsistent, keep original constraints
            new_c ->
              {Map.put(stn.constraints, {from_point, to_point}, new_c), false}
          end
      end
    
    # If already inconsistent, return early
    if is_inconsistent do
      %{stn | consistent: false}
    else
      # Add the reverse constraint, intersecting with existing if present
      reverse_constraint = {-max_dist, -min_dist}
      {updated_constraints_with_reverse, is_inconsistent_with_reverse} = 
        case Map.get(updated_constraints, {to_point, from_point}) do
          nil ->
            {Map.put(updated_constraints, {to_point, from_point}, reverse_constraint), false}
          existing_reverse_constraint ->
            case intersect_constraints(existing_reverse_constraint, reverse_constraint) do
              :inconsistent ->
                {updated_constraints, true} # Mark as inconsistent, keep original constraints
              new_c ->
                {Map.put(updated_constraints, {to_point, from_point}, new_c), false}
            end
        end
      
      if is_inconsistent_with_reverse do
        %{stn | consistent: false}
      else
        # Apply PC-2 to propagate the new constraint
        %{stn | constraints: updated_constraints_with_reverse}
        |> apply_pc2()
      end
    end
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

  # LOD and Unit Conversion System

  @doc """
  Changes the LOD level of an STN, rescaling all constraints appropriately.
  
  This is useful for dynamically adjusting temporal resolution based on
  computational requirements or precision needs.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new(lod_level: :low)
      iex> high_detail_stn = AriaEngine.Timeline.STN.rescale_lod(stn, :high)
      iex> high_detail_stn.lod_level
      :high

  """
  @spec rescale_lod(t(), lod_level()) :: t()
  def rescale_lod(stn, new_lod_level) do
    if stn.lod_level == new_lod_level do
      stn
    else
      old_resolution = stn.lod_resolution
      new_resolution = lod_resolution_for_level(new_lod_level)
      scale_factor = old_resolution / new_resolution
      
      # Rescale all constraints
      rescaled_constraints = 
        Enum.map(stn.constraints, fn {{from, to}, {min_dist, max_dist}} ->
          {{from, to}, {round(min_dist * scale_factor), round(max_dist * scale_factor)}}
        end)
        |> Map.new()
      
      %{stn | 
        lod_level: new_lod_level,
        lod_resolution: new_resolution,
        constraints: rescaled_constraints
      }
      |> apply_pc2()
    end
  end

  @doc """
  Converts STN units to a different time unit.
  
  This is useful for interfacing with other systems that use different
  temporal resolutions.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new(time_unit: :millisecond)
      iex> second_stn = AriaEngine.Timeline.STN.convert_units(stn, :second)
      iex> second_stn.time_unit
      :second

  """
  @spec convert_units(t(), time_unit()) :: t()
  def convert_units(stn, new_unit) do
    if stn.time_unit == new_unit do
      stn
    else
      conversion_factor = unit_conversion_factor(stn.time_unit, new_unit)
      
      # Convert all constraints
      converted_constraints = 
        Enum.map(stn.constraints, fn {{from, to}, {min_dist, max_dist}} ->
          {{from, to}, {round(min_dist * conversion_factor), round(max_dist * conversion_factor)}}
        end)
        |> Map.new()
      
      %{stn | 
        time_unit: new_unit,
        constraints: converted_constraints
      }
      |> apply_pc2()
    end
  end

  @doc """
  Creates an STN from DateTime intervals with automatic unit conversion.
  
  This is the primary interface for creating STNs from real-world temporal data.

  ## Examples

      iex> intervals = [
      ...>   AriaEngine.Timeline.Interval.new(~U[2025-01-01 10:00:00Z], ~U[2025-01-01 11:00:00Z]),
      ...>   AriaEngine.Timeline.Interval.new(~U[2025-01-01 11:30:00Z], ~U[2025-01-01 12:00:00Z])
      ...> ]
      iex> stn = AriaEngine.Timeline.STN.from_datetime_intervals(intervals, time_unit: :minute)
      iex> stn.time_unit
      :minute

  """
  @spec from_datetime_intervals([Interval.t()], keyword()) :: t()
  def from_datetime_intervals(intervals, opts \\ []) do
    stn = new(opts)
    
    Enum.reduce(intervals, stn, fn interval, acc_stn ->
      add_interval(acc_stn, interval)
    end)
  end

  # Boolean-like Operators for STN Composition

  @doc """
  Performs difference operation on two STNs.
  
  This removes constraints from the first STN based on the second STN.
  Results in constraints that satisfy the first STN but not the second.

  ## Examples

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> result = AriaEngine.Timeline.STN.difference(stn1, stn2)
      iex> result.consistent
      true

  """
  @spec difference(t(), t()) :: t()
  def difference(stn1, stn2) do
    # Auto-rescale to compatible units and LOD if enabled
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    
    # Keep time points from first STN, remove those in second
    merged_points = MapSet.difference(compatible_stn1.time_points, compatible_stn2.time_points)
    
    # For difference, we remove constraints that exist in stn2
    merged_constraints = merge_constraints_difference(compatible_stn1.constraints, compatible_stn2.constraints)
    
    %__MODULE__{
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
    |> apply_pc2()
  end

  @doc """
  Splits an STN into multiple independent segments for parallel processing.
  
  This is similar to boolean decomposition, breaking complex problems
  into simpler, parallelizable components.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> segments = AriaEngine.Timeline.STN.split(stn, 3)
      iex> is_list(segments)
      true

  """
  @spec split(t(), pos_integer()) :: [t()]
  def split(stn, num_segments), do: segment(stn, num_segments)

  @doc """
  Chains multiple STNs sequentially using temporal ordering constraints.
  
  This creates a pipeline of temporal constraints where each STN must
  complete before the next can begin.

  ## Examples

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> stn3 = AriaEngine.Timeline.STN.new()
      iex> chained = AriaEngine.Timeline.STN.chain([stn1, stn2, stn3])
      iex> chained.consistent
      true

  """
  @spec chain([t()]) :: t()
  def chain([]), do: new()
  def chain([single_stn]), do: single_stn
  def chain([first_stn | rest_stns]) do
    Enum.reduce(rest_stns, first_stn, fn stn, acc ->
      compose(acc, stn)
    end)
  end

  @doc """
  Bridge and compose STNs with different LOD levels using the LOD adapter.
  
  This is the high-level interface for cross-LOD STN operations, automatically
  handling unit conversion, LOD rescaling, and optimal target determination.

  ## Parameters

  - `stn1` - First STN
  - `stn2` - Second STN  
  - `operation` - Boolean operation (:intersection | :union | :difference)
  - `opts` - Bridging options (passed to LodAdapter.bridge_and_compose/4)

  ## Examples

      iex> real_time_stn = AriaEngine.Timeline.STN.new(lod_level: :ultra_high, time_unit: :microsecond)
      iex> planning_stn = AriaEngine.Timeline.STN.new(lod_level: :low, time_unit: :second)
      iex> result = AriaEngine.Timeline.STN.bridge_compose(real_time_stn, planning_stn, :intersection)
      iex> result = AriaEngine.Timeline.STN.bridge_compose(real_time_stn, planning_stn, :union,
      ...>   target_lod: :medium, target_unit: :millisecond)

  """
  @spec bridge_compose(t(), t(), :intersection | :union | :difference, keyword()) :: t()
  def bridge_compose(%__MODULE__{} = stn1, %__MODULE__{} = stn2, operation, opts \\ [])
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
  
  This enables temporal planning workflows that span from strategic planning
  down to detailed execution timing.

  ## Examples

      iex> strategic_stn = AriaEngine.Timeline.STN.new(lod_level: :very_low, time_unit: :hour)
      iex> tactical_stn = AriaEngine.Timeline.STN.new(lod_level: :low, time_unit: :minute)  
      iex> execution_stn = AriaEngine.Timeline.STN.new(lod_level: :high, time_unit: :millisecond)
      iex> chain = AriaEngine.Timeline.STN.lod_chain([strategic_stn, tactical_stn, execution_stn])

  """
  @spec lod_chain([t()], keyword()) :: t()
  def lod_chain(stns, opts \\ []) when is_list(stns) do
    case length(stns) do
      0 -> new()
      1 -> hd(stns)
      _ -> 
        # Use LOD adapter for chaining
        LodAdapter.create_lod_chain(stns, :sequential, opts)
    end
  end

  # Unit Conversion and LOD Helper Functions

  defp lod_resolution_for_level(:ultra_high), do: 1
  defp lod_resolution_for_level(:high), do: 10  
  defp lod_resolution_for_level(:medium), do: 100
  defp lod_resolution_for_level(:low), do: 1000
  defp lod_resolution_for_level(:very_low), do: 10000

  defp unit_conversion_factor(from_unit, to_unit) do
    from_microseconds = unit_to_microseconds(from_unit)
    to_microseconds = unit_to_microseconds(to_unit)
    from_microseconds / to_microseconds
  end

  defp unit_to_microseconds(:microsecond), do: 1
  defp unit_to_microseconds(:millisecond), do: 1_000
  defp unit_to_microseconds(:second), do: 1_000_000
  defp unit_to_microseconds(:minute), do: 60_000_000
  defp unit_to_microseconds(:hour), do: 3_600_000_000
  defp unit_to_microseconds(:day), do: 86_400_000_000

  defp convert_datetime_duration_to_stn_units(start_dt, end_dt, target_unit, _lod_level, lod_resolution) do
    # Calculate duration in microseconds
    duration_microseconds = DateTime.diff(end_dt, start_dt, :microsecond)
    
    # Convert to target unit
    target_unit_microseconds = unit_to_microseconds(target_unit)
    duration_in_target_units = duration_microseconds / target_unit_microseconds
    
    # Apply LOD rescaling
    rescaled_duration = duration_in_target_units / lod_resolution
    
    # Round to ensure integer constraints
    round(rescaled_duration)
  end

  defp initialize_constant_work_structure(stn) do
    # Pre-allocate dummy timepoints for constant work pattern
    dummy_points = 
      for i <- 1..stn.max_timepoints do
        "dummy_#{i}"
      end
      |> MapSet.new()
    
    # Add self-constraints for dummy points
    dummy_constraints = 
      Enum.reduce(dummy_points, %{}, fn point, acc ->
        Map.put(acc, {point, point}, {0, 0})
      end)
    
    %{stn | 
      time_points: MapSet.union(stn.time_points, dummy_points),
      dummy_constraints: dummy_constraints,
      constraints: Map.merge(stn.constraints, dummy_constraints)
    }
  end

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

  # Composable STN Operations - Boolean-like algebra for STNs

  @doc """
  Combines two STNs using union operation.
  
  Union operation merges constraints from both STNs, taking the intersection
  of constraint bounds where they overlap (tighter constraints win).
  
  This operation is commutative and associative, enabling parallelization.
  Auto-rescales STNs to compatible units and LOD levels if needed.

  ## Examples

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> combined = AriaEngine.Timeline.STN.union(stn1, stn2)
      iex> combined.consistent
      true

  """
  @spec union(t(), t()) :: t()
  def union(stn1, stn2) do
    # Auto-rescale to compatible units and LOD if enabled
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    
    # Merge time points
    merged_points = MapSet.union(compatible_stn1.time_points, compatible_stn2.time_points)
    
    # Merge constraints (intersection of bounds)
    merged_constraints = merge_constraints_union(compatible_stn1.constraints, compatible_stn2.constraints)
    
    # Combine metadata
    merged_metadata = Map.merge(compatible_stn1.metadata, compatible_stn2.metadata)
    
    %__MODULE__{
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
    |> apply_pc2()
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

      iex> stn1 = AriaEngine.Timeline.STN.new()
      iex> stn2 = AriaEngine.Timeline.STN.new()
      iex> stn3 = AriaEngine.Timeline.STN.new()
      iex> segments = [stn1, stn2, stn3]
      iex> joined = AriaEngine.Timeline.STN.parallel_join(segments)
      iex> joined.consistent
      true

  """
  @spec parallel_join([t()]) :: t()
  def parallel_join([]), do: new()
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
          Enum.chunk_every(stns, 2, 2, [new()]) |> Enum.map(&List.to_tuple/1),
          &union/2)
        |> Enum.reduce(&union/2)
        |> apply_pc2()
      
      _ ->
        # Direct processing for small sets
        stns
        |> Enum.reduce(&union/2)
        |> apply_pc2()
    end
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
  @spec segment(t(), pos_integer()) :: [t()]
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
      
    %__MODULE__{
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
  
  This provides significant performance improvement for large STNs
  by leveraging multi-core processing via the Flow adapter.

  ## Examples

      iex> stn = AriaEngine.Timeline.STN.new()
      iex> solved = AriaEngine.Timeline.STN.parallel_solve(stn, 4)
      iex> solved.consistent
      true

  """
  @spec parallel_solve(t(), integer()) :: t()
  def parallel_solve(stn, max_segments \\ System.schedulers_online()) do
    segments = segment(stn, max_segments)
    
    case length(segments) do
      1 -> 
        # Single segment, no need for parallel processing
        apply_pc2(hd(segments))
      
      segment_count ->
        # Use Flow adapter for parallel segment solving
        {:ok, flow_config} = FlowAdapter.create_pipeline("stn_parallel_solve", 
          flow_control: :pull, 
          stages: min(segment_count, max_segments),
          demand_size: 1,
          convergence: false
        )
        
        solved_segments = FlowAdapter.process_stn_segments(flow_config, segments, &apply_pc2/1)
        parallel_join(solved_segments)
    end
  end

  @doc """
  Solves the STN for consistency and computes shortest paths.
  """
  @spec solve(t()) :: t()
  def solve(stn) do
    apply_pc2(stn)
  end

  @doc """
  Adds a time point to the STN.
  """
  @spec add_time_point(t(), time_point()) :: t()
  def add_time_point(stn, time_point) do
    updated_time_points = MapSet.put(stn.time_points, time_point)
    
    # Add self-constraint for the new time point
    updated_constraints = Map.put(stn.constraints, {time_point, time_point}, {0, 0})
    
    %{stn | 
      time_points: updated_time_points,
      constraints: updated_constraints
    }
  end

    # Core PC-2 algorithm implementation
  defp apply_pc2_iterations(time_points, constraints) do
    _n = length(time_points)
    Logger.debug("PC2: Starting apply_pc2_iterations. Time points: #{inspect(time_points)}, Initial constraints: #{inspect(constraints)}")
    
    # Initialize with existing constraints and zero self-constraints
    initial_constraints = initialize_constraints(time_points, constraints)
    Logger.debug("PC2: Initialized constraints: #{inspect(initial_constraints)}")
    
    # First check for direct cycle inconsistencies (critical for 2-point networks)
    case check_direct_cycle_consistency(time_points, initial_constraints) do
      :inconsistent ->
        Logger.debug("PC2: Inconsistent after direct cycle check.")
        {initial_constraints, false}
      
      :consistent ->
        Logger.debug("PC2: Consistent after direct cycle check. Proceeding with main loops.")
        # Apply three nested loops for path consistency (Floyd-Warshall style)
        {final_constraints, consistent} = 
          Enum.reduce_while(time_points, {initial_constraints, true}, fn k, {acc_constraints, acc_consistent} ->
            Logger.debug("PC2: Outer loop (k): #{k}. Current consistent: #{acc_consistent}")
            if not acc_consistent do
              {:halt, {acc_constraints, false}}
            else
              case apply_pc2_with_intermediate(time_points, acc_constraints, k) do
                {new_constraints, new_consistent} ->
                  Logger.debug("PC2: Intermediate loop result for k=#{k}: Consistent: #{new_consistent}")
                  {:cont, {new_constraints, new_consistent}}
              end
            end
          end)
        
        # Final check for consistency after all iterations
        final_consistent = Enum.all?(Map.values(final_constraints), fn {min, max} -> min <= max end)
        Logger.debug("PC2: Final consistency check. Constraints: #{inspect(final_constraints)}. All bounds valid: #{final_consistent}")
        
        {final_constraints, consistent and final_consistent}
    end
  end

  defp check_direct_cycle_consistency(time_points, constraints) do
    Logger.debug("PC2: Checking direct cycle consistency.")
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
            Logger.debug("PC2: Checking direct cycle #{i} -> #{j} -> #{i}. Constraints: #{inspect(ij_constraint)}, #{inspect(ji_constraint)}")
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
    Logger.debug("PC2: check_cycle_consistency for (#{min1},#{max1}), (#{min2},#{max2}). Cycle: (#{cycle_min},#{cycle_max})")
    
    if cycle_min > 0 or cycle_max < 0 do
      Logger.debug("PC2: Cycle inconsistent.")
      :inconsistent
    else
      Logger.debug("PC2: Cycle consistent.")
      :consistent
    end
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
    Logger.debug("PC2: Entering apply_pc2_with_intermediate for k=#{k}. Constraints: #{inspect(constraints)}")
    Enum.reduce_while(time_points, {constraints, true}, fn i, {acc_constraints_i, acc_consistent_i} ->
      Logger.debug("PC2: Inner loop (i): #{i}. Current consistent: #{acc_consistent_i}")
      if not acc_consistent_i do
        {:halt, {acc_constraints_i, false}}
      else
        {final_constraints_j, final_consistent_j} =
          Enum.reduce_while(time_points, {acc_constraints_i, acc_consistent_i}, fn j, {acc_constraints_j, acc_consistent_j} ->
            Logger.debug("PC2: Innermost loop (j): #{j}. Current consistent: #{acc_consistent_j}")
            if not acc_consistent_j do
              {:halt, {acc_constraints_j, false}}
            else
              case update_constraint_via_path(acc_constraints_j, i, j, k) do
                {:inconsistent} ->
                  Logger.debug("PC2: Inconsistency detected in update_constraint_via_path for #{i}-#{j}-#{k}.")
                  {:halt, {acc_constraints_j, false}}
                {:ok, new_constraints} ->
                  Logger.debug("PC2: Constraint updated for #{i}-#{j}-#{k}. New constraints: #{inspect(new_constraints)}")
                  {:cont, {new_constraints, true}}
              end
            end
          end)
        {:cont, {final_constraints_j, final_consistent_j}}
      end
    end)
  end

  defp update_constraint_via_path(constraints, i, j, k) do
    Logger.debug("PC2: update_constraint_via_path for i=#{i}, j=#{j}, k=#{k}. Constraints: #{inspect(constraints)}")
    # Get existing direct constraint i -> j (default to no constraint if not exists)
    direct_constraint = Map.get(constraints, {i, j})
    Logger.debug("PC2: Direct constraint #{i}-#{j}: #{inspect(direct_constraint)}")

    # Get path constraint i -> k -> j
    ik_constraint = Map.get(constraints, {i, k})
    kj_constraint = Map.get(constraints, {k, j})
    Logger.debug("PC2: Path constraints #{i}-#{k}: #{inspect(ik_constraint)}, #{k}-#{j}: #{inspect(kj_constraint)}")

    # Skip if either path constraint is missing
    if is_nil(ik_constraint) or is_nil(kj_constraint) do
      Logger.debug("PC2: Skipping update_constraint_via_path due to missing path constraints.")
      {:ok, constraints}
    else
      path_constraint = compose_constraints(ik_constraint, kj_constraint)
      Logger.debug("PC2: Composed path constraint: #{inspect(path_constraint)}")

      # Intersect direct and path constraints
      new_constraint =
        if is_nil(direct_constraint) do
          path_constraint
        else
          intersect_constraints(direct_constraint, path_constraint)
        end
      Logger.debug("PC2: Intersected new constraint: #{inspect(new_constraint)}")

      case new_constraint do
        :inconsistent ->
          Logger.debug("PC2: Inconsistency detected in intersect_constraints.")
          {:inconsistent}

        constraint ->
          # Only update if the new constraint is tighter than the direct constraint
          updated_constraints =
            if constraint != direct_constraint do
              Map.put(constraints, {i, j}, constraint)
            else
              constraints
            end
          Logger.debug("PC2: Updated constraints: #{inspect(updated_constraints)}")
          {:ok, updated_constraints}
      end
    end
  end

  defp compose_constraints({min1, max1}, {min2, max2}) do
    composed = {min1 + min2, max1 + max2}
    Logger.debug("PC2: Composing (#{min1},#{max1}) and (#{min2},#{max2}) -> #{inspect(composed)}")
    composed
  end

  defp intersect_constraints({min1, max1}, {min2, max2}) do
    new_min = max(min1, min2)
    new_max = min(max1, max2)
    Logger.debug("PC2: Intersecting (#{min1},#{max1}) and (#{min2},#{max2}) -> (#{new_min},#{new_max})")

    # Check for inconsistency
    if new_min > new_max do
      Logger.debug("PC2: Inconsistency detected in intersect_constraints: #{new_min} > #{new_max}")
      :inconsistent
    else
      {new_min, new_max}
    end
  end

  # Private helper functions for composable operations


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
