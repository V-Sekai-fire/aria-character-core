# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TimelineTest do
  use ExUnit.Case, async: true
  doctest Timeline
  alias Timeline
  alias Timeline.Interval

  describe("timeline creation and basic operations") do
    test "creates a new empty timeline" do
      timeline = Timeline.new()
      assert timeline.intervals == %{}
      assert Timeline.consistent?(timeline)
    end

    test "creates timeline with metadata" do
      metadata = %{name: "Test Timeline"}
      timeline = Timeline.new(metadata: metadata)
      assert timeline.metadata == metadata
    end

    test "creates intervals within timeline" do
      timeline = Timeline.new()
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")

      interval =
        Interval.new(
          start_time,
          end_time,
          label: "Test Interval"
        )

      updated_timeline = Timeline.add_interval(timeline, interval)
      assert length(Map.keys(updated_timeline.intervals)) == 1
      assert Timeline.consistent?(updated_timeline)
    end

    test "maintains temporal consistency when adding intervals" do
      timeline = Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      interval2 = Interval.new(start2, end2)

      updated_timeline =
        timeline |> Timeline.add_interval(interval1) |> Timeline.add_interval(interval2)

      assert length(Map.keys(updated_timeline.intervals)) == 2
      assert Timeline.consistent?(updated_timeline)
    end

    test "handles overlapping intervals" do
      timeline = Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      interval2 = Interval.new(start2, end2)

      updated_timeline =
        timeline |> Timeline.add_interval(interval1) |> Timeline.add_interval(interval2)

      assert Timeline.consistent?(updated_timeline)
    end
  end

  describe("Allen's interval relationships") do
    setup do
      timeline = Timeline.new()

      before_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          label: "Before"
        )

      after_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          label: "After"
        )

      meets_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          label: "Meets"
        )

      overlaps_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          label: "Overlaps"
        )

      timeline =
        timeline
        |> Timeline.add_interval(before_interval)
        |> Timeline.add_interval(after_interval)
        |> Timeline.add_interval(meets_interval)
        |> Timeline.add_interval(overlaps_interval)

      %{
        timeline: timeline,
        before_interval: before_interval,
        after_interval: after_interval,
        meets_interval: meets_interval,
        overlaps_interval: overlaps_interval
      }
    end

    test("detects before relationship", %{
      timeline: timeline,
      before_interval: before_interval,
      after_interval: after_interval
    }) do
      max_timepoint = 1_000_000_000
      constraint = {1, max_timepoint}

      updated_timeline =
        Timeline.add_constraint(
          timeline,
          "#{before_interval.id}_end",
          "#{after_interval.id}_start",
          constraint
        )

      assert Timeline.consistent?(updated_timeline)
    end

    test("detects meets relationship", %{
      timeline: timeline,
      before_interval: before_interval,
      meets_interval: meets_interval
    }) do
      constraint = {0, 0}

      updated_timeline =
        Timeline.add_constraint(
          timeline,
          "#{before_interval.id}_end",
          "#{meets_interval.id}_start",
          constraint
        )

      assert Timeline.consistent?(updated_timeline)
    end

    test("detects overlaps relationship", %{timeline: timeline}) do
      assert Timeline.consistent?(timeline)
    end

    test("detects equals relationship", %{timeline: timeline}) do
      equal_interval1 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
        )

      equal_interval2 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(equal_interval1)
        |> Timeline.add_interval(equal_interval2)

      assert Timeline.consistent?(updated_timeline)
    end

    test("detects during relationship", %{timeline: timeline}) do
      during_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC")
        )

      updated_timeline = Timeline.add_interval(timeline, during_interval)
      assert Timeline.consistent?(updated_timeline)
    end

    test("detects starts relationship", %{timeline: timeline}) do
      starts_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
        )

      updated_timeline = Timeline.add_interval(timeline, starts_interval)
      assert Timeline.consistent?(updated_timeline)
    end

    test("detects finishes relationship", %{timeline: timeline}) do
      finishes_interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
        )

      updated_timeline = Timeline.add_interval(timeline, finishes_interval)
      assert Timeline.consistent?(updated_timeline)
    end
  end

  describe("agent and entity support") do
    test "creates timeline with agents" do
      timeline = Timeline.new()

      agent = %{
        id: "aria",
        name: "Aria VTuber",
        type: :agent,
        metadata: %{},
        capabilities: [
          :decision_making,
          :action_execution,
          :communication,
          :learning,
          :goal_setting
        ],
        properties: %{personality: "helpful"}
      }

      interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: agent,
          label: "Agent Interval"
        )

      updated_timeline = Timeline.add_interval(timeline, interval)
      assert Timeline.consistent?(updated_timeline)
    end

    test "creates timeline with entities" do
      timeline = Timeline.new()

      entity = %{
        id: "room",
        name: "Conference Room",
        type: :entity,
        metadata: %{},
        properties: %{capacity: 10},
        owner_agent_id: nil
      }

      interval =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: entity,
          label: "Entity Interval"
        )

      updated_timeline = Timeline.add_interval(timeline, interval)
      assert Timeline.consistent?(updated_timeline)
    end

    test "tracks agents and entities in timeline" do
      timeline = Timeline.new()

      agent = %{
        id: "aria",
        name: "Aria VTuber",
        type: :agent,
        metadata: %{},
        capabilities: [
          :decision_making,
          :action_execution,
          :communication,
          :learning,
          :goal_setting
        ],
        properties: %{}
      }

      entity = %{
        id: "room",
        name: "Conference Room",
        type: :entity,
        metadata: %{},
        properties: %{},
        owner_agent_id: nil
      }

      interval1 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: agent
        )

      interval2 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: entity
        )

      updated_timeline =
        timeline |> Timeline.add_interval(interval1) |> Timeline.add_interval(interval2)

      assert length(Map.keys(updated_timeline.intervals)) == 2
    end
  end

  describe("temporal consistency and PC-2 algorithm") do
    test "maintains consistency with complex constraint networks" do
      timeline = Timeline.new()

      interval1 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          label: "Task 1"
        )

      interval2 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          label: "Task 2"
        )

      interval3 =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          label: "Task 3"
        )

      updated_timeline =
        timeline
        |> Timeline.add_interval(interval1)
        |> Timeline.add_interval(interval2)
        |> Timeline.add_interval(interval3)

      assert length(Map.keys(updated_timeline.intervals)) == 3
      assert Timeline.consistent?(updated_timeline)
    end

    test "handles DateTime time points" do
      timeline = Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      interval1 = Interval.new(start1, end1)
      interval2 = Interval.new(start2, end2)

      updated_timeline =
        timeline |> Timeline.add_interval(interval1) |> Timeline.add_interval(interval2)

      assert Timeline.consistent?(updated_timeline)
    end
  end

  describe("error handling") do
    test "raises error for invalid time order" do
      assert_raise ArgumentError, ~r/start_time must be before or equal to end_time/, fn ->
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
        )
      end
    end

    test "handles empty timeline consistently" do
      timeline = Timeline.new()
      assert Timeline.consistent?(timeline)
      assert Map.keys(timeline.intervals) == []
    end
  end
end
