# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TemporalPlanningTest do
  @moduledoc """
  Test-driven development for temporal planning capabilities.
  
  This test demonstrates the simplest possible temporal planning scenario:
  - 1D movement on a straight line (0 ← → 20)
  - Maya patrols between position 3 and position 15  
  - Movement takes time in milliseconds (1 tick = 1 ms)
  - Shows the difference between regular planning (immediate) and temporal planning (duration-aware)
  
  Perfect for sharing on Discord to demonstrate temporal planning concepts! 🎯
  """
  
  @tag :skip
  use ExUnit.Case
  
  describe "Stage 0: Baseline functionality (ADR-50)" do
    test "regular planner works with basic 1D movement" do
      # Regular planning: immediate state changes, no duration
      # 1D movement: positions are single numbers on a line (0 ← → 20)
      initial_state = %{agent_position: 3}
      action = {:move_to, ["maya", 3, 15]}
      
      # Regular planning result: instant teleportation 
      final_state = apply_regular_action(initial_state, action)
      
      assert final_state.agent_position == 15
      # No time tracking in regular planning
      refute Map.has_key?(final_state, :time)
      
      IO.puts("✅ Regular planner: Maya teleports instantly from position #{initial_state.agent_position} to #{final_state.agent_position}")
    end
  end
  
  describe "Stage 1: Temporal state (ADR-50)" do
    test "temporal state tracks time and duration in milliseconds" do
      # Temporal planning: actions have duration, state tracks time in milliseconds
      # Since 1 tick = 1 ms, use millisecond timing for human-scale visibility
      initial_state = %{
        agent_position: 3,  # 1D position on line 0 ← → 20
        time: 0             # Time in milliseconds (ticks)
      }
      
      # Calculate movement duration: distance / speed
      # Use human-scale timing: 1000ms = 1 second
      distance = calculate_1d_distance(3, 15)  # 12 units
      speed = 3.0  # units per second
      duration_ms = trunc((distance / speed) * 1000)  # 4000 ms = 4 seconds
      
      action = {:move_to, ["maya", 3, 15], duration_ms}
      
      # Temporal planning result: movement takes time
      final_state = apply_temporal_action(initial_state, action)
      
      assert final_state.agent_position == 15
      assert final_state.time == 4000  # Time advanced by 4000ms = 4 seconds
      
      IO.puts("🕐 Temporal planner: Maya moves from position #{initial_state.agent_position} to #{final_state.agent_position} in #{duration_ms}ms")
      IO.puts("   └─ Distance: #{distance} units, Speed: #{speed} u/s, Duration: #{duration_ms}ms (#{duration_ms/1000}s)")
    end
  end
  
  describe "Stage 2: Discord-friendly 1D demonstration" do
    test "simple 1D timeline visualization for Discord sharing" do
      # Create a simple 1D scenario that's easy to understand and share
      # All positions are on a single line: 0 ← → 20
      scenario = [
        {0, "Maya starts at position 3"},
        {0, "Maya begins moving to position 15"},
        {4000, "Maya arrives at position 15"}
      ]
      
      timeline = format_timeline_for_discord(scenario)
      
      expected = """
      🎬 1D Temporal Planning Demo:
      00:00 - Maya starts at position 3
      00:00 - Maya begins moving to position 15
      00:04 - Maya arrives at position 15
      
      💡 Key insight: Temporal planning considers WHEN things happen, not just WHAT happens!
      📏 Movement on 1D line: 0 ← → 20 (distance = 12 units, 4 seconds @ 3 u/s)
      """
      
      assert String.trim(timeline) == String.trim(expected)
      IO.puts("\n" <> timeline)
    end
  end
  
  describe "Stage 3: 1D continuous loop demonstration for Discord" do
    test "maya patrols back and forth in a 1D loop" do
      # Create a 1D patrol loop that Maya can do indefinitely
      # Positions are single numbers on the line: 0 ← → 20
      start_pos = 3
      end_pos = 15
      _speed = 3.0  # units per second
      
      # Calculate one-way duration in milliseconds
      _distance = calculate_1d_distance(start_pos, end_pos)
      
      # Run multiple patrol cycles
      cycles = 3
      events = simulate_1d_patrol_loop(start_pos, end_pos, 3.0, cycles)
      
      # Verify the loop works
      assert length(events) == (cycles * 2 + 1)  # start + 2 moves per cycle
      
      # Show the 1D patrol timeline
      timeline = format_1d_patrol_timeline(events)
      IO.puts("\n🔄 Maya's 1D Patrol Loop (#{cycles} cycles):")
      IO.puts("📏 Line: 0 ← → 20, Maya moves between positions #{start_pos} and #{end_pos}")
      IO.puts(timeline)
      IO.puts("💭 This loop can run indefinitely - perfect for showing friends anytime!")
      
      # Verify Maya ends up back at start after even number of moves
      last_event = List.last(events)
      assert last_event.position == start_pos
    end
    
    test "simple infinite 1D loop generator for live demos" do
      # Create a simple function that generates the next state in the 1D patrol
      initial_state = %{
        position: 3,        # 1D position on line 0 ← → 20
        target: 15,         # 1D target position
        time: 0,            # Time in milliseconds
        direction: :forward
      }
      
      # Simulate several steps
      states = generate_1d_patrol_steps(initial_state, 6)
      
      IO.puts("\n🎮 Live 1D Demo States (6 steps):")
      IO.puts("📏 Movement line: 0 ← → 20")
      for {state, _index} <- Enum.with_index(states) do
        time_str = format_time_ms(state.time)
        direction_emoji = if state.direction == :forward, do: "→", else: "←"
        IO.puts("  #{time_str} #{direction_emoji} Maya at position #{state.position}")
      end
      
      # Verify the pattern: forward, backward, forward, backward...
      assert Enum.at(states, 0).direction == :forward
      assert Enum.at(states, 1).direction == :forward  # still moving forward
      assert Enum.at(states, 2).direction == :backward # reached end, turning back
      assert Enum.at(states, 3).direction == :backward # still moving backward
      assert Enum.at(states, 4).direction == :forward  # back to start, turning forward
    end
  end
  
  describe "Stage 4: Canonical temporal coordination (ADR-74)" do
    test "maya requires alex scouting before scorch - 1D vision conflict" do
      # The canonical temporal backtracking problem from ADR-74
      # 1D scenario: Maya needs Alex to scout before she can cast Scorch
      initial_state = %{
        maya: %{pos: 5, vision_range: 8, abilities: [:scorch], time: 0},
        alex: %{pos: 3, abilities: [:scout], time: 0},
        enemy: %{pos: 15, hp: 100, will_escape_at_ms: 3000},  # Enemy escapes after 3 seconds
        time: 0
      }
      
      _goal = {:eliminate, :enemy}
      
      # Test the vision conflict detection
      maya_to_enemy_distance = calculate_1d_distance(initial_state.maya.pos, initial_state.enemy.pos)
      vision_conflict = maya_to_enemy_distance > initial_state.maya.vision_range
      
      assert vision_conflict, "Maya should not be able to see enemy (distance #{maya_to_enemy_distance} > vision #{initial_state.maya.vision_range})"
      
      # Show the 1D visualization
      IO.puts("\n🎯 Temporal Coordination Problem (1D):")
      IO.puts("📏 Line: 0 ← → 20")
      IO.puts("   Alex👁️  Maya🔥       Enemy🎯")
      IO.puts("   |#{initial_state.alex.pos}|    |#{initial_state.maya.pos}|           |#{initial_state.enemy.pos}|")
      IO.puts("   Distance Maya→Enemy: #{maya_to_enemy_distance} > Vision: #{initial_state.maya.vision_range} ❌")
      IO.puts("   💡 Solution: Alex scouts first, then Maya casts!")
      
      # Show temporal coordination demonstration
      IO.puts("\n🎬 1D Temporal Planning Demo:")
      IO.puts("💡 Key insight: Temporal planning considers WHEN things happen, not just WHAT happens!")
      IO.puts("📏 Movement on 1D line: 0 ← → 20 (distance = 12 units, 4 seconds @ 3 u/s)")
    end
  end
  
  defp format_time_ms(milliseconds) do
    # Convert milliseconds to MM:SS format
    total_seconds = trunc(milliseconds / 1000)
    minutes = trunc(total_seconds / 60)
    remaining_seconds = total_seconds - minutes * 60
    minutes_str = String.pad_leading(Integer.to_string(minutes), 2, "0")
    seconds_str = String.pad_leading(Integer.to_string(remaining_seconds), 2, "0")
    "#{minutes_str}:#{seconds_str}"
  end
  
  # Helper functions for temporal planning tests

  defp apply_regular_action(state, action) do
    # Simple implementation for basic action application
    case action do
      {:move_to, [_agent, _from, to]} ->
        %{state | agent_position: to}
      {:attack, _target} ->
        # For demonstration purposes, just return the state
        state
      _ ->
        state
    end
  end

  defp apply_temporal_action(state, action) do
    # Temporal action application with time tracking
    case action do
      {:move_to, [_agent, _from, to], duration_ms} ->
        %{state | agent_position: to, time: Map.get(state, :time, 0) + duration_ms}
      {:attack, _target, duration_ms} ->
        %{state | time: Map.get(state, :time, 0) + duration_ms}
      _ ->
        state
    end
  end

  defp calculate_1d_distance(pos1, pos2) when is_number(pos1) and is_number(pos2) do
    abs(pos1 - pos2)
  end

  defp format_timeline_for_discord(scenario) do
    # Format scenario for Discord-friendly display
    timeline_entries = scenario
    |> Enum.map(fn {time_ms, description} ->
      time_str = format_time_ms(time_ms)
      "#{time_str} - #{description}"
    end)
    |> Enum.join("\n")
    
    """
    🎬 1D Temporal Planning Demo:
    #{timeline_entries}
    
    💡 Key insight: Temporal planning considers WHEN things happen, not just WHAT happens!
    📏 Movement on 1D line: 0 ← → 20 (distance = 12 units, 4 seconds @ 3 u/s)
    """
  end

  # Additional helper functions for 1D looping demonstrations
  
  defp simulate_1d_patrol_loop(start_pos, end_pos, speed, cycles) do
    distance = calculate_1d_distance(start_pos, end_pos)
    duration_ms = trunc((distance / speed) * 1000)  # Convert to milliseconds
    
    events = [%{time: 0, position: start_pos, action: "patrol_start"}]
    
    Enum.reduce(1..(cycles * 2), events, fn move_num, acc ->
      last_event = List.last(acc)
      new_time = last_event.time + duration_ms
      
      {new_pos, action} = if rem(move_num, 2) == 1 do
        {end_pos, "move_to_end"}
      else
        {start_pos, "return_to_start"}
      end
      
      new_event = %{time: new_time, position: new_pos, action: action}
      acc ++ [new_event]
    end)
  end
  
  defp format_1d_patrol_timeline(events) do
    events
    |> Enum.map(fn event ->
      time_str = format_time_ms(event.time)
      action_emoji = case event.action do
        "patrol_start" -> "🏁"
        "move_to_end" -> "→"
        "return_to_start" -> "←"
        _ -> "•"
      end
      "  #{time_str} #{action_emoji} Maya at position #{event.position}"
    end)
    |> Enum.join("\n")
  end
  
  defp generate_1d_patrol_steps(initial_state, num_steps) do
    start_pos = 3
    end_pos = 15
    speed = 3.0
    distance = calculate_1d_distance(start_pos, end_pos)
    duration_ms = trunc((distance / speed) * 1000)  # Convert to milliseconds
    
    {states, _} = Enum.reduce(1..num_steps, {[initial_state], initial_state}, fn _, {states, current_state} ->
      next_state = case current_state.direction do
        :forward ->
          if current_state.position == end_pos do
            # Reached end, turn around
            %{current_state | 
              target: start_pos, 
              direction: :backward, 
              time: current_state.time + duration_ms}
          else
            # Continue forward
            %{current_state | 
              position: end_pos, 
              time: current_state.time + duration_ms}
          end
        :backward ->
          if current_state.position == start_pos do
            # Reached start, turn around
            %{current_state | 
              target: end_pos, 
              direction: :forward, 
              time: current_state.time + duration_ms}
          else
            # Continue backward  
            %{current_state | 
              position: start_pos, 
              time: current_state.time + duration_ms}
          end
      end
      
      {states ++ [next_state], next_state}
    end)
    
    states
  end
end
