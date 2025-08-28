# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.TimelineBridgeTest do
  use ExUnit.Case, async: true
  doctest Timeline
  alias Timeline
  alias Timeline.Bridge
  alias Timeline.Interval

  describe("bridge management") do
    test "add_bridge/2 adds a bridge to timeline" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      updated_timeline = Timeline.add_bridge(timeline, bridge)
      assert Map.has_key?(updated_timeline.metadata.bridges, "decision_1")
      assert updated_timeline.metadata.bridges["decision_1"] == bridge
    end

    test "add_bridge/2 validates bridge placement" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)

      assert_raise ArgumentError, ~r/Bridge with ID 'decision_1' already exists/, fn ->
        Timeline.add_bridge(timeline_with_bridge, bridge)
      end
    end

    test "remove_bridge/2 removes a bridge from timeline" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      updated_timeline = Timeline.remove_bridge(timeline_with_bridge, "decision_1")
      refute Map.has_key?(updated_timeline.metadata.bridges, "decision_1")
    end

    test "get_bridge/2 retrieves a bridge by ID" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      retrieved_bridge = Timeline.get_bridge(timeline_with_bridge, "decision_1")
      assert retrieved_bridge == bridge
    end

    test "get_bridge/2 returns nil for non-existent bridge" do
      timeline = Timeline.new()
      assert Timeline.get_bridge(timeline, "non_existent") == nil
    end

    test "get_bridges/1 returns all bridges sorted by position" do
      timeline = Timeline.new()
      pos1 = "2025-01-01T11:00:00Z"
      pos2 = "2025-01-01T12:00:00Z"
      pos3 = "2025-01-01T10:00:00Z"
      bridge1 = Bridge.new("b1", pos1, :decision)
      bridge2 = Bridge.new("b2", pos2, :condition)
      bridge3 = Bridge.new("b3", pos3, :synchronization)

      timeline =
        timeline
        |> Timeline.add_bridge(bridge2)
        |> Timeline.add_bridge(bridge3)
        |> Timeline.add_bridge(bridge1)

      bridges = Timeline.get_bridges(timeline)
      assert length(bridges) == 3
      assert Enum.map(bridges, & &1.id) == ["b3", "b1", "b2"]
    end

    test "update_bridge/2 updates an existing bridge" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      updated_bridge = Bridge.update_metadata(bridge, %{priority: :high})
      updated_timeline = Timeline.update_bridge(timeline_with_bridge, updated_bridge)
      retrieved_bridge = Timeline.get_bridge(updated_timeline, "decision_1")
      assert retrieved_bridge.metadata.priority == :high
    end
  end

  describe("bridge validation") do
    test "validate_bridge_placement/2 succeeds for valid placement" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      assert Timeline.validate_bridge_placement(timeline, bridge) == :ok
    end

    test "validate_bridge_placement/2 fails for duplicate bridge ID" do
      timeline = Timeline.new()
      position = "2025-01-01T12:00:00Z"
      bridge = Bridge.new("decision_1", position, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)

      assert Timeline.validate_bridge_placement(timeline_with_bridge, bridge) ==
               {:error, "Bridge with ID 'decision_1' already exists"}
    end

    test "validate_bridge_placement/2 fails for bridge at interval boundary" do
      timeline = Timeline.new()
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          start_time,
          end_time
        )

      timeline_with_interval = Timeline.add_interval(timeline, interval)
      bridge_at_start = Bridge.new("bridge_start", start_time, :decision)

      assert {:error, _} =
               Timeline.validate_bridge_placement(timeline_with_interval, bridge_at_start)

      bridge_at_end = Bridge.new("bridge_end", end_time, :decision)

      assert {:error, _} =
               Timeline.validate_bridge_placement(timeline_with_interval, bridge_at_end)
    end
  end

  describe("bridge segmentation") do
    test "segment_by_bridges/1 returns single segment when no bridges" do
      timeline = Timeline.new()
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T12:00:00Z"

      interval =
        Interval.new_fixed_schedule(
          start_time,
          end_time
        )

      timeline_with_interval = Timeline.add_interval(timeline, interval)
      segments = Timeline.segment_by_bridges(timeline_with_interval)
      assert length(segments) == 1
      assert hd(segments).metadata.segment == 1
    end

    test "segment_by_bridges/1 creates multiple segments with bridges" do
      timeline = Timeline.new()
      start1 = "2025-01-01T10:00:00Z"
      end1 = "2025-01-01T11:00:00Z"

      interval1 =
        Interval.new_fixed_schedule(start1, end1)

      start2 = "2025-01-01T11:30:00Z"
      end2 = "2025-01-01T12:30:00Z"

      interval2 =
        Interval.new_fixed_schedule(start2, end2)

      timeline = timeline |> Timeline.add_interval(interval1) |> Timeline.add_interval(interval2)
      bridge_pos = "2025-01-01T11:15:00Z"
      bridge = Bridge.new("decision_1", bridge_pos, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      segments = Timeline.segment_by_bridges(timeline_with_bridge)
      assert length(segments) == 2
      [segment1, segment2] = segments
      assert segment1.metadata.segment == 1
      assert segment1.metadata.bridge_before == nil
      assert segment2.metadata.segment == 2
      assert segment2.metadata.bridge_before == bridge_pos
    end

    test "segment_by_bridges/1 filters intervals by segment time ranges" do
      timeline = Timeline.new()
      start1 = "2025-01-01T10:00:00Z"
      end1 = "2025-01-01T10:30:00Z"

      interval1 =
        Interval.new_fixed_schedule(start1, end1)

      start2 = "2025-01-01T11:30:00Z"
      end2 = "2025-01-01T12:00:00Z"

      interval2 =
        Interval.new_fixed_schedule(start2, end2)

      timeline = timeline |> Timeline.add_interval(interval1) |> Timeline.add_interval(interval2)
      bridge_pos = "2025-01-01T11:00:00Z"
      bridge = Bridge.new("decision_1", bridge_pos, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      segments = Timeline.segment_by_bridges(timeline_with_bridge)
      assert length(segments) == 2
      [segment1, segment2] = segments
      assert map_size(segment1.intervals) == 1
      assert map_size(segment2.intervals) == 1
      segment1_interval = segment1.intervals |> Map.values() |> hd()
      segment2_interval = segment2.intervals |> Map.values() |> hd()
      assert segment1_interval.id == interval1.id
      assert segment2_interval.id == interval2.id
    end

    test "segment_by_bridges/1 handles overlapping intervals correctly" do
      timeline = Timeline.new()
      start1 = "2025-01-01T10:00:00Z"
      end1 = "2025-01-01T12:00:00Z"

      interval1 =
        Interval.new_fixed_schedule(start1, end1)

      timeline_with_interval = Timeline.add_interval(timeline, interval1)
      bridge_pos = "2025-01-01T11:00:00Z"
      bridge = Bridge.new("decision_1", bridge_pos, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline_with_interval, bridge)
      segments = Timeline.segment_by_bridges(timeline_with_bridge)
      assert length(segments) == 2
      [segment1, segment2] = segments
      assert map_size(segment1.intervals) == 1
      assert map_size(segment2.intervals) == 1
      segment1_interval = segment1.intervals |> Map.values() |> hd()
      segment2_interval = segment2.intervals |> Map.values() |> hd()
      assert segment1_interval.id == interval1.id
      assert segment2_interval.id == interval1.id
    end

    test "segment_by_bridges/1 excludes empty segments" do
      timeline = Timeline.new()
      start1 = "2025-01-01T10:00:00Z"
      end1 = "2025-01-01T10:30:00Z"

      interval1 =
        Interval.new_fixed_schedule(start1, end1)

      timeline_with_interval = Timeline.add_interval(timeline, interval1)
      bridge_pos = "2025-01-01T11:00:00Z"
      bridge = Bridge.new("decision_1", bridge_pos, :decision)
      timeline_with_bridge = Timeline.add_bridge(timeline_with_interval, bridge)
      segments = Timeline.segment_by_bridges(timeline_with_bridge)
      assert length(segments) == 1
      assert map_size(hd(segments).intervals) == 1
    end
  end

  describe("bridge utility functions") do
    test "bridge_positions/1 returns sorted bridge positions" do
      timeline = Timeline.new()
      pos1 = "2025-01-01T11:00:00Z"
      pos2 = "2025-01-01T12:00:00Z"
      pos3 = "2025-01-01T10:00:00Z"
      bridge1 = Bridge.new("b1", pos1, :decision)
      bridge2 = Bridge.new("b2", pos2, :condition)
      bridge3 = Bridge.new("b3", pos3, :synchronization)

      timeline =
        timeline
        |> Timeline.add_bridge(bridge2)
        |> Timeline.add_bridge(bridge3)
        |> Timeline.add_bridge(bridge1)

      positions = Timeline.bridge_positions(timeline)
      assert positions == [pos3, pos1, pos2]
    end

    test "bridges_in_range/3 finds bridges within time range" do
      timeline = Timeline.new()
      start_time = "2025-01-01T10:00:00Z"
      end_time = "2025-01-01T14:00:00Z"
      pos1 = "2025-01-01T11:00:00Z"
      pos2 = "2025-01-01T15:00:00Z"
      pos3 = "2025-01-01T12:00:00Z"
      bridge1 = Bridge.new("b1", pos1, :decision)
      bridge2 = Bridge.new("b2", pos2, :decision)
      bridge3 = Bridge.new("b3", pos3, :decision)

      timeline =
        timeline
        |> Timeline.add_bridge(bridge1)
        |> Timeline.add_bridge(bridge2)
        |> Timeline.add_bridge(bridge3)

      bridges_in_range = Timeline.bridges_in_range(timeline, start_time, end_time)
      assert length(bridges_in_range) == 2
      assert Enum.map(bridges_in_range, & &1.id) |> Enum.sort() == ["b1", "b3"]
    end
  end

  describe("bridge-aware composition") do
    test "chain/1 preserves bridges from all timelines" do
      timeline1 = Timeline.new()
      pos1 = "2025-01-01T11:00:00Z"
      bridge1 = Bridge.new("b1", pos1, :decision)
      timeline1 = Timeline.add_bridge(timeline1, bridge1)
      timeline2 = Timeline.new()
      pos2 = "2025-01-01T12:00:00Z"
      bridge2 = Bridge.new("b2", pos2, :condition)
      timeline2 = Timeline.add_bridge(timeline2, bridge2)
      chained = Timeline.chain([timeline1, timeline2])
      bridges = Map.get(chained.metadata, :bridges, %{})
      assert map_size(bridges) == 2
      # Verify bridges are converted to semantic bridges
      assert bridges["b1"].semantic_relation != nil
      assert bridges["b2"].semantic_relation != nil
    end
  end
end
