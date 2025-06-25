# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Test script for semantic bridges functionality
# Run with: elixir test_semantic_bridges.exs

# Add the apps to the code path
Code.append_path("apps/aria_timeline/_build/dev/lib/aria_timeline/ebin")

alias Timeline.{Bridge, Interval}

# Create a timeline with some intervals
timeline = Timeline.new()

# Add some intervals
start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
interval1 = Interval.new(start_time, end_time)

start_time2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
end_time2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
interval2 = Interval.new(start_time2, end_time2)

timeline = timeline
|> Timeline.add_interval(interval1)
|> Timeline.add_interval(interval2)

IO.puts("Timeline created with #{map_size(timeline.intervals)} intervals")

# Test semantic bridge creation
IO.puts("\n=== Testing Semantic Bridge Creation ===")

# Test 1: Create a bridge at timeline start
timeline = Timeline.add_bridge_at_start(timeline, "timeline_start", :synchronization)
bridge = Timeline.get_bridge(timeline, "timeline_start")
IO.puts("Bridge at timeline start: #{bridge.semantic_relation} -> #{DateTime.to_iso8601(bridge.position)}")

# Test 2: Create a bridge at timeline end
timeline = Timeline.add_bridge_at_end(timeline, "timeline_end", :synchronization)
bridge = Timeline.get_bridge(timeline, "timeline_end")
IO.puts("Bridge at timeline end: #{bridge.semantic_relation} -> #{DateTime.to_iso8601(bridge.position)}")

# Test 3: Create a bridge during timeline
timeline = Timeline.add_bridge_during(timeline, "timeline_middle", :decision)
bridge = Timeline.get_bridge(timeline, "timeline_middle")
IO.puts("Bridge during timeline: #{bridge.semantic_relation} -> #{DateTime.to_iso8601(bridge.position)}")

# Test 4: Create a bridge at interval start
timeline = Timeline.add_interval_start_bridge(timeline, interval1.id, "interval_start")
bridge = Timeline.get_bridge(timeline, "interval_start")
IO.puts("Bridge at interval start: #{bridge.semantic_relation} -> #{DateTime.to_iso8601(bridge.position)}")

IO.puts("\n=== Testing Chain Function with Semantic Bridges ===")

# Create two timelines with semantic bridges
timeline1 = Timeline.new()
|> Timeline.add_interval(interval1)
|> Timeline.add_bridge_at_start("t1_start", :synchronization)
|> Timeline.add_bridge_for_chaining("t1_chain")

timeline2 = Timeline.new()
|> Timeline.add_interval(interval2)
|> Timeline.add_bridge_at_start("t2_start", :synchronization)

IO.puts("Timeline 1 bridges: #{length(Timeline.get_bridges(timeline1))}")
IO.puts("Timeline 2 bridges: #{length(Timeline.get_bridges(timeline2))}")

# Chain the timelines
chained = Timeline.chain([timeline1, timeline2])
chained_bridges = Timeline.get_bridges(chained)

IO.puts("Chained timeline bridges: #{length(chained_bridges)}")
IO.puts("Preserved semantic bridges:")
Enum.each(chained_bridges, fn bridge ->
  IO.puts("  - #{bridge.id}: #{bridge.semantic_relation} (#{bridge.reference_target})")
end)

IO.puts("\n=== Why We Don't Merge Bridges ===")
IO.puts("Bridges are timeline-specific because:")
IO.puts("1. Absolute position bridges become invalid when timelines are combined")
IO.puts("2. Semantic bridges maintain their meaning across timeline operations")
IO.puts("3. Each timeline represents a different temporal context")
IO.puts("4. Bridge positions are relative to their original timeline structure")

IO.puts("\nSemantic bridges preserved: #{length(chained_bridges)} out of #{length(Timeline.get_bridges(timeline1)) + length(Timeline.get_bridges(timeline2))} total")
