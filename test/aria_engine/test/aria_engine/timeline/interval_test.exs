defmodule Timeline.IntervalTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.{AgentEntity, Interval}

  describe("interval creation") do
    @describetag :timeline_stn
    test "creates interval with DateTime" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert interval.start_time == start_time
      assert interval.end_time == end_time
    end

    test "creates interval with DateTime timestamps" do
      start_time = "1970-01-01T00:00:00Z"
      end_time = "1970-01-01T01:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert Interval.duration_seconds(interval) == 3600.0
    end

    test "creates interval with agent" do
      agent = AgentEntity.create_agent("aria", "Aria VTuber")
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time),
          agent: agent
        )

      assert interval.agent == agent
      assert Interval.agent?(interval)
      refute Interval.entity?(interval)
    end

    test "creates interval with entity" do
      entity = AgentEntity.create_entity("room", "Conference Room")
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time),
          entity: entity
        )

      assert interval.entity == entity
      assert Interval.entity?(interval)
      refute Interval.agent?(interval)
    end

    test "creates interval with metadata" do
      metadata = %{priority: "high", category: "meeting"}
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time),
          metadata: metadata
        )

      assert interval.metadata == metadata
    end

    test "generates unique IDs for intervals" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval1 =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      interval2 =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert interval1.id != interval2.id
    end
  end

  describe("interval validation") do
    test "raises error when start_time is after end_time" do
      start_time = "2025-01-01T15:00:00Z"
      end_time = "2025-01-01T10:00:00Z"

      assert_raise ArgumentError, ~r/start_time must be before or equal to end_time/, fn ->
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )
      end
    end

    test "allows valid time ordering" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert DateTime.compare(interval.start_time, interval.end_time) == :lt
    end

    test "allows instantaneous intervals (start_time equals end_time)" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T10:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert DateTime.compare(interval.start_time, interval.end_time) == :eq
    end
  end

  describe("duration calculation") do
    test "calculates duration for DateTime intervals" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:30:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert Interval.duration_seconds(interval) == 9000.0
    end

    test "calculates duration for shorter DateTime intervals" do
      start_time = "1970-01-01T00:01:40Z"
      end_time = "1970-01-01T00:08:20Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert Interval.duration_seconds(interval) == 400.0
    end
  end

  describe("time point containment") do
    test "detects contained time points in DateTime interval" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"
      test_time = "2025-01-01T11:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      assert Interval.contains?(interval, test_time)
    end

    test "detects contained time points with boundary checks" do
      start_time = "1970-01-01T00:01:40Z"
      end_time = "1970-01-01T00:08:20Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      test_time = "1970-01-01T00:03:20Z"
      assert Interval.contains?(interval, test_time)
      assert Interval.contains?(interval, start_time)
      refute Interval.contains?(interval, end_time)
      before_time = "1970-01-01T00:00:50Z"
      refute Interval.contains?(interval, before_time)
      after_time = "1970-01-01T00:10:00Z"
      refute Interval.contains?(interval, after_time)
    end
  end

  describe("agent and entity detection") do
    test "detects agent intervals" do
      agent = AgentEntity.create_agent("aria", "Aria VTuber")
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time),
          agent: agent
        )

      assert Interval.agent?(interval)
      refute Interval.entity?(interval)
    end

    test "detects entity intervals" do
      entity = AgentEntity.create_entity("room", "Conference Room")
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time),
          entity: entity
        )

      assert interval.entity == entity
      refute Interval.agent?(interval)
    end

    test "detects intervals with neither agent nor entity" do
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time)
        )

      refute Interval.agent?(interval)
      refute Interval.entity?(interval)
    end
  end
end