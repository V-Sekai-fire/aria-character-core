# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimelineIntervals do
  @moduledoc """
  Core interval operations, Allen relations, and timeline functionality for AriaEngine.

  This module provides the foundational interval-based operations including:
  - Interval creation and manipulation
  - Allen's interval algebra relations
  - Timeline construction and segmentation
  - Time conversion utilities

  ## Time Representation
  - External API: seconds (float/integer)
  - Internal storage/solving: milliseconds (integer)
  - Precision: 1ms ticks as per ADR-006

  ## Features
  - All 13 Allen interval relations
  - Interval operations and validation
  - Timeline building and segmentation
  - Time conversion utilities

  ## Examples

      iex> alias AriaTimelineIntervals.Interval
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Interval.new(start_time, end_time)
      iex> interval.id != nil
      true

  """

  alias AriaTimelineIntervals.{Interval, AllenRelations, TimeConverter, TimelineBuilder, TimelineSegmenter}

  # Re-export key functions for convenience
  defdelegate new_interval(start_time, end_time), to: Interval, as: :new
  defdelegate new_interval(start_time, end_time, opts), to: Interval, as: :new
  defdelegate validate_interval(interval), to: Interval, as: :validate
  defdelegate duration(interval), to: Interval

  defdelegate allen_relation(interval1, interval2), to: AllenRelations, as: :relation
  defdelegate satisfies_relation?(interval1, interval2, relation), to: AllenRelations

  defdelegate seconds_to_milliseconds(seconds), to: TimeConverter
  defdelegate milliseconds_to_seconds(milliseconds), to: TimeConverter
  defdelegate datetime_to_milliseconds(datetime), to: TimeConverter
  defdelegate milliseconds_to_datetime(milliseconds), to: TimeConverter

  defdelegate build_timeline(intervals), to: TimelineBuilder, as: :build
  defdelegate build_timeline(intervals, opts), to: TimelineBuilder, as: :build

  defdelegate segment_timeline(intervals, duration_seconds), to: TimelineSegmenter, as: :segment_by_duration
end
