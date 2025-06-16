# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.IntervalEnhancedTest do
  use ExUnit.Case
  doctest AriaEngine.Timeline.Interval

  alias AriaEngine.Timeline.Interval

  describe "Enhanced Duration Functions" do
    test "duration_in_unit works for all supported units" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 12:30:15], "Etc/UTC")  # 2h 30m 15s
      interval = Interval.new(start_dt, end_dt)
      
      assert Interval.duration_in_unit(interval, :second) == 9015
      assert Interval.duration_in_unit(interval, :minute) == 150  # 150 minutes
      assert Interval.duration_in_unit(interval, :hour) == 2
      assert Interval.duration_in_unit(interval, :millisecond) == 9_015_000
    end

    test "from_duration creates intervals correctly" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      
      # Create 30-minute interval
      interval = Interval.from_duration(start_dt, 30, :minute)
      
      assert Interval.duration_in_unit(interval, :minute) == 30
      assert Interval.duration_in_unit(interval, :second) == 1800
    end

    test "from_duration works with different units" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      
      # Test various units
      hour_interval = Interval.from_duration(start_dt, 2, :hour)
      assert Interval.duration_in_unit(hour_interval, :hour) == 2
      
      day_interval = Interval.from_duration(start_dt, 1, :day)
      assert Interval.duration_in_unit(day_interval, :day) == 1
      assert Interval.duration_in_unit(day_interval, :hour) == 24
    end
  end

  describe "STN Integration" do
    test "to_stn_points provides correct format" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 10:05:00], "Etc/UTC")  # 5 minutes
      interval = Interval.new(start_dt, end_dt)
      
      {start_point, end_point, duration} = Interval.to_stn_points(interval, :second)
      
      assert start_point == "#{interval.id}_start"
      assert end_point == "#{interval.id}_end"
      assert duration == 300  # 300 seconds
    end

    test "to_stn_points works with different units" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")  # 1 hour
      interval = Interval.new(start_dt, end_dt)
      
      {_start, _end, duration_minutes} = Interval.to_stn_points(interval, :minute)
      assert duration_minutes == 60
      
      {_start, _end, duration_milliseconds} = Interval.to_stn_points(interval, :millisecond)
      assert duration_milliseconds == 3_600_000
    end
  end

  describe "Temporal Relationships" do
    test "overlaps? detects overlapping intervals" do
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      
      # Overlapping interval
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
      
      # Non-overlapping interval (after)
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
      
      # Adjacent interval (meets)
      start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      interval2 = Interval.new(start2, end2)
      
      refute Interval.overlaps?(interval1, interval2)
      refute Interval.overlaps?(interval2, interval1)
    end
  end

  describe "Allen's Interval Algebra" do
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

  describe "Edge Cases and Validation" do
    test "handles microsecond precision correctly" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00.000], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00.001], "Etc/UTC")  # 1ms
      interval = Interval.new(start_dt, end_dt)
      
      assert Interval.duration_in_unit(interval, :microsecond) == 1000
      assert Interval.duration_in_unit(interval, :millisecond) == 1
    end

    test "handles timezone differences correctly" do
      # Create intervals in different timezones
      start_utc = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_utc = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval_utc = Interval.new(start_utc, end_utc)
      
      # Same moment in different timezone
      start_est = DateTime.from_naive!(~N[2025-01-01 05:00:00], "America/New_York")
      end_est = DateTime.from_naive!(~N[2025-01-01 06:00:00], "America/New_York")
      interval_est = Interval.new(start_est, end_est)
      
      # Duration should be the same
      assert Interval.duration_in_unit(interval_utc, :second) == 
             Interval.duration_in_unit(interval_est, :second)
      
      # They should be equal in Allen's algebra
      assert Interval.allen_relation(interval_utc, interval_est) == :equals
    end

    test "large duration calculations" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 00:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-12-31 23:59:59], "Etc/UTC")  # Almost full year
      interval = Interval.new(start_dt, end_dt)
      
      # Should handle large durations correctly
      days = Interval.duration_in_unit(interval, :day)
      assert days == 364  # 2025 is not a leap year
      
      hours = Interval.duration_in_unit(interval, :hour)
      assert hours == 8735  # 364 * 24 + 23 hours
    end
  end
end
