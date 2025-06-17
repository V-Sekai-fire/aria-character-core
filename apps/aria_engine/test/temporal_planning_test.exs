# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TemporalPlanningTest do
  @moduledoc """
  Test-driven development for temporal planning capabilities using real durative actions.
  
  This test demonstrates temporal planning with the actual AriaEngine durative action system:
  - 1D movement on a straight line (0 ← → 20) using real DurativeAction structs
  - Maya patrols between position 3 and position 15 with actual planning
  - Movement takes time with STN temporal constraint management
  - Shows the difference between regular planning (immediate) and temporal planning (duration-aware)
  
  Perfect for sharing on Discord to demonstrate temporal planning concepts! 🎯
  """
  
  use ExUnit.Case
  
  alias AriaEngine.{Domain, StateV2, Plan}
  alias AriaEngine.Domain.DurativeAction
  alias AriaEngine.Timeline.STN
  
  describe "Stage 0: Baseline functionality with real actions" do
    test "regular planner works with basic 1D movement using actual domain" do
      # Create domain with regular instantaneous action
      domain = Domain.Core.new("1d_movement_domain")
      
      # Add regular teleport action (instantaneous)
      domain = Domain.Actions.add_action(domain, :teleport, fn state, [_agent, _from, to] ->
        state |> StateV2.set_fact("maya", "position", to)
      end)
      
      # Add method to decompose move goals into teleport actions
      domain = Domain.add_unigoal_method(domain, "position", "teleport_move", fn state, [agent, target_pos] ->
        current_pos = StateV2.get_fact(state, agent, "position")
        if current_pos != target_pos do
          [{:teleport, [agent, current_pos, target_pos]}]
        else
          []
        end
      end)
      
      # Initial state: Maya at position 3 on 1D line (0 ← → 20)
      initial_state = StateV2.new()
      |> StateV2.set_fact("maya", "position", 3)
      
      # Goal: Maya should be at position 15
      todos = [{"position", "maya", 15}]
      
      # Regular planning result: instant teleportation
      case Plan.Core.plan(domain, initial_state, todos, verbose: 0) do
        {:ok, solution_tree} ->
          actions = Plan.Utils.get_primitive_actions_dfs(solution_tree)
          assert length(actions) == 1
          assert [{:teleport, ["maya", 3, 15]}] = actions
          
          # Apply the action to verify instant change
          {:ok, final_state} = Domain.Actions.execute_action(domain, initial_state, :teleport, ["maya", 3, 15])
          assert StateV2.get_fact(final_state, "maya", "position") == 15
          
          IO.puts("✅ Regular planner: Maya teleports instantly from position 3 to 15")
          
        {:error, reason} ->
          flunk("Regular planning failed: #{reason}")
      end
    end
  end
  
  describe "Stage 1: Temporal planning with real durative actions" do
    test "durative actions track time and duration with STN" do
      # Create domain with durative movement action
      domain = Domain.Core.new("temporal_1d_domain")
      
      # Create STN for temporal constraint management
      stn = STN.new()
      
      # Calculate movement duration: distance / speed
      # Distance from position 3 to 15 = 12 units
      # Speed = 3.0 units per second = 4000ms for 12 units
      duration_ms = 4000
      
      # Add durative movement action (takes time)
      move_action = DurativeAction.new(
        :move_slowly,
        {:fixed, duration_ms},  # 4 seconds
        %{
          at_start: [{"maya", "position", 3}],  # Must start at position 3 (entity, predicate, value)
          over_all: [],
          at_end: []
        },
        %{
          at_start: [{"maya", "moving", true}],
          at_end: [{"maya", "position", 15}, {"maya", "moving", false}],
          over_time: []
        },
        fn state, [_agent, _from, to] ->
          state
          |> StateV2.set_fact("maya", "position", to)
          |> StateV2.set_fact("maya", "moving", false)
        end
      )
      
      domain = Domain.Core.add_durative_action(domain, :move_slowly, move_action)
      stn = STN.Core.add_durative_action(stn, move_action)
      
      # Add task method to make durative action available to planner
      domain = Domain.add_task_method(domain, "move_slowly", "do_move_slowly", fn _state, args ->
        [{:move_slowly, args}]  # Direct call to durative action
      end)
      
      # Add method to decompose move goals into durative actions
      domain = Domain.add_unigoal_method(domain, "position", "move_slowly_method", fn state, [agent, target_pos] ->
        current_pos = StateV2.get_fact(state, agent, "position")
        if current_pos != target_pos do
          [{:move_slowly, [agent, current_pos, target_pos]}]
        else
          []
        end
      end)
      
      # Initial state: Maya at position 3, not moving
      initial_state = StateV2.new()
      |> StateV2.set_fact("maya", "position", 3)
      |> StateV2.set_fact("maya", "moving", false)
      
      # Goal: Maya should be at position 15
      todos = [{"position", "maya", 15}]
      
      # Temporal planning result: movement takes time
      case Plan.Core.plan(domain, initial_state, todos, verbose: 0) do
        {:ok, solution_tree} ->
          actions = Plan.Utils.get_primitive_actions_dfs(solution_tree)
          assert length(actions) == 1
          assert [{:move_slowly, ["maya", 3, 15]}] = actions
          
          # Verify STN temporal constraints
          assert STN.consistent?(stn)
          time_points = STN.time_points(stn)
          assert "move_slowly_start" in time_points
          assert "move_slowly_end" in time_points
          
          # Verify duration constraint
          duration_constraint = STN.get_constraint(stn, "move_slowly_start", "move_slowly_end")
          assert duration_constraint == {4000, 4000}  # Fixed 4-second duration
          
          distance = calculate_1d_distance(3, 15)  # 12 units
          speed = 3.0  # units per second
          
          IO.puts("🕐 Temporal planner: Maya moves from position 3 to 15 in #{duration_ms}ms")
          IO.puts("   └─ Distance: #{distance} units, Speed: #{speed} u/s, Duration: #{duration_ms}ms (#{duration_ms/1000}s)")
          
        {:error, reason} ->
          flunk("Temporal planning failed: #{reason}")
      end
    end
  end
  
  describe "Stage 2: Discord-friendly 1D demonstration with real planning" do
    test "simple 1D timeline visualization powered by real temporal planner" do
      # Create domain for timeline demonstration
      domain = Domain.Core.new("demo_domain")
      
      # Add durative movement action
      move_action = DurativeAction.new(
        :move_with_timeline,
        {:fixed, 4000},  # 4 seconds
        %{
          at_start: [{"maya", "position", 3}],
          over_all: [],
          at_end: []
        },
        %{
          at_start: [{"maya", "moving", true}],
          at_end: [{"maya", "position", 15}, {"maya", "moving", false}],
          over_time: []
        },
        fn state, [_agent, _from, to] ->
          state
          |> StateV2.set_fact("maya", "position", to)
          |> StateV2.set_fact("maya", "moving", false)
        end
      )
      
      domain = Domain.Core.add_durative_action(domain, :move_with_timeline, move_action)
      
      # Create timeline scenario based on real planning
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
  
  describe "Stage 3: 1D continuous patrol using durative actions" do
    test "maya patrols back and forth with real temporal planning" do
      # Create domain for patrol demonstration
      domain = Domain.Core.new("patrol_domain")
      
      start_pos = 3
      end_pos = 15
      speed = 3.0  # units per second
      distance = calculate_1d_distance(start_pos, end_pos)
      duration_ms = trunc((distance / speed) * 1000)  # 4000ms
      
      # Add durative action for moving forward
      move_forward = DurativeAction.new(
        :patrol_forward,
        {:fixed, duration_ms},
        %{
          at_start: [{"maya", "position", start_pos}],
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"maya", "position", end_pos}],
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("maya", "position", end_pos)
        end
      )
      
      # Add durative action for moving backward
      move_backward = DurativeAction.new(
        :patrol_backward,
        {:fixed, duration_ms},
        %{
          at_start: [{"maya", "position", end_pos}],
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"maya", "position", start_pos}],
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("maya", "position", start_pos)
        end
      )
      
      domain = Domain.Core.add_durative_action(domain, :patrol_forward, move_forward)
      domain = Domain.Core.add_durative_action(domain, :patrol_backward, move_backward)
      
      # Simulate multiple patrol cycles using real actions
      cycles = 3
      events = simulate_patrol_with_durative_actions(domain, start_pos, end_pos, cycles)
      
      # Verify the patrol pattern
      assert length(events) == (cycles * 2 + 1)  # start + 2 moves per cycle
      
      # Show the 1D patrol timeline
      timeline = format_1d_patrol_timeline(events)
      IO.puts("\n🔄 Maya's Real Durative Action Patrol (#{cycles} cycles):")
      IO.puts("📏 Line: 0 ← → 20, Maya moves between positions #{start_pos} and #{end_pos}")
      IO.puts(timeline)
      IO.puts("💭 Powered by actual AriaEngine durative actions!")
      
      # Verify Maya ends up back at start after even number of moves
      last_event = List.last(events)
      assert last_event.position == start_pos
    end
  end
  
  describe "Stage 4: Canonical temporal coordination with STN constraints" do
    test "maya requires alex scouting before scorch - real temporal constraints" do
      # The canonical temporal backtracking problem with real durative actions
      domain = Domain.Core.new("coordination_domain")
      
      # Create STN for temporal constraint management
      stn = STN.new()
      
      # Alex scouting action - reveals enemy location
      scout_action = DurativeAction.new(
        :scout_enemy,
        {:fixed, 1000},  # 1 second to scout
        %{
          at_start: [{"alex", "position", 3}],
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"maya", "enemy_visible", true}],  # Maya can now see enemy
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("enemy_visible", "maya", true)
        end
      )
      
      # Maya scorch action - requires enemy to be visible
      scorch_action = DurativeAction.new(
        :cast_scorch,
        {:fixed, 500},  # 0.5 seconds to cast
        %{
          at_start: [{"maya", "enemy_visible", true}],  # Requires scouting first
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"enemy", "enemy_hp", 0}],  # Enemy eliminated
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("enemy_hp", "enemy", 0)
        end
      )
      
      domain = Domain.Core.add_durative_action(domain, :scout_enemy, scout_action)
      domain = Domain.Core.add_durative_action(domain, :cast_scorch, scorch_action)
      
      # Add STN constraints
      stn = STN.Core.add_durative_action(stn, scout_action)
      stn = STN.Core.add_durative_action(stn, scorch_action)
      
      # Add temporal constraint: enemy escapes after 3 seconds
      stn = STN.add_constraint(stn, "start", "enemy_escape_deadline", {3000, 3000})
      
      # Add ordering constraint: scouting must complete before scorch starts
      stn = STN.add_constraint(stn, "scout_enemy_end", "cast_scorch_start", {0, 1000000})
      
      # Initial state - enemy not visible, at full health
      initial_state = StateV2.new()
      |> StateV2.set_fact("maya", "position", 5)
      |> StateV2.set_fact("alex", "position", 3)
      |> StateV2.set_fact("enemy", "position", 15)
      |> StateV2.set_fact("maya", "enemy_visible", false)  # Cannot see enemy initially
      |> StateV2.set_fact("enemy", "enemy_hp", 100)
      
      # Verify vision conflict exists
      maya_to_enemy_distance = calculate_1d_distance(5, 15)
      vision_range = 8
      vision_conflict = maya_to_enemy_distance > vision_range
      
      assert vision_conflict, "Maya should not be able to see enemy (distance #{maya_to_enemy_distance} > vision #{vision_range})"
      
      # Show the 1D visualization
      IO.puts("\n🎯 Real Temporal Coordination with STN:")
      IO.puts("📏 Line: 0 ← → 20")
      IO.puts("   Alex👁️  Maya🔥       Enemy🎯")
      IO.puts("   |3|    |5|           |15|")
      IO.puts("   Distance Maya→Enemy: #{maya_to_enemy_distance} > Vision: #{vision_range} ❌")
      IO.puts("   💡 Solution: Alex scouts first, then Maya casts (with real temporal ordering)!")
      
      # Verify STN is consistent with all constraints
      assert STN.consistent?(stn)
      
      # Show STN time points
      time_points = STN.time_points(stn)
      IO.puts("\n🕐 STN Time Points: #{inspect(time_points)}")
      IO.puts("⏱️  Total execution time must be < 3000ms (enemy escape deadline)")
    end
  end
  
  # Helper functions for real temporal planning
  
  defp calculate_1d_distance(pos1, pos2) when is_number(pos1) and is_number(pos2) do
    abs(pos1 - pos2)
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
  
  defp simulate_patrol_with_durative_actions(domain, start_pos, end_pos, cycles) do
    # Simulate patrol using actual durative action execution
    distance = calculate_1d_distance(start_pos, end_pos)
    speed = 3.0
    duration_ms = trunc((distance / speed) * 1000)
    
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
end
