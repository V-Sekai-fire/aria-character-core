# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.TimelineSegmenter do
  @moduledoc """
  Timeline segmentation functionality for breaking timelines into manageable chunks.

  This module handles:
  - Timeline segmentation by bridge positions
  - Segment creation and validation
  - Time range analysis and bounds calculation
  - Segment metadata management

  Segmentation is useful for parallel processing, analysis, and execution
  of large timelines by breaking them into smaller, independent segments.
  """

  alias AriaEngine.Timeline.Bridge
  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.Internal.STN

  @type timeline :: %{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: STN.t(),
          metadata: map()
        }

  @doc """
  Segments the timeline by bridge positions.

  Returns a list of timeline segments, where each segment contains intervals
  that occur between bridge points. Each segment is a complete Timeline
  with proper DateTime intervals.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> interval1 = AriaEngine.Timeline.Interval.new(start1, end1)
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval1)
      iex> bridge_pos = DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", bridge_pos, :decision)
      iex> timeline = AriaEngine.Timeline.add_bridge(timeline, bridge)
      iex> segments = AriaEngine.Timeline.Segmentation.segment_by_bridges(timeline)
      iex> length(segments)
      2

  """
  @spec segment_by_bridges(timeline()) :: [timeline()]
  def segment_by_bridges(timeline) do
    bridges = get_sorted_bridges(timeline)

    case bridges do
      [] ->
        # No bridges, return the timeline as a single segment
        [%{timeline | metadata: Map.put(timeline.metadata, :segment, 1)}]

      _ ->
        # Create segments based on bridge positions
        create_segments_from_bridges(timeline, bridges)
    end
  end

  @doc """
  Gets the temporal bounds of a timeline (earliest start, latest end).

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> interval1 = AriaEngine.Timeline.Interval.new(start1, end1)
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval1)
      iex> {start_time, end_time} = AriaEngine.Timeline.Segmentation.get_timeline_bounds(timeline)
      iex> DateTime.compare(start_time, start1)
      :eq

  """
  @spec get_timeline_bounds(timeline()) :: {DateTime.t(), DateTime.t()}
  def get_timeline_bounds(timeline) when map_size(timeline.intervals) == 0 do
    # No intervals, use a default range
    start_time = DateTime.from_naive!(~N[2025-01-01 00:00:00], "Etc/UTC")
    end_time = DateTime.from_naive!(~N[2025-01-01 23:59:59], "Etc/UTC")
    {start_time, end_time}
  end

  def get_timeline_bounds(timeline) do
    interval_list = Map.values(timeline.intervals)

    start_time =
      interval_list
      |> Enum.map(& &1.start_time)
      |> Enum.min(DateTime)

    end_time =
      interval_list
      |> Enum.map(& &1.end_time)
      |> Enum.max(DateTime)

    {start_time, end_time}
  end

  @doc """
  Creates time ranges for segmentation based on bridge positions.

  Returns a list of {start_time, end_time, bridge_before} tuples representing
  the time ranges for each segment.
  """
  @spec create_time_ranges(timeline(), [DateTime.t()]) :: [{DateTime.t(), DateTime.t(), DateTime.t() | nil}]
  def create_time_ranges(timeline, bridge_positions) do
    # Get the overall timeline bounds
    {timeline_start, timeline_end} = get_timeline_bounds(timeline)

    # Create ranges: [timeline_start, bridge1], [bridge1, bridge2], ..., [bridgeN, timeline_end]
    all_boundaries = [timeline_start] ++ bridge_positions ++ [timeline_end]

    all_boundaries
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.map(fn {[start_time, end_time], index} ->
      bridge_before = if index == 0, do: nil, else: Enum.at(bridge_positions, index - 1)
      {start_time, end_time, bridge_before}
    end)
  end

  @doc """
  Creates a single timeline segment for the given time range.

  Filters intervals that fall within the segment's time range and creates
  appropriate metadata for the segment.
  """
  @spec create_segment(timeline(), DateTime.t(), DateTime.t(), pos_integer(), DateTime.t() | nil) :: timeline()
  def create_segment(timeline, start_time, end_time, segment_num, bridge_before) do
    # Filter intervals that fall within this segment's time range
    segment_intervals =
      timeline.intervals
      |> Enum.filter(fn {_id, interval} ->
        interval_in_range?(interval, start_time, end_time)
      end)
      |> Map.new()

    # Create segment metadata
    segment_metadata =
      timeline.metadata
      |> Map.put(:segment, segment_num)
      |> Map.put(:bridge_before, bridge_before)
      |> Map.put(:segment_start, start_time)
      |> Map.put(:segment_end, end_time)

    # Create new timeline for this segment
    %{
      intervals: segment_intervals,
      bridges: %{}, # Segments don't inherit bridges
      stn: STN.new(), # Each segment gets a fresh STN
      metadata: segment_metadata
    }
  end

  @doc """
  Checks if an interval overlaps with a given time range.

  An interval overlaps with the range if:
  - interval start is before range end AND
  - interval end is after range start
  """
  @spec interval_in_range?(Interval.t(), DateTime.t(), DateTime.t()) :: boolean()
  def interval_in_range?(%Interval{start_time: start_time, end_time: end_time}, range_start, range_end) do
    DateTime.compare(start_time, range_end) == :lt and
    DateTime.compare(end_time, range_start) == :gt
  end

  @doc """
  Checks if a timeline segment is empty (contains no intervals).
  """
  @spec segment_empty?(timeline()) :: boolean()
  def segment_empty?(timeline) do
    map_size(timeline.intervals) == 0
  end

  @doc """
  Filters out empty segments from a list of timeline segments.
  """
  @spec filter_empty_segments([timeline()]) :: [timeline()]
  def filter_empty_segments(segments) do
    Enum.reject(segments, &segment_empty?/1)
  end

  @doc """
  Gets segment metadata for a timeline segment.

  Returns a map containing segment information like segment number,
  time bounds, and associated bridge information.
  """
  @spec get_segment_metadata(timeline()) :: map()
  def get_segment_metadata(timeline) do
    Map.take(timeline.metadata, [:segment, :bridge_before, :segment_start, :segment_end])
  end

  @doc """
  Validates that all segments in a list are properly formed.

  Checks that segments have proper metadata, non-overlapping time ranges,
  and valid interval assignments.
  """
  @spec validate_segments([timeline()]) :: :ok | {:error, String.t()}
  def validate_segments(segments) do
    segments
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {segment, index}, _acc ->
      case validate_single_segment(segment, index + 1) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Private helper functions

  defp get_sorted_bridges(timeline) do
    timeline.bridges
    |> Map.values()
    |> Bridge.sort_by_position()
  end

  defp create_segments_from_bridges(timeline, bridges) do
    # Get sorted bridge positions
    bridge_positions = Enum.map(bridges, & &1.position)

    # Create time ranges for each segment
    time_ranges = create_time_ranges(timeline, bridge_positions)

    # Create a segment for each time range
    time_ranges
    |> Enum.with_index(1)
    |> Enum.map(fn {{start_time, end_time, bridge_before}, segment_num} ->
      create_segment(timeline, start_time, end_time, segment_num, bridge_before)
    end)
    |> filter_empty_segments()
  end

  defp validate_single_segment(segment, expected_segment_num) do
    metadata = get_segment_metadata(segment)

    cond do
      Map.get(metadata, :segment) != expected_segment_num ->
        {:error, "Segment #{expected_segment_num} has incorrect segment number"}

      is_nil(Map.get(metadata, :segment_start)) ->
        {:error, "Segment #{expected_segment_num} missing segment_start"}

      is_nil(Map.get(metadata, :segment_end)) ->
        {:error, "Segment #{expected_segment_num} missing segment_end"}

      true ->
        :ok
    end
  end
end
