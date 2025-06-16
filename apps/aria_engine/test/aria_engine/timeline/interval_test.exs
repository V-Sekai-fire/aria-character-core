# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.IntervalTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.Timeline.Interval

  alias AriaEngine.Timeline.{Interval, AgentEntity}

  describe "interval creation" do
    test "creates interval with NaiveDateTime" do
      start_time = ~N[2025-01-01 10:00:00]
      end_time = ~N[2025-01-01 12:00:00]
      
      interval = Interval.new(start_time, end_time, label: "Test")
      
      assert interval.start_time == start_time
      assert interval.end_time == end_time
      assert interval.label == "Test"
      assert is_binary(interval.id)
      assert String.length(interval.id) > 0
    end

    test "creates interval with DateTime" do
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      
      interval = Interval.new(start_time, end_time)
      
      assert interval.start_time == start_time
      assert interval.end_time == end_time
    end

    test "creates interval with integer timestamps" do
      interval = Interval.new(0, 3600)  # 1 hour in seconds
      
      assert interval.start_time == 0
      assert interval.end_time == 3600
    end

    test "creates interval with agent" do
      agent = AgentEntity.create_agent("aria", "Aria VTuber")
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00],
        agent: agent
      )
      
      assert interval.agent == agent
      assert Interval.agent?(interval)
      refute Interval.entity?(interval)
    end

    test "creates interval with entity" do
      entity = AgentEntity.create_entity("room", "Conference Room")
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00],
        entity: entity
      )
      
      assert interval.entity == entity
      assert Interval.entity?(interval)
      refute Interval.agent?(interval)
    end

    test "creates interval with metadata" do
      metadata = %{priority: "high", category: "meeting"}
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00],
        metadata: metadata
      )
      
      assert interval.metadata == metadata
    end

    test "generates unique IDs for intervals" do
      interval1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])
      interval2 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])
      
      assert interval1.id != interval2.id
    end
  end

  describe "interval validation" do
    test "raises error when start_time is after end_time" do
      assert_raise ArgumentError, ~r/start_time must be before end_time/, fn ->
        Interval.new(~N[2025-01-01 15:00:00], ~N[2025-01-01 10:00:00])
      end
    end

    test "raises error when start_time equals end_time" do
      assert_raise ArgumentError, ~r/start_time must be before end_time/, fn ->
        Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 10:00:00])
      end
    end

    test "allows valid time ordering" do
      # Should not raise
      interval = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])
      assert interval.start_time < interval.end_time
    end
  end

  describe "duration calculation" do
    test "calculates duration for NaiveDateTime intervals" do
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00]
      )
      
      assert Interval.duration(interval) == 7200  # 2 hours in seconds
    end

    test "calculates duration for DateTime intervals" do
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC")
      
      interval = Interval.new(start_time, end_time)
      
      assert Interval.duration(interval) == 9000  # 2.5 hours in seconds
    end

    test "calculates duration for integer intervals" do
      interval = Interval.new(100, 500)
      
      assert Interval.duration(interval) == 400
    end

    test "raises error for mixed time types" do
      # Create interval with incompatible types by bypassing validation
      interval = %Interval{
        id: "test",
        start_time: ~N[2025-01-01 10:00:00],
        end_time: 3600,
        label: nil,
        agent: nil,
        entity: nil,
        metadata: %{}
      }
      
      assert_raise ArgumentError, ~r/Incompatible time types/, fn ->
        Interval.duration(interval)
      end
    end
  end

  describe "time point containment" do
    test "detects contained time points in NaiveDateTime interval" do
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00]
      )
      
      assert Interval.contains?(interval, ~N[2025-01-01 11:00:00])
      assert Interval.contains?(interval, ~N[2025-01-01 10:00:00])  # Start inclusive
      refute Interval.contains?(interval, ~N[2025-01-01 12:00:00])  # End exclusive
      refute Interval.contains?(interval, ~N[2025-01-01 09:00:00])
      refute Interval.contains?(interval, ~N[2025-01-01 13:00:00])
    end

    test "detects contained time points in DateTime interval" do
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      test_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      
      interval = Interval.new(start_time, end_time)
      
      assert Interval.contains?(interval, test_time)
    end

    test "detects contained time points in integer interval" do
      interval = Interval.new(100, 500)
      
      assert Interval.contains?(interval, 200)
      assert Interval.contains?(interval, 100)  # Start inclusive
      refute Interval.contains?(interval, 500)  # End exclusive
      refute Interval.contains?(interval, 50)
      refute Interval.contains?(interval, 600)
    end

    test "raises error for incompatible time types in containment check" do
      interval = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])
      
      assert_raise ArgumentError, ~r/Incompatible time types/, fn ->
        Interval.contains?(interval, 3600)  # Integer time point with NaiveDateTime interval
      end
    end
  end

  describe "agent and entity detection" do
    test "detects agent intervals" do
      agent = AgentEntity.create_agent("aria", "Aria VTuber")
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00],
        agent: agent
      )
      
      assert Interval.agent?(interval)
      refute Interval.entity?(interval)
    end

    test "detects entity intervals" do
      entity = AgentEntity.create_entity("room", "Conference Room")
      interval = Interval.new(
        ~N[2025-01-01 10:00:00],
        ~N[2025-01-01 12:00:00],
        entity: entity
      )
      
      assert Interval.entity?(interval)
      refute Interval.agent?(interval)
    end

    test "detects intervals with neither agent nor entity" do
      interval = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])
      
      refute Interval.agent?(interval)
      refute Interval.entity?(interval)
    end
  end
end
