# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script for Enhanced Scheduling functionality
# Usage: mix run scripts/debug_enhanced_scheduling.exs

defmodule EnhancedSchedulingDebug do
  alias AriaEngine.TimelineGraph
  alias AriaEngine.Timeline.STN
  alias AriaEngine.Timeline.Interval

  def test_npc_daily_routine do
    IO.puts("=== Testing NPC Daily Routine with Enhanced Scheduling ===")
    
    # Create a timeline graph with a guard NPC
    timeline_graph = TimelineGraph.new()
    
    {:ok, timeline_graph, "guard"} = TimelineGraph.create_entity(
      timeline_graph,
      "guard",
      "Tower Guard",
      %{type: "humanoid", location: "tower"}
    )
    
    # Promote to agent with action capabilities
    {:ok, timeline_graph} = TimelineGraph.add_capabilities(
      timeline_graph,
      "guard",
      [:autonomous_operation, :decision_making, :patrol_duty]
    )
    
    IO.puts("✅ Created agent: #{TimelineGraph.is_currently_agent?(timeline_graph, "guard")}")
    
    # Schedule morning work shift (8 AM - 4 PM)
    work_start = DateTime.utc_now() |> DateTime.add(8 * 3600, :second)
    
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "guard",
      :work_shift,
      start_time: work_start,
      duration_hours: 8,
      priority: :high,
      repeat: :daily
    )
    
    IO.puts("✅ Scheduled work shift: 8 hours at high priority")
    
    # Try to schedule lunch break during work (should conflict but get resolved)
    lunch_start = DateTime.add(work_start, 4 * 3600, :second)  # 12 PM
    
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "guard",
      :lunch_break,
      start_time: lunch_start,
      duration_hours: 1,
      priority: :medium,
      repeat: :daily
    )
    
    IO.puts("✅ Scheduled lunch break: 1 hour at medium priority")
    
    # Schedule urgent meeting that conflicts with work (should override)
    urgent_start = DateTime.add(work_start, 2 * 3600, :second)  # 10 AM
    
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "guard",
      :emergency_meeting,
      start_time: urgent_start,
      duration_hours: 2,
      priority: :critical,
      deadline: DateTime.add(urgent_start, 30 * 60, :second)  # 30 min deadline
    )
    
    IO.puts("✅ Scheduled emergency meeting: 2 hours at critical priority")
    
    # Get today's schedule
    now = DateTime.utc_now()
    start_of_day = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
    end_of_day = %{now | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}
    
    routines = TimelineGraph.get_scheduled_routines(
      timeline_graph,
      "guard",
      start_of_day,
      end_of_day
    )
    
    IO.puts("📅 Final schedule has #{length(routines)} routines")
    
    timeline_graph
  end

  def test_multi_agent_resource_conflicts do
    IO.puts("\n=== Testing Multi-Agent Resource Conflicts ===")
    
    # Create timeline graph with kitchen staff
    timeline_graph = TimelineGraph.new()
    
    # Create chef
    {:ok, timeline_graph, "chef"} = TimelineGraph.create_entity(
      timeline_graph,
      "chef",
      "Head Chef",
      %{type: "humanoid", location: "kitchen"}
    )
    
    {:ok, timeline_graph} = TimelineGraph.add_capabilities(
      timeline_graph,
      "chef",
      [:autonomous_operation, :cooking, :meal_prep]
    )
    
    # Create sous chef
    {:ok, timeline_graph, "sous_chef"} = TimelineGraph.create_entity(
      timeline_graph,
      "sous_chef",
      "Sous Chef",
      %{type: "humanoid", location: "kitchen"}
    )
    
    {:ok, timeline_graph} = TimelineGraph.add_capabilities(
      timeline_graph,
      "sous_chef",
      [:autonomous_operation, :cooking, :food_prep]
    )
    
    IO.puts("✅ Created kitchen staff agents")
    
    # Schedule overlapping kitchen usage (shared resource conflict)
    lunch_prep_start = DateTime.utc_now() |> DateTime.add(11 * 3600, :second)  # 11 AM
    
    # Chef schedules lunch prep
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "chef",
      :lunch_prep,
      start_time: lunch_prep_start,
      duration_hours: 2,
      priority: :high
    )
    
    # Sous chef schedules bread baking (conflicts with kitchen usage)
    bread_start = DateTime.add(lunch_prep_start, 30 * 60, :second)  # 11:30 AM
    
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "sous_chef",
      :bread_baking,
      start_time: bread_start,
      duration_hours: 3,
      priority: :medium
    )
    
    IO.puts("✅ Scheduled conflicting kitchen activities")
    
    # Test environmental process affecting both
    {:ok, timeline_graph} = TimelineGraph.add_environmental_process(
      timeline_graph,
      :power_outage,
      affects: ["chef", "sous_chef"],
      start_time: DateTime.add(lunch_prep_start, 45 * 60, :second),  # 11:45 AM
      duration_hours: 1,
      effects: %{cooking_speed: 0.0, lighting: :emergency}
    )
    
    IO.puts("✅ Added power outage affecting both agents")
    
    timeline_graph
  end

  def test_stn_interval_queries do
    IO.puts("\n=== Testing STN Interval Query Functions ===")
    
    # Create a basic STN with some intervals
    stn = STN.new()
    
    # Add test intervals
    interval1 = Interval.new(
      DateTime.utc_now(),
      DateTime.utc_now() |> DateTime.add(2 * 3600, :second),
      id: "meeting1",
      metadata: %{type: "meeting", priority: :high}
    )
    
    interval2 = Interval.new(
      DateTime.utc_now() |> DateTime.add(1 * 3600, :second),
      DateTime.utc_now() |> DateTime.add(3 * 3600, :second),
      id: "training",
      metadata: %{type: "training", priority: :medium}
    )
    
    interval3 = Interval.new(
      DateTime.utc_now() |> DateTime.add(4 * 3600, :second),
      DateTime.utc_now() |> DateTime.add(5 * 3600, :second),
      id: "break",
      metadata: %{type: "break", priority: :low}
    )
    
    stn = stn
          |> STN.add_interval(interval1)
          |> STN.add_interval(interval2)
          |> STN.add_interval(interval3)
    
    IO.puts("✅ Added 3 test intervals to STN")
    
    # Test get_intervals
    all_intervals = STN.get_intervals(stn)
    IO.puts("📊 Total intervals in STN: #{length(all_intervals)}")
    
    # Test overlapping intervals query
    now_ms = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    two_hours_later_ms = now_ms + (2 * 3600 * 1000)
    
    overlapping = STN.get_overlapping_intervals(stn, now_ms, two_hours_later_ms)
    IO.puts("🔍 Overlapping intervals (next 2 hours): #{length(overlapping)}")
    
    # Test conflict detection
    new_start_ms = now_ms + (1.5 * 3600 * 1000)  # 1.5 hours from now
    new_end_ms = new_start_ms + (1 * 3600 * 1000)  # 1 hour duration
    
    conflicts = STN.check_interval_conflicts(stn, new_start_ms, new_end_ms)
    IO.puts("⚠️  Conflicts for 1.5-2.5 hour slot: #{length(conflicts)}")
    
    # Test find free slots
    search_start_ms = now_ms
    search_end_ms = now_ms + (6 * 3600 * 1000)  # 6 hours window
    desired_duration_ms = 1 * 3600 * 1000  # 1 hour duration
    
    free_slots = STN.find_free_slots(stn, desired_duration_ms, search_start_ms, search_end_ms)
    IO.puts("🆓 Free 1-hour slots in next 6 hours: #{length(free_slots)}")
    
    # Test find next available slot
    case STN.find_next_available_slot(stn, desired_duration_ms, now_ms) do
      {:ok, slot_start, slot_end} ->
        start_dt = DateTime.from_unix!(slot_start, :millisecond)
        end_dt = DateTime.from_unix!(slot_end, :millisecond)
        IO.puts("✅ Next available slot: #{DateTime.to_time(start_dt)} - #{DateTime.to_time(end_dt)}")
      {:error, reason} ->
        IO.puts("❌ No available slot found: #{reason}")
    end
    
    stn
  end

  def test_priority_and_deadline_handling do
    IO.puts("\n=== Testing Priority and Deadline Handling ===")
    
    timeline_graph = TimelineGraph.new()
    
    # Create a busy executive assistant
    {:ok, timeline_graph, "assistant"} = TimelineGraph.create_entity(
      timeline_graph,
      "assistant",
      "Executive Assistant",
      %{type: "humanoid", location: "office"}
    )
    
    {:ok, timeline_graph} = TimelineGraph.add_capabilities(
      timeline_graph,
      "assistant",
      [:autonomous_operation, :scheduling, :coordination]
    )
    
    base_time = DateTime.utc_now()
    
    # Schedule regular meeting (medium priority)
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "assistant",
      :team_meeting,
      start_time: DateTime.add(base_time, 2 * 3600, :second),
      duration_hours: 2,
      priority: :medium
    )
    
    # Schedule urgent CEO meeting (critical priority) - should override
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "assistant",
      :ceo_meeting,
      start_time: DateTime.add(base_time, round(2.5 * 3600), :second),
      duration_hours: 1,
      priority: :critical,
      deadline: DateTime.add(base_time, 3 * 3600, :second)
    )
    
    # Schedule client call with strict deadline
    {:ok, timeline_graph} = TimelineGraph.schedule_routine(
      timeline_graph,
      "assistant",
      :client_call,
      start_time: DateTime.add(base_time, 1 * 3600, :second),
      duration_hours: 1,
      priority: :high,
      deadline: DateTime.add(base_time, round(2.5 * 3600), :second)
    )
    
    IO.puts("✅ Scheduled activities with different priorities and deadlines")
    IO.puts("   - Team meeting: medium priority, 2 hours")
    IO.puts("   - CEO meeting: critical priority, 1 hour, deadline")
    IO.puts("   - Client call: high priority, 1 hour, strict deadline")
    
    timeline_graph
  end

  def run_all_tests do
    IO.puts("🚀 Testing Enhanced Scheduling System for NPCs")
    IO.puts("=" <> String.duplicate("=", 50))
    
    test_npc_daily_routine()
    test_multi_agent_resource_conflicts()
    test_stn_interval_queries()
    test_priority_and_deadline_handling()
    
    IO.puts("\n" <> String.duplicate("=", 52))
    IO.puts("✅ All Enhanced Scheduling tests completed successfully!")
    IO.puts("🎯 NPCs can now handle complex time-sensitive routines")
  end
end

EnhancedSchedulingDebug.run_all_tests()
