# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.IntervalEnhancedTest do
  use ExUnit.Case
  doctest Timeline.Interval
  alias Timeline.Interval

  describe("Enhanced Duration Functions") do
    test "duration_in_unit works for all supported units" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 12:30:15], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)
      assert Interval.duration_in_unit(interval, :second) == 9015
      assert Interval.duration_in_unit(interval, :minute) == 150
      assert Interval.duration_in_unit(interval, :hour) == 2
      assert Interval.duration_in_unit(interval, :millisecond) == 9_015_000
    end

    test "from_duration creates intervals correctly" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      interval = Interval.from_duration(start_dt, 30, :minute)
      assert Interval.duration_in_unit(interval, :minute) == 30
      assert Interval.duration_in_unit(interval, :second) == 1800
    end

    test "from_duration works with different units" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      hour_interval = Interval.from_duration(start_dt, 2, :hour)
      assert Interval.duration_in_unit(hour_interval, :hour) == 2
      day_interval = Interval.from_duration(start_dt, 1, :day)
      assert Interval.duration_in_unit(day_interval, :day) == 1
      assert Interval.duration_in_unit(day_interval, :hour) == 24
    end
  end

  describe("STN Integration") do
    test "to_stn_points provides correct format" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 10:05:00], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)
      {start_point, end_point, duration} = Interval.to_stn_points(interval, :second)
      assert start_point == "#{interval.id}_start"
      assert end_point == "#{interval.id}_end"
      assert duration == 300
    end

    test "to_stn_points works with different units" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)
      {_start, _end, duration_minutes} = Interval.to_stn_points(interval, :minute)
      assert duration_minutes == 60
      {_start, _end, duration_milliseconds} = Interval.to_stn_points(interval, :millisecond)
      assert duration_milliseconds == 3_600_000
    end
  end

  describe("Temporal Relationships") do
    test "overlaps? detects overlapping intervals" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      assert Interval.overlaps?(interval1, interval2)
      assert Interval.overlaps?(interval2, interval1)
    end

    test "overlaps? detects non-overlapping intervals" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      refute Interval.overlaps?(interval1, interval2)
      refute Interval.overlaps?(interval2, interval1)
    end

    test "overlaps? handles adjacent intervals correctly" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      refute Interval.overlaps?(interval1, interval2)
      refute Interval.overlaps?(interval2, interval1)
    end
  end

  describe("Allen's Interval Algebra") do
    test "detects 'before' relationship" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      assert Interval.allen_relation(interval1, interval2) == :before
      assert Interval.allen_relation(interval2, interval1) == :after
    end

    test "detects 'meets' relationship" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      assert Interval.allen_relation(interval1, interval2) == :meets
      assert Interval.allen_relation(interval2, interval1) == :met_by
    end

    test "detects 'equals' relationship" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start_dt, end_dt)
      interval2 = Interval.new(start_dt, end_dt)
      assert Interval.allen_relation(interval1, interval2) == :equals
    end

    test "detects 'overlaps' relationship" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      assert Interval.allen_relation(interval1, interval2) == :overlaps
      assert Interval.allen_relation(interval2, interval1) == :overlapped_by
    end

    test "detects 'contains' relationship" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      start2 = DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      assert Interval.allen_relation(interval1, interval2) == :contains
      assert Interval.allen_relation(interval2, interval1) == :during
    end

    test "detects 'starts' relationship" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start_dt, end1)
      end2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      interval2 = Interval.new(start_dt, end2)
      assert Interval.allen_relation(interval1, interval2) == :starts
      assert Interval.allen_relation(interval2, interval1) == :started_by
    end

    test "detects 'finishes' relationship" do
      end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end_dt)
      start2 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      interval2 = Interval.new(start2, end_dt)
      assert Interval.allen_relation(interval1, interval2) == :finishes
      assert Interval.allen_relation(interval2, interval1) == :finished_by
    end
  end

  describe("Edge Cases and Validation") do
    test "handles microsecond precision correctly" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00.000], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00.001], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)
      assert Interval.duration_in_unit(interval, :microsecond) == 1000
      assert Interval.duration_in_unit(interval, :millisecond) == 1
    end

    test "handles timezone differences correctly" do
      start_utc = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_utc = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval_utc = Interval.new(start_utc, end_utc)
      start_est_equiv = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      end_est_equiv = DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC")
      interval_est_equiv = Interval.new(start_est_equiv, end_est_equiv)

      assert Interval.duration_in_unit(interval_utc, :second) ==
               Interval.duration_in_unit(interval_est_equiv, :second)

      assert Interval.duration_in_unit(interval_utc, :second) == 3600
      assert Interval.duration_in_unit(interval_est_equiv, :second) == 3600
    end

    test "large duration calculations" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 00:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-12-31 23:59:59], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)
      days = Interval.duration_in_unit(interval, :day)
      assert days == 364
      hours = Interval.duration_in_unit(interval, :hour)
      assert hours == 8759
    end
  end
end
