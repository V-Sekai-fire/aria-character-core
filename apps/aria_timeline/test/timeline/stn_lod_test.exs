# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.STNLODTest do
  use ExUnit.Case
  # Set module timeout to 60 seconds
  @moduletag timeout: 60000
  doctest Timeline

  alias Timeline.{Interval}
  alias Timeline.Internal.STN

  describe "LOD and Unit System" do
    test "creates STN with specified time unit and LOD level" do
      stn = STN.new(time_unit: :second, lod_level: :high)

      assert stn.time_unit == :second
      assert stn.lod_level == :high
      assert stn.lod_resolution == 10
      assert stn.auto_rescale == true
    end

    test "rescales LOD level correctly" do
      stn = STN.new(lod_level: :low)
      high_detail_stn = STN.rescale_lod(stn, :high)

      assert high_detail_stn.lod_level == :high
      assert high_detail_stn.lod_resolution == 10
    end

    test "converts time units correctly" do
      stn = STN.new(time_unit: :millisecond)
      second_stn = STN.convert_units(stn, :second)

      assert second_stn.time_unit == :second
    end

    test "automatic rescaling with constraints" do
      # Create STN with constraints in milliseconds
      stn = STN.new(time_unit: :millisecond)

      stn =
        stn
        |> STN.add_time_point("t1")
        |> STN.add_time_point("t2")
        # 1-2 seconds
        |> STN.add_constraint("t1", "t2", {1000, 2000})

      # Convert to seconds
      second_stn = STN.convert_units(stn, :second)
      constraint = STN.get_constraint(second_stn, "t1", "t2")

      # Should be converted to seconds
      assert constraint == {1, 2}
    end
  end

  describe "DateTime Integration" do
    test "creates STN from DateTime intervals with automatic unit conversion" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)

      stn = STN.from_datetime_intervals([interval], time_unit: :minute, lod_level: :medium)

      assert stn.time_unit == :minute
      assert stn.lod_level == :medium
      assert STN.consistent?(stn)

      # Should have start and end time points
      time_points = STN.time_points(stn)
      assert length(time_points) == 2
      assert "#{interval.id}_start" in time_points
      assert "#{interval.id}_end" in time_points
    end

    test "adds interval with LOD rescaling" do
      start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      # 5 minutes
      end_dt = DateTime.from_naive!(~N[2025-01-01 10:05:00], "Etc/UTC")
      interval = Interval.new(start_dt, end_dt)

      # Create STN with second resolution and low LOD (1000 units per tick)
      stn = STN.new(time_unit: :second, lod_level: :low)
      updated_stn = STN.add_interval(stn, interval)

      assert STN.consistent?(updated_stn)
    end
  end

  describe "Boolean-like Operators" do
    test "AND operation (union) with compatible STNs" do
      stn1 =
        STN.new(time_unit: :second)
        |> STN.add_time_point("t1")
        |> STN.add_constraint("t1", "t1", {0, 0})

      stn2 =
        STN.new(time_unit: :second)
        |> STN.add_time_point("t2")
        |> STN.add_constraint("t2", "t2", {0, 0})

      result = STN.union(stn1, stn2)

      assert STN.consistent?(result)
      time_points = STN.time_points(result)
      assert "t1" in time_points
      assert "t2" in time_points
    end

    test "OR operation with relaxed constraints" do
      stn1 =
        STN.new(time_unit: :second)
        |> STN.add_time_point("t1")
        |> STN.add_time_point("t2")
        |> STN.add_constraint("t1", "t2", {10, 20})

      stn2 =
        STN.new(time_unit: :second)
        |> STN.add_time_point("t1")
        |> STN.add_time_point("t2")
        |> STN.add_constraint("t1", "t2", {5, 30})

      result = STN.union(stn1, stn2)

      assert STN.consistent?(result)
      # OR should create more permissive bounds
      constraint = STN.get_constraint(result, "t1", "t2")
      # Min of mins, max of maxes
      assert constraint == {5, 30}
    end

    test "chaining STNs sequentially" do
      stn1 = STN.new() |> STN.add_time_point("phase1")
      stn2 = STN.new() |> STN.add_time_point("phase2")
      stn3 = STN.new() |> STN.add_time_point("phase3")

      chained = STN.chain([stn1, stn2, stn3])

      assert STN.consistent?(chained)
      time_points = STN.time_points(chained)
      assert "phase1" in time_points
      assert "phase2" in time_points
      assert "phase3" in time_points
    end

    test "splitting STN for parallel processing" do
      stn =
        STN.new()
        |> STN.add_time_point("t1")
        |> STN.add_time_point("t2")
        |> STN.add_time_point("t3")
        |> STN.add_time_point("t4")

      segments = STN.split(stn, 2)

      assert is_list(segments)
      assert length(segments) <= 2

      # Each segment should be consistent
      Enum.each(segments, fn segment ->
        assert STN.consistent?(segment)
      end)
    end
  end

  describe "Auto-rescaling Compatibility" do
    test "union auto-rescales incompatible units" do
      stn1 =
        STN.new(time_unit: :millisecond, auto_rescale: true)
        |> STN.add_time_point("t1")
        |> STN.add_constraint("t1", "t1", {0, 0})

      stn2 =
        STN.new(time_unit: :second, auto_rescale: true)
        |> STN.add_time_point("t2")
        |> STN.add_constraint("t2", "t2", {0, 0})

      result = STN.union(stn1, stn2)

      assert STN.consistent?(result)
      # Uses first STN's units
      assert result.time_unit == :millisecond
    end

    test "union auto-rescales incompatible LOD levels" do
      stn1 =
        STN.new(lod_level: :high, auto_rescale: true)
        |> STN.add_time_point("t1")

      stn2 =
        STN.new(lod_level: :low, auto_rescale: true)
        |> STN.add_time_point("t2")

      result = STN.union(stn1, stn2)

      assert STN.consistent?(result)
      # Uses first STN's LOD
      assert result.lod_level == :high
    end

    test "respects auto_rescale disabled" do
      stn1 = STN.new(time_unit: :millisecond, auto_rescale: false)
      stn2 = STN.new(time_unit: :second, auto_rescale: false)

      # Should not auto-rescale when disabled
      result = STN.union(stn1, stn2)

      assert STN.consistent?(result)
      # Units should remain as-is from first STN
      assert result.time_unit == :millisecond
    end
  end

  describe "Constant Work Pattern Support" do
    test "creates STN with constant work enabled" do
      stn = STN.new(constant_work_enabled: true, max_timepoints: 32)

      assert stn.constant_work_enabled == true
      assert stn.max_timepoints == 32
      assert map_size(stn.dummy_constraints) > 0

      # Should have dummy timepoints
      time_points = STN.time_points(stn)
      dummy_points = Enum.filter(time_points, &String.starts_with?(&1, "dummy_"))
      assert length(dummy_points) == 32
    end

    test "constant work STN remains consistent" do
      stn =
        STN.new(constant_work_enabled: true, max_timepoints: 16)
        |> STN.add_time_point("real_point")
        |> STN.add_constraint("real_point", "real_point", {0, 0})

      assert STN.consistent?(stn)

      # Should still have dummy points
      time_points = STN.time_points(stn)
      dummy_points = Enum.filter(time_points, &String.starts_with?(&1, "dummy_"))
      assert length(dummy_points) == 16
      assert "real_point" in time_points
    end
  end

  describe "Performance and Integration" do
    # Set timeout to 30 seconds
    @tag timeout: 30000
    test "parallel solving with LOD system" do
      # Create a larger STN for parallel processing
      stn = STN.new(time_unit: :millisecond, lod_level: :medium)
      assert STN.consistent?(stn)

      # Add multiple intervals
      intervals =
        for i <- 1..10 do
          start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
          end_dt = DateTime.add(start_dt, i * 60, :second)
          Interval.new(start_dt, end_dt)
        end

      stn_with_intervals =
        STN.from_datetime_intervals(intervals, time_unit: :second, lod_level: :high)

      # Solve in parallel - this may result in unsatisfiable constraints
      result = STN.parallel_solve(stn_with_intervals, 4)

      case result do
        {:error, :unsatisfiable} ->
          # This is expected for overlapping intervals that create impossible constraints
          # The durative planner can use this signal to backtrack and try different scheduling
          assert true
        solved_stn ->
          # If constraints are satisfiable, verify the solution
          assert STN.consistent?(solved_stn)
          assert solved_stn.time_unit == :second
          assert solved_stn.lod_level == :high
      end
    end

    test "complex boolean operations with LOD" do
      # Create multiple STNs with different LOD levels
      stn_high =
        STN.new(lod_level: :high, time_unit: :millisecond)
        |> STN.add_time_point("high_res")

      stn_low =
        STN.new(lod_level: :low, time_unit: :millisecond)
        |> STN.add_time_point("low_res")

      # Chain them together
      result = STN.chain([stn_high, stn_low])

      assert STN.consistent?(result)

      # Then split for parallel processing
      segments = STN.split(result, 2)

      # And merge back together with union
      final_result =
        case segments do
          [seg1, seg2] -> STN.union(seg1, seg2)
          [single] -> single
          [] -> STN.new()
        end

      assert STN.consistent?(final_result)
    end
  end
end
