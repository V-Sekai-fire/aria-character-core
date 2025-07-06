# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimelineIntervalsTest do
  use ExUnit.Case
  doctest AriaTimelineIntervals
  doctest AriaTimelineIntervals.Interval
  doctest AriaTimelineIntervals.AllenRelations
  doctest AriaTimelineIntervals.TimeConverter
  doctest AriaTimelineIntervals.TimelineBuilder
  doctest AriaTimelineIntervals.TimelineSegmenter

  test "basic interval creation and validation" do
    start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
    end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")

    interval = AriaTimelineIntervals.new_interval(start_time, end_time)

    assert interval.start_time == start_time
    assert interval.end_time == end_time
    assert interval.id != nil
    assert AriaTimelineIntervals.validate_interval(interval) == :ok
  end

  test "time conversion utilities" do
    assert AriaTimelineIntervals.seconds_to_milliseconds(5.5) == 5500
    assert AriaTimelineIntervals.milliseconds_to_seconds(5500) == 5.5
  end

  test "Allen relations basic functionality" do
    start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
    end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
    interval1 = AriaTimelineIntervals.new_interval(start1, end1)

    start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
    end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
    interval2 = AriaTimelineIntervals.new_interval(start2, end2)

    relation = AriaTimelineIntervals.allen_relation(interval1, interval2)
    assert relation == :before
    assert AriaTimelineIntervals.satisfies_relation?(interval1, interval2, :before) == true
  end

  test "timeline building" do
    start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
    end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
    interval1 = AriaTimelineIntervals.new_interval(start1, end1)

    start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
    end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
    interval2 = AriaTimelineIntervals.new_interval(start2, end2)

    timeline = AriaTimelineIntervals.build_timeline([interval1, interval2])

    assert length(timeline.intervals) == 2
    assert timeline.start_time == start1
    assert timeline.end_time == end2
  end

  test "timeline segmentation" do
    start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
    end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
    interval1 = AriaTimelineIntervals.new_interval(start1, end1)

    segments = AriaTimelineIntervals.segment_timeline([interval1], 3600)

    assert length(segments) == 2  # 2-hour interval segmented into 1-hour windows
  end
end
