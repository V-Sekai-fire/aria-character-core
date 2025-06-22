# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.BridgeTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.Timeline.Bridge

  alias AriaEngine.Timeline.Bridge

  # TODO: 2025-06-21 Autobridge timelines.

  describe "new/4" do
    test "creates a bridge with required parameters" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test_bridge", position, :decision)

      assert bridge.id == "test_bridge"
      assert bridge.position == position
      assert bridge.type == :decision
      assert bridge.metadata == %{}
    end

    test "creates a bridge with metadata" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      metadata = %{priority: :high, options: ["north", "south"]}
      bridge = Bridge.new("test_bridge", position, :decision, metadata: metadata)

      assert bridge.metadata == metadata
    end

    test "validates bridge type" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")

      assert_raise ArgumentError, fn ->
        Bridge.new("test_bridge", position, :invalid_type)
      end
    end
  end

  describe "valid_type?/1" do
    test "returns true for valid bridge types" do
      assert Bridge.valid_type?(:decision)
      assert Bridge.valid_type?(:condition)
      assert Bridge.valid_type?(:synchronization)
      assert Bridge.valid_type?(:resource_check)
    end

    test "returns false for invalid bridge types" do
      refute Bridge.valid_type?(:invalid)
      refute Bridge.valid_type?(:unknown)
      refute Bridge.valid_type?(nil)
    end
  end

  describe "type checking functions" do
    test "decision?/1" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      decision_bridge = Bridge.new("test", position, :decision)
      condition_bridge = Bridge.new("test", position, :condition)

      assert Bridge.decision?(decision_bridge)
      refute Bridge.decision?(condition_bridge)
    end

    test "condition?/1" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      condition_bridge = Bridge.new("test", position, :condition)
      decision_bridge = Bridge.new("test", position, :decision)

      assert Bridge.condition?(condition_bridge)
      refute Bridge.condition?(decision_bridge)
    end

    test "synchronization?/1" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      sync_bridge = Bridge.new("test", position, :synchronization)
      decision_bridge = Bridge.new("test", position, :decision)

      assert Bridge.synchronization?(sync_bridge)
      refute Bridge.synchronization?(decision_bridge)
    end

    test "resource_check?/1" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      resource_bridge = Bridge.new("test", position, :resource_check)
      decision_bridge = Bridge.new("test", position, :decision)

      assert Bridge.resource_check?(resource_bridge)
      refute Bridge.resource_check?(decision_bridge)
    end
  end

  describe "update_metadata/2" do
    test "updates bridge metadata" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test", position, :decision, metadata: %{priority: :low})

      updated_bridge = Bridge.update_metadata(bridge, %{priority: :high, timeout: 30})

      assert updated_bridge.metadata.priority == :high
      assert updated_bridge.metadata.timeout == 30
    end

    test "merges with existing metadata" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test", position, :decision, metadata: %{priority: :low, options: ["a", "b"]})

      updated_bridge = Bridge.update_metadata(bridge, %{priority: :high})

      assert updated_bridge.metadata.priority == :high
      assert updated_bridge.metadata.options == ["a", "b"]
    end
  end

  describe "temporal comparison functions" do
    test "before?/2" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test", position, :decision)

      earlier_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      later_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")

      refute Bridge.before?(bridge, earlier_time)
      assert Bridge.before?(bridge, later_time)
      refute Bridge.before?(bridge, position)
    end

    test "after?/2" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test", position, :decision)

      earlier_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      later_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")

      assert Bridge.after?(bridge, earlier_time)
      refute Bridge.after?(bridge, later_time)
      refute Bridge.after?(bridge, position)
    end

    test "at?/2" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test", position, :decision)

      earlier_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      later_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")

      refute Bridge.at?(bridge, earlier_time)
      refute Bridge.at?(bridge, later_time)
      assert Bridge.at?(bridge, position)
    end
  end

  describe "sort_by_position/1" do
    test "sorts bridges by temporal position" do
      pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      pos3 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")

      bridge1 = Bridge.new("b1", pos1, :decision)
      bridge2 = Bridge.new("b2", pos2, :decision)
      bridge3 = Bridge.new("b3", pos3, :decision)

      # Input in random order
      bridges = [bridge2, bridge3, bridge1]
      sorted = Bridge.sort_by_position(bridges)

      assert Enum.map(sorted, & &1.id) == ["b3", "b1", "b2"]
    end

    test "handles empty list" do
      assert Bridge.sort_by_position([]) == []
    end

    test "handles single bridge" do
      position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      bridge = Bridge.new("test", position, :decision)

      assert Bridge.sort_by_position([bridge]) == [bridge]
    end
  end

  describe "in_range/3" do
    test "finds bridges within time range" do
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")  # In range
      pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")  # Out of range
      pos3 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")  # In range
      pos4 = DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC")  # Out of range

      bridge1 = Bridge.new("b1", pos1, :decision)
      bridge2 = Bridge.new("b2", pos2, :decision)
      bridge3 = Bridge.new("b3", pos3, :decision)
      bridge4 = Bridge.new("b4", pos4, :decision)

      bridges = [bridge1, bridge2, bridge3, bridge4]
      in_range = Bridge.in_range(bridges, start_time, end_time)

      assert length(in_range) == 2
      assert Enum.map(in_range, & &1.id) |> Enum.sort() == ["b1", "b3"]
    end

    test "includes bridges at range boundaries" do
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      bridge_at_start = Bridge.new("start", start_time, :decision)
      bridge_at_end = Bridge.new("end", end_time, :decision)

      bridges = [bridge_at_start, bridge_at_end]
      in_range = Bridge.in_range(bridges, start_time, end_time)

      assert length(in_range) == 2
      assert Enum.map(in_range, & &1.id) |> Enum.sort() == ["end", "start"]
    end

    test "handles empty bridge list" do
      start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")

      assert Bridge.in_range([], start_time, end_time) == []
    end
  end
end
