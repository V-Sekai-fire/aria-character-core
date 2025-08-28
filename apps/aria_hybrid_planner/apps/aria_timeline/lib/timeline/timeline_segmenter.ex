# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.TimelineSegmenter do
  @moduledoc "Timeline segmentation functionality for breaking timelines into manageable chunks.\n\nThis module handles:\n- Timeline segmentation by bridge positions\n- Segment creation and validation\n- Time range analysis and bounds calculation\n- Segment metadata management\n\nSegmentation is useful for parallel processing, analysis, and execution\nof large timelines by breaking them into smaller, independent segments.\n"
  alias Timeline.Bridge
  alias Timeline.Interval
  alias Timeline.Internal.STN

  @type timeline :: %{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: STN.t(),
          metadata: map()
        }
  @doc "Segments the timeline by bridge positions.\n\nReturns a list of timeline segments, where each segment contains intervals\nthat occur between bridge points. Each segment is a complete Timeline\nwith proper DateTime intervals.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start1 = DateTime.from_naive!(2025-01-01T10:00:00Z, \"Etc/UTC\")\n    iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> interval1 =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start1),\n    DateTime.to_iso8601(end1)\n  )\n    iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval1)\n    iex> bridge_pos = DateTime.from_naive!(~N[2025-01-01 10:30:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", bridge_pos, :decision)\n    iex> timeline = AriaEngine.Timeline.add_bridge(timeline, bridge)\n    iex> segments = AriaEngine.Timeline.Segmentation.segment_by_bridges(timeline)\n    iex> length(segments)\n    2\n\n"
  @spec segment_by_bridges(timeline()) :: [timeline()]
  def segment_by_bridges(timeline) do
    bridges = get_sorted_bridges(timeline)

    case bridges do
      [] -> [%{timeline | metadata: Map.put(timeline.metadata, :segment, 1)}]
      _ -> create_segments_from_bridges(timeline, bridges)
    end
  end

  @doc "Gets the temporal bounds of a timeline (earliest start, latest end).\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start1 = DateTime.from_naive!(2025-01-01T10:00:00Z, \"Etc/UTC\")\n    iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> interval1 =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start1),\n    DateTime.to_iso8601(end1)\n  )\n    iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval1)\n    iex> {start_time, end_time} = AriaEngine.Timeline.Segmentation.get_timeline_bounds(timeline)\n    iex> DateTime.compare(start_time, start1)\n    :eq\n\n"
  @spec get_timeline_bounds(timeline()) :: {DateTime.t(), DateTime.t()}
  def get_timeline_bounds(timeline) when map_size(timeline.intervals) == 0 do
    start_time = "2025-01-01T00:00:00Z"
    end_time = "2025-01-01T23:59:59Z"
    {start_time, end_time}
  end

  def get_timeline_bounds(timeline) do
    interval_list = Map.values(timeline.intervals)
    start_time = interval_list |> Enum.map(& &1.start_time) |> Enum.min(DateTime)
    end_time = interval_list |> Enum.map(& &1.end_time) |> Enum.max(DateTime)
    {start_time, end_time}
  end

  @doc "Creates time ranges for segmentation based on bridge positions.\n\nReturns a list of {start_time, end_time, bridge_before} tuples representing\nthe time ranges for each segment.\n"
  @spec create_time_ranges(timeline(), [DateTime.t()]) :: [
          {DateTime.t(), DateTime.t(), DateTime.t() | nil}
        ]
  def create_time_ranges(timeline, bridge_positions) do
    {timeline_start, timeline_end} = get_timeline_bounds(timeline)
    all_boundaries = [timeline_start] ++ bridge_positions ++ [timeline_end]

    all_boundaries
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.map(fn {[start_time, end_time], index} ->
      bridge_before =
        if index == 0 do
          nil
        else
          Enum.at(bridge_positions, index - 1)
        end

      {start_time, end_time, bridge_before}
    end)
  end

  @doc "Creates a single timeline segment for the given time range.\n\nFilters intervals that fall within the segment's time range and creates\nappropriate metadata for the segment.\n"
  @spec create_segment(timeline(), DateTime.t(), DateTime.t(), pos_integer(), DateTime.t() | nil) ::
          timeline()
  def create_segment(timeline, start_time, end_time, segment_num, bridge_before) do
    segment_intervals =
      timeline.intervals
      |> Enum.filter(fn {_id, interval} -> interval_in_range?(interval, start_time, end_time) end)
      |> Map.new()

    segment_metadata =
      timeline.metadata
      |> Map.put(:segment, segment_num)
      |> Map.put(:bridge_before, bridge_before)
      |> Map.put(:segment_start, start_time)
      |> Map.put(:segment_end, end_time)

    %{intervals: segment_intervals, bridges: %{}, stn: STN.new(), metadata: segment_metadata}
  end

  @doc "Checks if an interval overlaps with a given time range.\n\nAn interval overlaps with the range if:\n- interval start is before range end AND\n- interval end is after range start\n"
  @spec interval_in_range?(Interval.t(), DateTime.t(), DateTime.t()) :: boolean()
  def interval_in_range?(
        %Interval{start_time: start_time, end_time: end_time},
        range_start,
        range_end
      ) do
    DateTime.compare(start_time, range_end) == :lt and
      DateTime.compare(end_time, range_start) == :gt
  end

  @doc "Checks if a timeline segment is empty (contains no intervals).\n"
  @spec segment_empty?(timeline()) :: boolean()
  def segment_empty?(timeline) do
    map_size(timeline.intervals) == 0
  end

  @doc "Filters out empty segments from a list of timeline segments.\n"
  @spec filter_empty_segments([timeline()]) :: [timeline()]
  def filter_empty_segments(segments) do
    Enum.reject(segments, &segment_empty?/1)
  end

  @doc "Gets segment metadata for a timeline segment.\n\nReturns a map containing segment information like segment number,\ntime bounds, and associated bridge information.\n"
  @spec get_segment_metadata(timeline()) :: map()
  def get_segment_metadata(timeline) do
    Map.take(timeline.metadata, [:segment, :bridge_before, :segment_start, :segment_end])
  end

  @doc "Validates that all segments in a list are properly formed.\n\nChecks that segments have proper metadata, non-overlapping time ranges,\nand valid interval assignments.\n"
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

  defp get_sorted_bridges(timeline) do
    timeline.bridges |> Map.values() |> Bridge.sort_by_position()
  end

  defp create_segments_from_bridges(timeline, bridges) do
    bridge_positions = Enum.map(bridges, & &1.position)
    time_ranges = create_time_ranges(timeline, bridge_positions)

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
