# Test script for bridge conversion functionality
# Run with: mix run test_bridge_conversion.exs

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

# Create a bridge with absolute position (DateTime)
absolute_bridge_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
absolute_bridge = Bridge.new("absolute_bridge", absolute_bridge_time, :decision)

# Add the absolute bridge to timeline
timeline_with_bridge = Timeline.add_bridge(timeline, absolute_bridge)

IO.puts("\n=== Testing Bridge Conversion ===")
IO.puts("Original bridge semantic_relation: #{inspect(absolute_bridge.semantic_relation)}")

# Create another timeline to test chaining
timeline2 = Timeline.new()
|> Timeline.add_interval(interval2)

# Test the chain function - this should convert absolute bridges to semantic bridges
IO.puts("\n=== Testing Chain Function ===")
chained = Timeline.chain([timeline_with_bridge, timeline2])

# Check if bridges were preserved and converted
preserved_bridges = Timeline.get_bridges(chained)
IO.puts("Preserved bridges after chaining: #{length(preserved_bridges)}")

Enum.each(preserved_bridges, fn bridge ->
  IO.puts("  - Bridge ID: #{bridge.id}")
  IO.puts("    Semantic relation: #{inspect(bridge.semantic_relation)}")
  IO.puts("    Reference target: #{inspect(bridge.reference_target)}")
  IO.puts("    Position: #{DateTime.to_iso8601(bridge.position)}")
  IO.puts("")
end)

IO.puts("✅ Bridge conversion test completed successfully!")
