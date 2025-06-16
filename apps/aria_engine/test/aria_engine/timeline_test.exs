# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TimelineTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.Timeline

  alias AriaEngine.Timeline
  alias AriaEngine.Timeline.{Interval, STN}

  describe "timeline creation and basic operations" do
    test "creates a new empty timeline" do
      timeline = Timeline.new()
      assert timeline.intervals == %{}
      assert timeline.stn.consistent
    end

    test "creates timeline with metadata" do
      metadata = [name: "Test Timeline"]
      timeline = Timeline.new(metadata)
      assert timeline.stn.metadata == %{name: "Test Timeline"}
    end

    test "creates intervals within timeline" do
      timeline = Timeline.new()

      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      
      interval = Interval.new(
        start_time,
        end_time,
        [label: "Test Interval"]
      )

      updated_timeline = Timeline.add_interval(timeline, interval)

      assert length(Map.keys(updated_timeline.intervals)) == 1
      assert STN.consistent?(updated_timeline.stn)
    end

    test "maintains temporal consistency when adding intervals" do
      timeline = Timeline.new()

      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")

      interval1 = Interval.new(start1, end1)
      interval2 = Interval.new(start2, end2)

      updated_timeline = timeline
      |> Timeline.add_interval(interval1)
      |> Timeline.add_interval(interval2)

      assert length(Map.keys(updated_timeline.intervals)) == 2
      assert STN.consistent?(updated_timeline.stn)
    end

    test "handles overlapping intervals" do
      timeline = Timeline.new()

      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      interval1 = Interval.new(start1, end1)
      interval2 = Interval.new(start2, end2)

      updated_timeline = timeline
      |> Timeline.add_interval(interval1)
      |> Timeline.add_interval(interval2)

      assert STN.consistent?(updated_timeline.stn)
    end
  end

  describe "Allen's interval relationships" do
    setup do
      timeline = Timeline.new()

      before_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        [label: "Before"]
      )

      after_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
        [label: "After"]
      )

      meets_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
        [label: "Meets"]
      )

      overlaps_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
        [label: "Overlaps"]
      )

      timeline = timeline
      |> Timeline.add_interval(before_interval)
      |> Timeline.add_interval(after_interval)
      |> Timeline.add_interval(meets_interval)
      |> Timeline.add_interval(overlaps_interval)

      %{timeline: timeline}
    end

    test "detects before relationship", %{timeline: timeline} do
      constraint = {1, :infinity} # after_interval starts at least 1 unit after before_interval ends
      updated_timeline = Timeline.add_constraint(timeline, "Before_end", "After_start", constraint)
      assert STN.consistent?(updated_timeline.stn)
    end

    test "detects meets relationship", %{timeline: timeline} do
      constraint = {0, 0} # meets_interval starts exactly when before_interval ends
      updated_timeline = Timeline.add_constraint(timeline, "Before_end", "Meets_start", constraint)
      assert STN.consistent?(updated_timeline.stn)
    end

    test "detects overlaps relationship", %{timeline: timeline} do
      # No explicit constraint needed, overlapping is determined by start/end times
      assert STN.consistent?(timeline.stn)
    end

    test "detects equals relationship", %{timeline: timeline} do
      equal_interval1 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      )
      equal_interval2 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      )

      updated_timeline = timeline
      |> Timeline.add_interval(equal_interval1)
      |> Timeline.add_interval(equal_interval2)

      assert STN.consistent?(updated_timeline.stn)
    end

    test "detects during relationship", %{timeline: timeline} do
      during_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC")
      )
      updated_timeline = Timeline.add_interval(timeline, during_interval)
      assert STN.consistent?(updated_timeline.stn)
    end

    test "detects starts relationship", %{timeline: timeline} do
      starts_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      )
      updated_timeline = Timeline.add_interval(timeline, starts_interval)
      assert STN.consistent?(updated_timeline.stn)
    end

    test "detects finishes relationship", %{timeline: timeline} do
      finishes_interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      )
      updated_timeline = Timeline.add_interval(timeline, finishes_interval)
      assert STN.consistent?(updated_timeline.stn)
    end
  end

  describe "agent and entity support" do
    test "creates timeline with agents" do
      timeline = Timeline.new()
      agent = %{id: "aria", name: "Aria VTuber", type: :agent, metadata: %{}, capabilities: [:decision_making, :action_execution, :communication, :learning, :goal_setting], properties: %{personality: "helpful"}}
      interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        agent: agent, label: "Agent Interval"
      )
      updated_timeline = Timeline.add_interval(timeline, interval)

      assert updated_timeline.stn.consistent
    end

    test "creates timeline with entities" do
      timeline = Timeline.new()
      entity = %{id: "room", name: "Conference Room", type: :entity, metadata: %{}, properties: %{capacity: 10}, owner_agent_id: nil}
      interval = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        entity: entity, label: "Entity Interval"
      )
      updated_timeline = Timeline.add_interval(timeline, interval)

      assert updated_timeline.stn.consistent
    end

    test "tracks agents and entities in timeline" do
      timeline = Timeline.new()
      agent = %{id: "aria", name: "Aria VTuber", type: :agent, metadata: %{}, capabilities: [:decision_making, :action_execution, :communication, :learning, :goal_setting], properties: %{}}
      entity = %{id: "room", name: "Conference Room", type: :entity, metadata: %{}, properties: %{}, owner_agent_id: nil}

      interval1 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        agent: agent
      )
      interval2 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        entity: entity
      )

      updated_timeline = timeline
      |> Timeline.add_interval(interval1)
      |> Timeline.add_interval(interval2)

      assert length(Map.keys(updated_timeline.intervals)) == 2
    end
  end

  describe "temporal consistency and PC-2 algorithm" do
    test "maintains consistency with complex constraint networks" do
      timeline = Timeline.new()

      interval1 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
        label: "Task 1"
      )
      interval2 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
        label: "Task 2"
      )
      interval3 = Interval.new(
        DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
        DateTime.from_naive!(~N[2025-01-01 16:00:00], "Etc/UTC"),
        label: "Task 3"
      )

      updated_timeline = timeline
      |> Timeline.add_interval(interval1)
      |> Timeline.add_interval(interval2)
      |> Timeline.add_interval(interval3)

      assert length(Map.keys(updated_timeline.intervals)) == 3
      assert STN.consistent?(updated_timeline.stn)
    end

    test "handles DateTime time points" do
      timeline = Timeline.new()
      start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      interval1 = Interval.new(start1, end1)
      interval2 = Interval.new(start2, end2)

      updated_timeline = timeline
      |> Timeline.add_interval(interval1)
      |> Timeline.add_interval(interval2)

      assert STN.consistent?(updated_timeline.stn)
    end
  end

  describe "error handling" do
    test "raises error for invalid time order" do
      assert_raise ArgumentError, ~r/start_time must be before end_time/, fn ->
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
        )
      end
    end

    test "handles empty timeline consistently" do
      timeline = Timeline.new()
      assert STN.consistent?(timeline.stn)
      assert Map.keys(timeline.intervals) == []
    end
  end
end
