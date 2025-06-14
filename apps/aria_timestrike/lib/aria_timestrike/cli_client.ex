# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.CliClient do
  @moduledoc """
  CLI client for the Timestrike game.
  
  This module provides a terminal-based interface that displays the game state
  in real-time and accepts user input for game commands.
  """
  
  alias AriaTimestrike.GameEngine
  
  @tick_interval 100  # 100ms ticks
  
  def start(initial_game_state) do
    # Initialize the game state in a process
    {:ok, game_pid} = Agent.start_link(fn -> initial_game_state end)
    
    # Start the game loop
    spawn(fn -> game_loop(game_pid, 0) end)
    
    # Handle user input
    input_loop(game_pid)
  end
  
  defp game_loop(game_pid, tick_count) do
    game_state = Agent.get(game_pid, & &1)
    
    # Clear screen and display current state
    clear_screen()
    display_game_state(game_state, tick_count)
    
    # Update agent positions (simple simulation)
    updated_state = update_agent_positions(game_state, tick_count)
    Agent.update(game_pid, fn _ -> updated_state end)
    
    # Continue the loop
    Process.sleep(@tick_interval)
    game_loop(game_pid, tick_count + 1)
  end
  
  defp input_loop(game_pid) do
    case IO.gets("") do
      " \n" ->  # Spacebar pressed
        IO.puts("\n🔄 INTERRUPTION! Replanning...")
        game_state = Agent.get(game_pid, & &1)
        {:ok, new_goal} = GameEngine.generate_next_goal(game_state, "Alex")
        IO.puts("🎯 New goal: #{inspect(new_goal)}")
        Process.sleep(1000)
        input_loop(game_pid)
        
      "q\n" ->  # Quit
        IO.puts("\n👋 Game ended.")
        System.halt(0)
        
      _ ->
        input_loop(game_pid)
    end
  end
  
  defp clear_screen do
    IO.write("\e[2J\e[H")  # ANSI escape codes to clear screen
  end
  
  defp display_game_state(game_state, tick_count) do
    IO.puts("🎯 Aria Timestrike - Live Game State")
    IO.puts("====================================")
    IO.puts("Tick: #{tick_count} | Time: #{Float.round(tick_count * 0.1, 1)}s")
    IO.puts("")
    
    # Display mission status
    IO.puts("📋 Mission: #{game_state.mission_status}")
    IO.puts("")
    
    # Display agents
    IO.puts("👥 Agents:")
    for {name, agent} <- game_state.agents do
      {x, y, z} = agent.position
      # Handle both integer and float positions
      x_display = if is_float(x), do: Float.round(x, 1), else: x
      y_display = if is_float(y), do: Float.round(y, 1), else: y
      z_display = if is_float(z), do: Float.round(z, 1), else: z
      
      status_icon = case agent.status do
        :alive -> "🟢"
        :dead -> "🔴"
        _ -> "⚪"
      end
      
      IO.puts("  #{status_icon} #{name}: (#{x_display}, #{y_display}, #{z_display}) - Speed: #{agent.speed}")
    end
    
    IO.puts("")
    IO.puts("🎮 Controls:")
    IO.puts("  SPACEBAR - Interrupt/Replan")
    IO.puts("  Q - Quit")
    IO.puts("")
    
    # Display ASCII map
    display_ascii_map(game_state)
  end
  
  defp display_ascii_map(game_state) do
    IO.puts("🗺️  Map:")
    IO.puts("   0 1 2 3 4 5 6 7 8 9")
    
    for y <- 0..7 do
      row = "#{y}  "
      
      row = for x <- 0..9, into: row do
        agent_at_pos = find_agent_at_position(game_state, {x, 0, y})
        case agent_at_pos do
          nil -> "."
          "Alex" -> "A"
          "Maya" -> "M"
          "Jordan" -> "J"
          _ -> "?"
        end <> " "
      end
      
      IO.puts(row)
    end
    
    IO.puts("")
  end
  
  defp find_agent_at_position(game_state, target_pos) do
    Enum.find_value(game_state.agents, fn {name, agent} ->
      {x, y, z} = agent.position
      rounded_pos = {round(x), round(y), round(z)}
      if rounded_pos == target_pos, do: name, else: nil
    end)
  end
  
  defp update_agent_positions(game_state, tick_count) do
    # Simple movement simulation for Alex
    time_in_seconds = tick_count * 0.1
    
    # Alex moves in a simple pattern
    alex_pos = calculate_alex_position(time_in_seconds)
    
    # Update Alex's position in the agents map
    updated_agents = Map.put(game_state.agents, "Alex", %{game_state.agents["Alex"] | position: alex_pos})
    
    %{game_state | agents: updated_agents}
  end
  
  defp calculate_alex_position(time) do
    # Simple back-and-forth movement
    cycle_time = 10.0  # 10 second cycle
    progress = :math.fmod(time, cycle_time) / cycle_time
    
    if progress < 0.5 do
      # Moving from {2,0,3} to {8,0,3}
      x = 2 + (6 * progress * 2)
      {x, 0, 3}
    else
      # Moving from {8,0,3} to {2,0,3}
      x = 8 - (6 * (progress - 0.5) * 2)
      {x, 0, 3}
    end
  end
end
