# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimelineIntervals.TimelineBuilder do
  @moduledoc """
  Timeline construction utilities for building timelines from intervals.

  This module provides functionality to construct timelines from collections
  of intervals, with support for validation, sorting, and metadata management.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> timeline = TimelineBuilder.build([interval1])
      iex> length(timeline.intervals)
      1

  """

  alias AriaTimelineIntervals.Interval

  @type timeline :: %{
          intervals: [Interval.t()],
          start_time: DateTime.t() | nil,
          end_time: DateTime.t() | nil,
          metadata: map()
        }

  @doc """
  Builds a timeline from a list of intervals.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> timeline = TimelineBuilder.build([interval1])
      iex> length(timeline.intervals)
      1

  """
  @spec build([Interval.t()]) :: timeline()
  def build(intervals) when is_list(intervals) do
    build(intervals, [])
  end

  @doc """
  Builds a timeline from a list of intervals with options.

  ## Options

  - `:sort` - Whether to sort intervals by start time (default: true)
  - `:validate` - Whether to validate intervals (default: true)
  - `:metadata` - Additional metadata for the timeline

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> timeline = TimelineBuilder.build([interval1], sort: false)
      iex> length(timeline.intervals)
      1

  """
  @spec build([Interval.t()], keyword()) :: timeline()
  def build(intervals, opts) when is_list(intervals) and is_list(opts) do
    should_sort = Keyword.get(opts, :sort, true)
    should_validate = Keyword.get(opts, :validate, true)
    metadata = Keyword.get(opts, :metadata, %{})

    processed_intervals = intervals
    |> maybe_validate(should_validate)
    |> maybe_sort(should_sort)

    {start_time, end_time} = calculate_timeline_bounds(processed_intervals)

    %{
      intervals: processed_intervals,
      start_time: start_time,
      end_time: end_time,
      metadata: Map.merge(%{
        interval_count: length(processed_intervals),
        created_at: DateTime.utc_now()
      }, metadata)
    }
  end

  @doc """
  Validates a list of intervals.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> TimelineBuilder.validate_intervals([interval1])
      :ok

  """
  @spec validate_intervals([Interval.t()]) :: :ok | {:error, String.t()}
  def validate_intervals(intervals) when is_list(intervals) do
    case Enum.find_index(intervals, fn interval ->
      case Interval.validate(interval) do
        :ok -> false
        {:error, _} -> true
      end
    end) do
      nil -> :ok
      index -> {:error, "Invalid interval at index #{index}"}
    end
  end

  @doc """
  Sorts intervals by start time.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval2 = Interval.new(start2, end2)
      iex> sorted = TimelineBuilder.sort_intervals([interval1, interval2])
      iex> hd(sorted).start_time
      ~U[2025-01-01 10:00:00Z]

  """
  @spec sort_intervals([Interval.t()]) :: [Interval.t()]
  def sort_intervals(intervals) when is_list(intervals) do
    Enum.sort_by(intervals, & &1.start_time, DateTime)
  end

  @doc """
  Calculates the bounds (start and end times) of a timeline.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC")
      iex> interval2 = Interval.new(start2, end2)
      iex> {start_time, end_time} = TimelineBuilder.calculate_bounds([interval1, interval2])
      iex> start_time
      ~U[2025-01-01 10:00:00Z]
      iex> end_time
      ~U[2025-01-01 16:00:00Z]

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

  @doc """
  Merges multiple timelines into a single timeline.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, TimelineBuilder}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start1, end1)
      iex> timeline1 = TimelineBuilder.build([interval1])
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC")
      iex> interval2 = Interval.new(start2, end2)
      iex> timeline2 = TimelineBuilder.build([interval2])
      iex> merged = TimelineBuilder.merge([timeline1, timeline2])
      iex> length(merged.intervals)
      2

  """
  @spec merge([timeline()]) :: timeline()
  def merge(timelines) when is_list(timelines) do
    all_intervals = timelines
    |> Enum.flat_map(& &1.intervals)
    |> Enum.uniq_by(& &1.id)

    merged_metadata = timelines
    |> Enum.map(& &1.metadata)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Map.put(:merged_from_count, length(timelines))
    |> Map.put(:merged_at, DateTime.utc_now())

    build(all_intervals, metadata: merged_metadata)
  end

  # Private helper functions

  defp maybe_validate(intervals, true) do
    case validate_intervals(intervals) do
      :ok -> intervals
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  defp maybe_validate(intervals, false), do: intervals

  defp maybe_sort(intervals, true), do: sort_intervals(intervals)
  defp maybe_sort(intervals, false), do: intervals

  defp calculate_timeline_bounds(intervals) do
    calculate_bounds(intervals)
  end
end
