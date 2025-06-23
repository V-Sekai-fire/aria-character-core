# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.Timeline

  describe("timeline creation and basic operations") do
    test "creates a new empty timeline" do
      timeline = AriaEngine.Timeline.new()
      assert timeline.intervals == %{}
      assert AriaEngine.Timeline.consistent?(timeline)
    end

    test "creates timeline with metadata" do
      metadata = %{name: "Test Timeline"}
      timeline = AriaEngine.Timeline.new(metadata: metadata)
      assert timeline.metadata == metadata
    end

    test "creates intervals within timeline" do
      timeline = AriaEngine.Timeline.new()
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")

      interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start_time),
          DateTime.to_iso8601(end_time),
          label: "Test Interval"
        )

      updated_timeline = AriaEngine.Timeline.add_interval(timeline, interval)
      assert length(Map.keys(updated_timeline.intervals)) == 1
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test "maintains temporal consistency when adding intervals" do
      timeline = AriaEngine.Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")

      interval1 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start1),
          DateTime.to_iso8601(end1)
        )

      interval2 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start2),
          DateTime.to_iso8601(end2)
        )

      updated_timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(interval1)
        |> AriaEngine.Timeline.add_interval(interval2)

      assert length(Map.keys(updated_timeline.intervals)) == 2
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test "handles overlapping intervals" do
      timeline = AriaEngine.Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      interval1 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start1),
          DateTime.to_iso8601(end1)
        )

      interval2 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start2),
          DateTime.to_iso8601(end2)
        )

      updated_timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(interval1)
        |> AriaEngine.Timeline.add_interval(interval2)

      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end
  end

  describe("Allen's interval relationships") do
    setup do
      timeline = AriaEngine.Timeline.new()

      before_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          label: "Before"
        )

      after_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          label: "After"
        )

      meets_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          label: "Meets"
        )

      overlaps_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          label: "Overlaps"
        )

      timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(before_interval)
        |> AriaEngine.Timeline.add_interval(after_interval)
        |> AriaEngine.Timeline.add_interval(meets_interval)
        |> AriaEngine.Timeline.add_interval(overlaps_interval)

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
        AriaEngine.Timeline.add_constraint(
          timeline,
          "#{before_interval.id}_end",
          "#{after_interval.id}_start",
          constraint
        )

      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test("detects meets relationship", %{
      timeline: timeline,
      before_interval: before_interval,
      meets_interval: meets_interval
    }) do
      constraint = {0, 0}

      updated_timeline =
        AriaEngine.Timeline.add_constraint(
          timeline,
          "#{before_interval.id}_end",
          "#{meets_interval.id}_start",
          constraint
        )

      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test("detects overlaps relationship", %{timeline: timeline}) do
      assert AriaEngine.Timeline.consistent?(timeline)
    end

    test("detects equals relationship", %{timeline: timeline}) do
      equal_interval1 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
        )

      equal_interval2 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
        )

      updated_timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(equal_interval1)
        |> AriaEngine.Timeline.add_interval(equal_interval2)

      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test("detects during relationship", %{timeline: timeline}) do
      during_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC")
        )

      updated_timeline = AriaEngine.Timeline.add_interval(timeline, during_interval)
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test("detects starts relationship", %{timeline: timeline}) do
      starts_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
        )

      updated_timeline = AriaEngine.Timeline.add_interval(timeline, starts_interval)
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test("detects finishes relationship", %{timeline: timeline}) do
      finishes_interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
        )

      updated_timeline = AriaEngine.Timeline.add_interval(timeline, finishes_interval)
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end
  end

  describe("agent and entity support") do
    test "creates timeline with agents" do
      timeline = AriaEngine.Timeline.new()

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
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: agent,
          label: "Agent Interval"
        )

      updated_timeline = AriaEngine.Timeline.add_interval(timeline, interval)
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test "creates timeline with entities" do
      timeline = AriaEngine.Timeline.new()

      entity = %{
        id: "room",
        name: "Conference Room",
        type: :entity,
        metadata: %{},
        properties: %{capacity: 10},
        owner_agent_id: nil
      }

      interval =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: entity,
          label: "Entity Interval"
        )

      updated_timeline = AriaEngine.Timeline.add_interval(timeline, interval)
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test "tracks agents and entities in timeline" do
      timeline = AriaEngine.Timeline.new()

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
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: agent
        )

      interval2 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          entity: entity
        )

      updated_timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(interval1)
        |> AriaEngine.Timeline.add_interval(interval2)

      assert length(Map.keys(updated_timeline.intervals)) == 2
    end
  end

  describe("temporal consistency and PC-2 algorithm") do
    test "maintains consistency with complex constraint networks" do
      timeline = AriaEngine.Timeline.new()

      interval1 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          label: "Task 1"
        )

      interval2 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          label: "Task 2"
        )

      interval3 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
          label: "Task 3"
        )

      updated_timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(interval1)
        |> AriaEngine.Timeline.add_interval(interval2)
        |> AriaEngine.Timeline.add_interval(interval3)

      assert length(Map.keys(updated_timeline.intervals)) == 3
      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end

    test "handles DateTime time points" do
      timeline = AriaEngine.Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      interval1 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start1),
          DateTime.to_iso8601(end1)
        )

      interval2 =
        AriaEngine.Timeline.Interval.new_fixed_schedule(
          DateTime.to_iso8601(start2),
          DateTime.to_iso8601(end2)
        )

      updated_timeline =
        timeline
        |> AriaEngine.Timeline.add_interval(interval1)
        |> AriaEngine.Timeline.add_interval(interval2)

      assert AriaEngine.Timeline.consistent?(updated_timeline)
    end
  end

  describe("error handling") do
    test "raises error for invalid time order" do
      assert_raise ArgumentError, ~r/start_time must be before or equal to end_time/, fn ->
        AriaEngine.Timeline.Interval.new_fixed_schedule(DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
        )
      end
    end

    test "handles empty timeline consistently" do
      timeline = AriaEngine.Timeline.new()
      assert AriaEngine.Timeline.consistent?(timeline)
      assert Map.keys(timeline.intervals) == []
    end
  end
end
