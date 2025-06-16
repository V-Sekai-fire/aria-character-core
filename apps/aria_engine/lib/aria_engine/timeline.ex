# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline do
  @moduledoc """
  Timeline module with interval-based storage using Path Consistency (PC-2) algorithm
  for Simple Temporal Network (STN) solving.

  Accepts time input in seconds but solves at 1ms tick precision.
  Supports Allen's interval algebra with usability improvements.
  Respects agent vs entity distinction in temporal constraints.

  ## Time Representation
  - External API: seconds (float/integer)
  - Internal storage/solving: milliseconds (integer)
  - Precision: 1ms ticks as per ADR-006

  ## Features
  - All 13 Allen interval relations
  - Path Consistency (PC-2) STN solving
  - Agent/entity distinction
  - Fluent API for constraint building
  - Comprehensive edge case handling

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = timeline
      ...> |> AriaEngine.Timeline.add_interval(:action1, 0.0, 5.5)
      ...> |> AriaEngine.Timeline.add_interval(:action2, 3.0, 8.0)
      ...> |> AriaEngine.Timeline.add_constraint(:action1, :action2, :overlaps)
      iex> timeline.consistent
      true

  ## References

  - ADR-078: Timeline Module PC-2 STN Implementation
  - ADR-079: Timeline Module Implementation Progress
  - ADR-045: Allen's Interval Algebra Temporal Relationships
  - ADR-040: Temporal Constraint Solver Selection
  - ADR-046: Interval Notation Usability
  - ADR-006: Game Engine Real-time Execution (1ms tick requirement)
  """

  alias AriaEngine.Timeline.{Interval, STN, IntervalRelations, TimeConverter}

  @type timeline :: %__MODULE__{
          intervals: %{atom() => Interval.t()},
          constraints: [constraint()],
          stn: STN.t() | nil,
          consistent: boolean(),
          metadata: map()
        }

  @type constraint :: %{
          from: atom(),
          to: atom(),
          relation: IntervalRelations.relation(),
          metadata: map()
        }

  defstruct intervals: %{},
            constraints: [],
            stn: nil,
            consistent: true,
            metadata: %{}

  @doc """
  Creates a new empty timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline.consistent
      true
      iex> timeline.intervals
      %{}

  """
  @spec new(map()) :: timeline()
  def new(metadata \\ %{}) do
    %__MODULE__{
      intervals: %{},
      constraints: [],
      stn: STN.new(),
      consistent: true,
      metadata: metadata
    }
  end

  @doc """
  Adds an interval to the timeline.
  Time values are expected in seconds and converted to milliseconds internally.

  ## Parameters

  - `timeline`: The timeline to add the interval to
  - `name`: Unique atom identifier for the interval
  - `start_seconds`: Start time in seconds (float/integer)
  - `end_seconds`: End time in seconds (float/integer)
  - `opts`: Optional parameters including:
    - `:label` - Human-readable label
    - `:agent` - Associated agent
    - `:entity` - Associated entity
    - `:metadata` - Additional metadata

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, :action1, 0.0, 5.5)
      iex> timeline.intervals[:action1].start_ms
      0
      iex> timeline.intervals[:action1].end_ms
      5500

  """
  @spec add_interval(timeline(), atom(), number(), number(), keyword()) :: timeline()
  def add_interval(timeline, name, start_seconds, end_seconds, opts \\ []) do
    case TimeConverter.safe_interval_to_ms(start_seconds, end_seconds) do
      {:ok, {start_ms, end_ms}} ->
        interval = Interval.new(name, start_ms, end_ms, opts)
        
        updated_timeline = %{timeline | 
          intervals: Map.put(timeline.intervals, name, interval)
        }
        
        # Update STN with new interval
        updated_stn = STN.add_interval(timeline.stn, interval)
        %{updated_timeline | stn: updated_stn}
      
      {:error, reason} ->
        raise ArgumentError, reason
    end
  end

  @doc """
  Adds a temporal constraint between two intervals using Allen's relations.

  ## Parameters

  - `timeline`: The timeline to add the constraint to
  - `from`: Source interval name (atom)
  - `to`: Target interval name (atom)
  - `relation`: Allen relation (see AllenRelations module)
  - `metadata`: Optional metadata map

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = timeline
      ...> |> AriaEngine.Timeline.add_interval(:a, 0, 5)
      ...> |> AriaEngine.Timeline.add_interval(:b, 3, 8)
      ...> |> AriaEngine.Timeline.add_constraint(:a, :b, :overlaps)
      iex> timeline.consistent
      true

  """
  @spec add_constraint(timeline(), atom(), atom(), IntervalRelations.relation(), map()) :: timeline()
  def add_constraint(timeline, from, to, relation, metadata \\ %{}) do
    unless Map.has_key?(timeline.intervals, from) do
      raise ArgumentError, "Interval #{from} not found in timeline"
    end
    
    unless Map.has_key?(timeline.intervals, to) do
      raise ArgumentError, "Interval #{to} not found in timeline"
    end

    unless IntervalRelations.valid_relation?(relation) do
      raise ArgumentError, "Invalid Allen relation: #{relation}"
    end

    constraint = %{
      from: from,
      to: to,
      relation: relation,
      metadata: metadata
    }

    updated_constraints = [constraint | timeline.constraints]
    
    # Convert Allen constraint to STN constraint and add to STN
    from_interval = timeline.intervals[from]
    to_interval = timeline.intervals[to]
    
    updated_stn = STN.add_allen_constraint(timeline.stn, from_interval, to_interval, relation)
    
    %{timeline | constraints: updated_constraints, stn: updated_stn}
  end

  @doc """
  Solves the timeline using Path Consistency (PC-2) algorithm.
  Returns updated timeline with consistency information.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = timeline
      ...> |> AriaEngine.Timeline.add_interval(:a, 0, 5)
      ...> |> AriaEngine.Timeline.add_interval(:b, 3, 8)
      ...> |> AriaEngine.Timeline.add_constraint(:a, :b, :overlaps)
      ...> |> AriaEngine.Timeline.solve()
      iex> timeline.consistent
      true

  """
  @spec solve(timeline()) :: timeline()
  def solve(timeline) do
    solved_stn = STN.apply_pc2(timeline.stn)
    consistent = STN.consistent?(solved_stn)
    
    %{timeline | stn: solved_stn, consistent: consistent}
  end

  @doc """
  Solves the timeline using parallel STN segments to avoid O(n³) complexity.
  
  This method automatically segments the STN and solves segments in parallel,
  providing significant performance improvements for large timelines.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = timeline
      ...> |> AriaEngine.Timeline.add_interval(:a, 0, 5)
      ...> |> AriaEngine.Timeline.add_interval(:b, 3, 8)
      ...> |> AriaEngine.Timeline.add_constraint(:a, :b, :overlaps)
      ...> |> AriaEngine.Timeline.parallel_solve()
      iex> timeline.consistent
      true

  """
  @spec parallel_solve(timeline(), integer()) :: timeline()
  def parallel_solve(timeline, max_segments \\ System.schedulers_online()) do
    solved_stn = STN.parallel_solve(timeline.stn, max_segments)
    consistent = STN.consistent?(solved_stn)
    
    %{timeline | stn: solved_stn, consistent: consistent}
  end

  @doc """
  Combines multiple timelines using STN union operations.
  
  This allows composing complex timelines from simpler ones,
  enabling modular timeline construction.

  ## Examples

      iex> timeline1 = AriaEngine.Timeline.new()
      ...> |> AriaEngine.Timeline.add_interval(:a, 0, 5)
      iex> timeline2 = AriaEngine.Timeline.new()
      ...> |> AriaEngine.Timeline.add_interval(:b, 3, 8)
      iex> combined = AriaEngine.Timeline.union(timeline1, timeline2)
      iex> map_size(combined.intervals)
      2

  """
  @spec union(timeline(), timeline()) :: timeline()
  def union(timeline1, timeline2) do
    # Merge intervals
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)
    
    # Merge constraints
    merged_constraints = timeline1.constraints ++ timeline2.constraints
    
    # Union STNs
    merged_stn = STN.union(timeline1.stn, timeline2.stn)
    
    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)
    
    %{timeline1 | 
      intervals: merged_intervals,
      constraints: merged_constraints,
      stn: merged_stn,
      consistent: timeline1.consistent and timeline2.consistent,
      metadata: merged_metadata
    }
  end

  @doc """
  Composes timelines sequentially, creating execution chains.
  
  ## Examples

      iex> phase1 = AriaEngine.Timeline.new()
      ...> |> AriaEngine.Timeline.add_interval(:setup, 0, 2)
      iex> phase2 = AriaEngine.Timeline.new()
      ...> |> AriaEngine.Timeline.add_interval(:execute, 0, 5)
      iex> workflow = AriaEngine.Timeline.compose(phase1, phase2)
      iex> workflow.consistent
      true

  """
  @spec compose(timeline(), timeline()) :: timeline()
  def compose(timeline1, timeline2) do
    # Compose STNs
    composed_stn = STN.compose(timeline1.stn, timeline2.stn)
    
    # Union other components
    union(timeline1, timeline2)
    |> Map.put(:stn, composed_stn)
  end

  @doc """
  Checks if the timeline is temporally consistent.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> AriaEngine.Timeline.consistent?(timeline)
      true

  """
  @spec consistent?(timeline()) :: boolean()
  def consistent?(timeline) do
    timeline.consistent
  end

  @doc """
  Gets all intervals in the timeline as a list.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, :action1, 0, 5)
      iex> intervals = AriaEngine.Timeline.intervals(timeline)
      iex> length(intervals)
      1

  """
  @spec intervals(timeline()) :: [Interval.t()]
  def intervals(timeline) do
    Map.values(timeline.intervals)
  end

  @doc """
  Gets a specific interval by name.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, :action1, 0, 5)
      iex> interval = AriaEngine.Timeline.get_interval(timeline, :action1)
      iex> interval.name
      :action1

  """
  @spec get_interval(timeline(), atom()) :: Interval.t() | nil
  def get_interval(timeline, name) do
    Map.get(timeline.intervals, name)
  end

  @doc """
  Gets the earliest possible start time for an interval in seconds.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = timeline
      ...> |> AriaEngine.Timeline.add_interval(:action1, 0, 5)
      ...> |> AriaEngine.Timeline.solve()
      iex> AriaEngine.Timeline.earliest_start(timeline, :action1)
      0.0

  """
  @spec earliest_start(timeline(), atom()) :: float() | nil
  def earliest_start(timeline, interval_name) do
    case timeline.stn do
      nil -> nil
      stn -> 
        case STN.earliest_start(stn, interval_name) do
          nil -> nil
          ms -> TimeConverter.ms_to_seconds(ms)
        end
    end
  end

  @doc """
  Gets the latest possible end time for an interval in seconds.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> timeline = timeline
      ...> |> AriaEngine.Timeline.add_interval(:action1, 0, 5)
      ...> |> AriaEngine.Timeline.solve()
      iex> AriaEngine.Timeline.latest_end(timeline, :action1)
      5.0

  """
  @spec latest_end(timeline(), atom()) :: float() | nil
  def latest_end(timeline, interval_name) do
    case timeline.stn do
      nil -> nil
      stn ->
        case STN.latest_end(stn, interval_name) do
          nil -> nil
          ms -> TimeConverter.ms_to_seconds(ms)
        end
    end
  end

  # Fluent API for building constraints - usability improvements from ADR-046
  
  @doc """
  Fluent API for building constraints.
  
  ## Examples

      timeline
      |> before(:a, :b)
      |> meets(:b, :c)
      |> overlaps(:c, :d)

  """
  def before(timeline, from, to), do: add_constraint(timeline, from, to, :before)
  def after(timeline, from, to), do: add_constraint(timeline, from, to, :after)
  def meets(timeline, from, to), do: add_constraint(timeline, from, to, :meets)
  def met_by(timeline, from, to), do: add_constraint(timeline, from, to, :met_by)
  def overlaps(timeline, from, to), do: add_constraint(timeline, from, to, :overlaps)
  def overlapped_by(timeline, from, to), do: add_constraint(timeline, from, to, :overlapped_by)
  def starts(timeline, from, to), do: add_constraint(timeline, from, to, :starts)
  def started_by(timeline, from, to), do: add_constraint(timeline, from, to, :started_by)
  def during(timeline, from, to), do: add_constraint(timeline, from, to, :during)
  def contains(timeline, from, to), do: add_constraint(timeline, from, to, :contains)
  def finishes(timeline, from, to), do: add_constraint(timeline, from, to, :finishes)
  def finished_by(timeline, from, to), do: add_constraint(timeline, from, to, :finished_by)
  def equals(timeline, from, to), do: add_constraint(timeline, from, to, :equals)

  # Forward Allen's Interval Algebra operations for interval queries
  # These provide the improved usability features requested in ADR-046

  @doc """
  Checks if interval1 occurs before interval2.
  
  This is Allen's 'before' relation with improved usability.
  """
  def before?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.before?(interval1, interval2)
    else
      false
    end
  end

  @doc """
  Checks if interval1 meets interval2.
  
  This is Allen's 'meets' relation with improved usability.
  """
  def meets?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)  
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.meets?(interval1, interval2)
    else
      false
    end
  end

  @doc """
  Checks if interval1 overlaps interval2.
  
  This is Allen's 'overlaps' relation with improved usability.
  """
  def overlaps?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.overlaps?(interval1, interval2)
    else
      false
    end
  end

  @doc """
  Checks if interval1 starts interval2.
  
  This is Allen's 'starts' relation with improved usability.
  """
  def starts?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.starts?(interval1, interval2)
    else
      false
    end
  end

  @doc """
  Checks if interval1 is during interval2.
  
  This is Allen's 'during' relation with improved usability.
  """
  def during?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.during?(interval1, interval2)
    else
      false
    end
  end

  @doc """
  Checks if interval1 finishes interval2.
  
  This is Allen's 'finishes' relation with improved usability.
  """
  def finishes?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.finishes?(interval1, interval2)
    else
      false
    end
  end

  @doc """
  Checks if interval1 equals interval2.
  
  This is Allen's 'equals' relation with improved usability.
  """
  def equals?(timeline, interval1_name, interval2_name) do
    interval1 = get_interval(timeline, interval1_name)
    interval2 = get_interval(timeline, interval2_name)
    
    if interval1 && interval2 do
      IntervalRelations.equals?(interval1, interval2)
    else
      false
    end
  end
end
