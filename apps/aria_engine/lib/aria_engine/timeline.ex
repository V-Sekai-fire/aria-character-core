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
      iex> alias AriaEngine.Timeline.Interval
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Interval.new(start_time, end_time)
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval)
      iex> length(Map.keys(timeline.intervals))
      1

  ## References

  - ADR-078: Timeline Module PC-2 STN Implementation
  - ADR-079: Timeline Module Implementation Progress
  - ADR-045: Allen's Interval Algebra Temporal Relationships
  - ADR-040: Temporal Constraint Solver Selection
  - ADR-046: Interval Notation Usability
  - ADR-006: Game Engine Real-time Execution (1ms tick requirement)
  """

  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.STN

  @type t :: %__MODULE__{
          intervals: %{Interval.id() => Interval.t()},
          stn: AriaEngine.Timeline.STN.t()
        }

  defstruct intervals: %{},
            stn: AriaEngine.Timeline.STN.new()

  @spec new(list(Interval.t())) :: t()
  def new(intervals \\ []) when is_list(intervals) do
    %__MODULE__{}
    |> add_intervals(intervals)
  end

  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, interval) do
    stn =
      timeline.stn
      |> STN.add_interval(interval)

    timeline
    |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
    |> Map.put(:stn, stn)
  end

  @spec add_intervals(t(), list(Interval.t())) :: t()
  def add_intervals(%__MODULE__{} = timeline, intervals) do
    Enum.reduce(intervals, timeline, &add_interval/2)
  end

  @spec get_interval(t(), Interval.id()) :: Interval.t() | nil
  def get_interval(%__MODULE__{intervals: intervals}, id) do
    intervals[id]
  end

  @spec update_interval(t(), Interval.t()) :: t()
  def update_interval(%__MODULE__{} = timeline, interval) do
    stn = STN.update_interval(timeline.stn, interval)

    timeline
    |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
    |> Map.put(:stn, stn)
  end

  @spec remove_interval(t(), Interval.id()) :: t()
  def remove_interval(%__MODULE__{} = timeline, id) do
    stn = STN.remove_interval(timeline.stn, id)

    timeline
    |> Map.put(:intervals, Map.delete(timeline.intervals, id))
    |> Map.put(:stn, stn)
  end

  @spec add_constraint(t(), String.t(), String.t(), {number(), number()}) :: t()
  def add_constraint(timeline, from_point, to_point, constraint) do
    stn = STN.add_constraint(timeline.stn, from_point, to_point, constraint)
    %{timeline | stn: stn}
  end

  @spec solve(t()) :: t()
  def solve(timeline) do
    stn = STN.solve(timeline.stn)
    %{timeline | stn: stn}
  end
end
