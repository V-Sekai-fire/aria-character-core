# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Bridge.Constraints do
  @moduledoc """
  STN constraint generation for temporal relations.

  Converts high-level temporal relations into valid STN constraints while
  preventing contract violations such as zero-duration specifications.
  """

  alias Timeline.Interval
  alias Timeline.Internal.STN
  alias Timeline.Bridge.Relations

  @type temporal_constraint :: {number(), number()}
  @type constraint_result :: {:ok, temporal_constraint()} | {:error, atom()}

  # Minimum duration threshold to prevent zero-duration contract violations
  @min_duration_threshold 1

  @doc """
  Generates STN constraints for a temporal relation between two intervals.

  This function implements the core Bridge layer functionality, converting high-level
  temporal relations into valid STN constraints while preventing contract violations.

  ## Examples

      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Timeline.Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> interval2 = Timeline.Interval.new(start2, end2)
      iex> {:ok, constraint} = Timeline.Bridge.Constraints.generate_stn_constraint(interval1, interval2, :second)
      iex> constraint
      {-1, 1}

  """
  @spec generate_stn_constraint(Interval.t(), Interval.t(), STN.time_unit()) ::
          constraint_result()
  def generate_stn_constraint(%Interval{} = interval1, %Interval{} = interval2, time_unit) do
    relation = Relations.classify_relation(interval1, interval2)

    # Validate intervals before constraint generation
    with :ok <- validate_interval_duration(interval1, time_unit),
         :ok <- validate_interval_duration(interval2, time_unit) do
      generate_constraint_for_relation(interval1, interval2, relation, time_unit)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validates that an interval meets STN contract requirements.

  Prevents zero-duration and other invalid specifications from reaching the STN solver.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> Timeline.Bridge.Constraints.validate_interval_for_stn(interval, :second)
      :ok

  """
  @spec validate_interval_for_stn(Interval.t(), STN.time_unit()) :: :ok | {:error, atom()}
  def validate_interval_for_stn(%Interval{} = interval, time_unit) do
    validate_interval_duration(interval, time_unit)
  end

  @doc """
  Filters a list of intervals to remove those that would cause STN contract violations.

  Returns only intervals that can be safely processed by the STN solver.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> valid_interval = Timeline.Interval.new(start_dt, end_dt)
      iex> zero_interval = Timeline.Interval.new(start_dt, start_dt)
      iex> Timeline.Bridge.Constraints.filter_valid_intervals([valid_interval, zero_interval], :second)
      [valid_interval]

  """
  @spec filter_valid_intervals([Interval.t()], STN.time_unit()) :: [Interval.t()]
  def filter_valid_intervals(intervals, time_unit) when is_list(intervals) do
    Enum.filter(intervals, fn interval ->
      case validate_interval_for_stn(interval, time_unit) do
        :ok -> true
        {:error, _} -> false
      end
    end)
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  defp validate_interval_duration(
         %Interval{start_time: start_time, end_time: end_time},
         time_unit
       ) do
    duration_in_unit = calculate_duration_in_unit(start_time, end_time, time_unit)

    cond do
      duration_in_unit < @min_duration_threshold ->
        {:error, :zero_duration_violation}

      duration_in_unit < 0 ->
        {:error, :negative_duration}

      true ->
        :ok
    end
  end

  defp calculate_duration_in_unit(start_time, end_time, time_unit) do
    case time_unit do
      :microsecond -> DateTime.diff(end_time, start_time, :microsecond)
      :millisecond -> DateTime.diff(end_time, start_time, :millisecond)
      :second -> DateTime.diff(end_time, start_time, :second)
      :minute -> div(DateTime.diff(end_time, start_time, :second), 60)
      :hour -> div(DateTime.diff(end_time, start_time, :second), 3600)
      :day -> div(DateTime.diff(end_time, start_time, :second), 86400)
    end
  end

  defp generate_constraint_for_relation(interval1, interval2, relation, time_unit) do
    case relation do
      :EQ ->
        # Equal intervals - convert fixed-point to micro-range
        {:ok, {-1, 1}}

      :ADJ_F ->
        # interval1 meets interval2 - convert fixed-point to micro-range
        {:ok, {-1, 1}}

      :ADJ_B ->
        # interval2 meets interval1 - convert fixed-point to micro-range
        {:ok, {-1, 1}}

      :PRECEDES ->
        # interval1 before interval2 - positive gap between them
        gap = calculate_gap_between_intervals(interval1, interval2, time_unit)
        # Convert fixed-point to micro-range
        {:ok, {max(gap - 1, 0), gap + 1}}

      :FOLLOWS ->
        # interval1 after interval2 - negative gap (interval2 before interval1)
        gap = calculate_gap_between_intervals(interval2, interval1, time_unit)
        # Convert fixed-point to micro-range
        {:ok, {-gap - 1, max(-gap + 1, 1)}}

      :OVERLAP_F ->
        # interval1 overlaps interval2 forward
        overlap = calculate_overlap_constraint(interval1, interval2, time_unit)
        {:ok, overlap}

      :OVERLAP_B ->
        # interval1 overlapped by interval2
        overlap = calculate_overlap_constraint(interval2, interval1, time_unit)
        {:ok, {-elem(overlap, 1), -elem(overlap, 0)}}

      :WITHIN ->
        # interval1 during interval2
        {:ok, generate_containment_constraint(interval1, interval2, time_unit)}

      :CONTAINS ->
        # interval1 contains interval2
        constraint = generate_containment_constraint(interval2, interval1, time_unit)
        {:ok, {-elem(constraint, 1), -elem(constraint, 0)}}

      :START_ALIGN ->
        # interval1 starts interval2 - same start, different end
        {:ok, {-1, 1}}

      :START_EXTEND ->
        # interval1 started by interval2 - same start, interval1 extends
        {:ok, {-1, 1}}

      :END_ALIGN ->
        # interval1 finishes interval2 - same end, different start
        {:ok, {-1, 1}}

      :END_EXTEND ->
        # interval1 finished by interval2 - same end, interval1 extends
        {:ok, {-1, 1}}

      _ ->
        # Default case - treat as equal
        {:ok, {-1, 1}}
    end
  end

  defp calculate_gap_between_intervals(interval1, interval2, time_unit) do
    gap_microseconds = DateTime.diff(interval2.start_time, interval1.end_time, :microsecond)
    convert_microseconds_to_unit(gap_microseconds, time_unit)
  end

  defp calculate_overlap_constraint(interval1, interval2, time_unit) do
    # Calculate the overlap duration and position
    overlap_start = max_datetime(interval1.start_time, interval2.start_time)
    overlap_end = min_datetime(interval1.end_time, interval2.end_time)

    if DateTime.compare(overlap_start, overlap_end) == :lt do
      overlap_duration = DateTime.diff(overlap_end, overlap_start, :microsecond)
      overlap_in_unit = convert_microseconds_to_unit(overlap_duration, time_unit)
      # Convert fixed-point to micro-range if needed
      if overlap_in_unit == 0 do
        {-1, 1}
      else
        {max(overlap_in_unit - 1, 0), overlap_in_unit + 1}
      end
    else
      # No overlap - convert fixed-point to micro-range
      {-1, 1}
    end
  end

  defp generate_containment_constraint(inner_interval, outer_interval, time_unit) do
    # Calculate the temporal distance from outer start to inner start
    start_offset =
      DateTime.diff(inner_interval.start_time, outer_interval.start_time, :microsecond)

    start_offset_in_unit = convert_microseconds_to_unit(start_offset, time_unit)

    # Calculate the temporal distance from inner end to outer end
    end_offset = DateTime.diff(outer_interval.end_time, inner_interval.end_time, :microsecond)
    end_offset_in_unit = convert_microseconds_to_unit(end_offset, time_unit)

    {start_offset_in_unit, start_offset_in_unit + end_offset_in_unit}
  end

  defp convert_microseconds_to_unit(microseconds, time_unit) do
    case time_unit do
      :microsecond -> microseconds
      :millisecond -> div(microseconds, 1000)
      :second -> div(microseconds, 1_000_000)
      :minute -> div(microseconds, 60_000_000)
      :hour -> div(microseconds, 3_600_000_000)
      :day -> div(microseconds, 86_400_000_000)
    end
  end

  defp max_datetime(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :gt -> dt1
      _ -> dt2
    end
  end

  defp min_datetime(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :lt -> dt1
      _ -> dt2
    end
  end
end
