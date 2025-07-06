# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimelineIntervals.TimelineSegmenter do
  @moduledoc """
  Timeline segmentation utilities for dividing timelines into segments.

  This module provides functionality to segment timelines based on various
  criteria such as time windows, overlap detection, and temporal patterns.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineSegmenter}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> segments = TimelineSegmenter.segment_by_duration([interval1], 3600)
      iex> length(segments)
      2

  """

  alias AriaTimelineIntervals.Interval

  @type segment :: %{
          intervals: [Interval.t()],
          start_time: DateTime.t(),
          end_time: DateTime.t(),
          metadata: map()
        }

  @doc """
  Segments intervals by fixed duration windows.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineSegmenter}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> segments = TimelineSegmenter.segment_by_duration([interval1], 3600)
      iex> length(segments)
      2

  """
  @spec segment_by_duration([Interval.t()], integer()) :: [segment()]
  def segment_by_duration(intervals, duration_seconds) when is_list(intervals) and is_integer(duration_seconds) do
    case intervals do
      [] -> []
      _ ->
        {start_time, end_time} = calculate_bounds(intervals)
        create_time_windows(start_time, end_time, duration_seconds)
        |> Enum.map(&assign_intervals_to_window(&1, intervals))
        |> Enum.reject(&Enum.empty?(&1.intervals))
    end
  end

  @doc """
  Segments intervals by overlapping groups.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineSegmenter}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> interval2 = Interval.new(start2, end2)
      iex> segments = TimelineSegmenter.segment_by_overlaps([interval1, interval2])
      iex> length(segments)
      1

  """
  @spec segment_by_overlaps([Interval.t()]) :: [segment()]
  def segment_by_overlaps(intervals) when is_list(intervals) do
    intervals
    |> Enum.sort_by(& &1.start_time, DateTime)
    |> group_overlapping_intervals()
    |> Enum.map(&create_segment_from_group/1)
  end

  @doc """
  Segments intervals by gaps between them.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineSegmenter}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC")
      iex> interval2 = Interval.new(start2, end2)
      iex> segments = TimelineSegmenter.segment_by_gaps([interval1, interval2], 3600)
      iex> length(segments)
      2

  """
  @spec segment_by_gaps([Interval.t()], integer()) :: [segment()]
  def segment_by_gaps(intervals, max_gap_seconds) when is_list(intervals) and is_integer(max_gap_seconds) do
    intervals
    |> Enum.sort_by(& &1.start_time, DateTime)
    |> group_by_gaps(max_gap_seconds)
    |> Enum.map(&create_segment_from_group/1)
  end

  @doc """
  Finds gaps between intervals in a timeline.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineSegmenter}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC")
      iex> interval2 = Interval.new(start2, end2)
      iex> gaps = TimelineSegmenter.find_gaps([interval1, interval2])
      iex> length(gaps)
      1

  """
  @spec find_gaps([Interval.t()]) :: [Interval.t()]
  def find_gaps(intervals) when is_list(intervals) do
    intervals
    |> Enum.sort_by(& &1.start_time, DateTime)
    |> find_gaps_between_intervals()
  end

  @doc """
  Calculates the bounds (start and end times) of a list of intervals.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineSegmenter}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> {start_time, _end_time} = TimelineSegmenter.calculate_bounds([interval1])
      iex> start_time
      ~U[2025-01-01 10:00:00Z]

  """
  @spec calculate_bounds([Interval.t()]) :: {DateTime.t() | nil, DateTime.t() | nil}
  def calculate_bounds([]), do: {nil, nil}

  def calculate_bounds(intervals) when is_list(intervals) do
    start_times = Enum.map(intervals, & &1.start_time)
    end_times = Enum.map(intervals, & &1.end_time)

    start_time = Enum.min(start_times, DateTime)
    end_time = Enum.max(end_times, DateTime)

    {start_time, end_time}
  end

  # Private helper functions

  defp create_time_windows(start_time, end_time, duration_seconds) do
    window_count = ceil(DateTime.diff(end_time, start_time, :second) / duration_seconds)

    0..(window_count - 1)
    |> Enum.map(fn index ->
      window_start = DateTime.add(start_time, index * duration_seconds, :second)
      window_end = DateTime.add(start_time, (index + 1) * duration_seconds, :second)

      %{
        start_time: window_start,
        end_time: min(window_end, end_time),
        intervals: [],
        metadata: %{window_index: index, duration_seconds: duration_seconds}
      }
    end)
  end

  defp assign_intervals_to_window(window, intervals) do
    matching_intervals = Enum.filter(intervals, fn interval ->
      interval_overlaps_window?(interval, window.start_time, window.end_time)
    end)

    %{window | intervals: matching_intervals}
  end

  defp interval_overlaps_window?(interval, window_start, window_end) do
    DateTime.compare(interval.start_time, window_end) == :lt and
    DateTime.compare(interval.end_time, window_start) == :gt
  end

  defp group_overlapping_intervals(intervals) do
    Enum.reduce(intervals, [], fn interval, groups ->
      case find_overlapping_group(interval, groups) do
        nil ->
          groups ++ [[interval]]
        group_index ->
          List.update_at(groups, group_index, fn group -> group ++ [interval] end)
      end
    end)
  end

  defp find_overlapping_group(interval, groups) do
    case Enum.with_index(groups)
         |> Enum.find(fn {group, _index} ->
           Enum.any?(group, &Interval.overlaps?(&1, interval))
         end) do
      nil -> nil
      {_group, index} -> index
    end
  end

  defp group_by_gaps(intervals, max_gap_seconds) do
    Enum.reduce(intervals, [], fn interval, groups ->
      case find_group_within_gap(interval, groups, max_gap_seconds) do
        nil ->
          groups ++ [[interval]]
        {group_index, _group} ->
          List.update_at(groups, group_index, &(&1 ++ [interval]))
      end
    end)
  end

  defp find_group_within_gap(interval, groups, max_gap_seconds) do
    Enum.with_index(groups)
    |> Enum.find(fn {group, _index} ->
      last_interval = List.last(group)
      gap_seconds = DateTime.diff(interval.start_time, last_interval.end_time, :second)
      gap_seconds <= max_gap_seconds
    end)
  end

  defp find_gaps_between_intervals([]), do: []
  defp find_gaps_between_intervals([_single]), do: []

  defp find_gaps_between_intervals(intervals) do
    intervals
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [first, second] ->
      DateTime.compare(first.end_time, second.start_time) == :lt
    end)
    |> Enum.map(fn [first, second] ->
      Interval.new(first.end_time, second.start_time,
        metadata: %{gap: true, gap_duration_seconds: DateTime.diff(second.start_time, first.end_time, :second)})
    end)
  end

  defp create_segment_from_group(group) do
    {start_time, end_time} = calculate_bounds(group)

    %{
      intervals: group,
      start_time: start_time,
      end_time: end_time,
      metadata: %{
        interval_count: length(group),
        total_duration_seconds: DateTime.diff(end_time, start_time, :second)
      }
    }
  end
end
