# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Internal.STN do
  @moduledoc false

  # This module is part of the internal Timeline implementation.
  # External modules should use the Timeline API instead of accessing STN directly.

  # Simple Temporal Network (STN) implementation with composable, parallelizable operations
  # and Path Consistency (PC-2) algorithm.

  # This module provides optimal constraint solving for temporal relationships
  # using composable STN operations that can be parallelized, avoiding O(n³) 
  # complexity blowup through strategic segmentation and boolean-like operations.

  ## Creating STNs

  # For basic usage:

  #     stn = STN.new()  # Standard STN

  # For production systems requiring predictable performance:

  #     stn = STN.new_constant_work()  # AWS constant work pattern enabled

  # ## Time Unit Design

  # Each STN has an explicit time_unit field that defines the base unit for all
  # temporal constraints within that network. The default is :second for
  # human-readable temporal reasoning with decimal arithmetic.

  # - Constraints are expressed in the STN's time_unit
  # - Integration with Interval module handles unit conversion automatically
  # - Use convert_units/2 to change an STN's time unit if needed
  # - Mixed-unit STNs require explicit conversion before composition

  ## Composable STN Operations

  # Like boolean algebra, STNs support compositional operations:
  # - **Union**: Combine constraints allowing either STN to be satisfied (looser constraints)
  # - **Intersection**: Find common constraints that must satisfy both STNs (tighter constraints)
  # - **Difference**: Remove constraints from one STN based on another STN
  # - **Composition**: Chain STNs sequentially
  # - **Parallel Join**: Merge independent STN segments

  ## Parallelization Strategy

  # - **Segment Independence**: Divide timeline into independent segments
  # - **Parallel Solving**: Each segment solved independently  
  # - **Boundary Merging**: Combine results at segment boundaries
  # - **Complexity Reduction**: O(n³) becomes O(k * (n/k)³) where k = segments

  ## AWS Constant Work Pattern

  # The constant work pattern ensures predictable performance by always processing
  # maximum-sized constraint networks, regardless of actual complexity. This eliminates
  # performance variance in real-time temporal reasoning systems.

  # Use new_constant_work/1 for production systems requiring consistent response times.
  # See ADR-081 for detailed implementation rationale.

  # ## Algorithm: Path Consistency (PC-2)

  # The PC-2 algorithm maintains path consistency in the constraint graph by
  # ensuring that for every triple of variables (i, j, k), the direct constraint
  # between i and k is consistent with the path i -> j -> k.

  # Time complexity: O(n³) per segment, parallelizable across segments
  # Space complexity: O(n²) for the constraint matrix

  ## References

  # - ADR-040: Temporal Constraint Solver Selection  
  # - ADR-081: AWS Constant Work Pattern for STN Solving
  # - "Temporal Constraint Networks" by Dechter, Meiri, and Pearl (1991)
  # - "Parallelizing Constraint Satisfaction" for segmentation approaches
  # - [AWS Builders Library - Reliability and Constant Work](https://aws.amazon.com/builders-library/reliability-and-constant-work/)

  alias Timeline.Internal.STN.Core
  alias Timeline.Internal.STN.PC2
  alias Timeline.Internal.STN.Units
  alias Timeline.Internal.STN.Operations

  # {min_distance, max_distance}
  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  # time units per tick
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10_000

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
            time_unit: :second,
            lod_level: :medium,
            lod_resolution: 100,
            # Auto-rescaling defaults
            auto_rescale: true,
            datetime_conversion_unit: :second,
            # Constant work pattern defaults (AWS constant work pattern - opt-in)
            max_timepoints: 64,
            constant_work_enabled: false,
            dummy_constraints: %{}

  @doc """
  Creates a new empty Simple Temporal Network.

  Uses seconds as the default time unit for human-readable temporal constraints.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true,
      # Default to seconds instead of milliseconds
      time_unit: :second
    }
  end

  @doc """
  Creates a new Simple Temporal Network with specified units and LOD level.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    time_unit = Keyword.get(opts, :time_unit, :second)
    lod_level = Keyword.get(opts, :lod_level, :medium)
    max_timepoints = Keyword.get(opts, :max_timepoints, 64)
    constant_work_enabled = Keyword.get(opts, :constant_work_enabled, false)

    stn = %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true,
      time_unit: time_unit,
      lod_level: lod_level,
      lod_resolution: Units.lod_resolution_for_level(lod_level),
      auto_rescale: Keyword.get(opts, :auto_rescale, true),
      datetime_conversion_unit: Keyword.get(opts, :datetime_conversion_unit, :second),
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
  """
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    opts_with_constant_work = Keyword.put(opts, :constant_work_enabled, true)
    new(opts_with_constant_work)
  end

  # Delegated functions to sub-modules

  # Core functions
  defdelegate add_interval(stn, interval), to: Core
  defdelegate update_interval(stn, interval), to: Core
  defdelegate remove_interval(stn, interval_id), to: Core
  defdelegate add_constraint(stn, from_point, to_point, constraint), to: Core
  defdelegate consistent?(stn), to: Core
  defdelegate time_points(stn), to: Core
  defdelegate get_constraint(stn, from_point, to_point), to: Core
  defdelegate add_time_point(stn, time_point), to: Core

  # Interval query functions for scheduling
  defdelegate get_intervals(stn), to: Core
  defdelegate get_overlapping_intervals(stn, query_start, query_end), to: Core
  defdelegate find_free_slots(stn, duration, window_start, window_end), to: Core
  defdelegate check_interval_conflicts(stn, new_start, new_end), to: Core
  defdelegate find_next_available_slot(stn, duration, earliest_start), to: Core

  # PC2 functions
  defdelegate apply_pc2(stn), to: PC2
  # solve is in operations now
  defdelegate solve(stn), to: Operations

  # Units functions
  defdelegate rescale_lod(stn, new_lod_level), to: Units
  defdelegate convert_units(stn, new_unit), to: Units
  defdelegate from_datetime_intervals(intervals, opts), to: Units

  # Operations functions
  defdelegate intersection(stn1, stn2), to: Operations
  defdelegate difference(stn1, stn2), to: Operations
  defdelegate split(stn, num_segments), to: Operations
  defdelegate chain(stns), to: Operations
  defdelegate union(stn1, stn2), to: Operations
  defdelegate compose(stn1, stn2), to: Operations
  defdelegate parallel_join(stns), to: Operations
  defdelegate segment(stn, max_segments), to: Operations
  defdelegate parallel_solve(stn, max_segments), to: Operations

  # Private helper functions that were in the original STN module
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

    %{
      stn
      | time_points: MapSet.union(stn.time_points, dummy_points),
        dummy_constraints: dummy_constraints,
        constraints: Map.merge(stn.constraints, dummy_constraints)
    }
  end
end
