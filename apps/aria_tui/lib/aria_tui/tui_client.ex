# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Client do
  @moduledoc """
  Enhanced Terminal User Interface (TUI) client for the Timestrike game.

  This module provides a rich, interactive terminal interface that displays
  the game state in real-time with a beautiful layout, colors, and responsive controls.
  Uses ANSI escape codes for cross-platform terminal enhancement.
  """

  alias AriaTimestrike.GameEngine
  alias AriaTui.Display

  @tick_interval 100  # 100ms ticks

  def start(initial_game_state \\ nil) do
    game_state = initial_game_state || create_default_game_state()
    {:ok, game_pid} = start_link(initial_game_state: game_state)

    # Setup terminal
    setup_terminal()

    # Start the game loop
    spawn(fn -> enhanced_game_loop(game_pid) end)

    # Handle user input
    enhanced_input_loop(game_pid)
  end

  def start_link(opts \\ []) do
    initial_game_state = Keyword.get(opts, :initial_game_state)
    game_state = initial_game_state || create_default_game_state()
    Agent.start_link(fn ->
      %{
        game_state: game_state,
        tick_count: 0,
        paused: false,
        last_message: "🎯 Enhanced TUI started! Press SPACE to interrupt, P to pause, Q to quit.",
        last_update: DateTime.utc_now()
      }
    end)
  end

  def get_state(pid) do
    Agent.get(pid, fn state -> state end)
  end

  def update_state(pid, fun) do
    Agent.update(pid, fun)
  end

  def handle_key(pid, key) do
    Agent.update(pid, fn state ->
      case key do
        " " -> %{state | last_message: "🔔 Interrupted by user"}
        "p" -> %{state | paused: !state.paused}
        "q" -> %{state | last_message: "👋 Goodbye!"}
        _ -> state
      end
    end)
  end

  def tick(pid) do
    Agent.update(pid, fn state ->
      if state.paused do
        state
      else
        %{state | tick_count: state.tick_count + 1}
      end
    end)
  end

  def handle_message(pid, message) do
    case message do
      {:game_update, new_game_state} ->
        Agent.update(pid, fn state ->
          %{state | game_state: new_game_state}
        end)
      _ ->
        :ok
    end
  end

  defp create_default_game_state do
    %{
      mission_status: "active",
      agents: %{
        "Alex" => %{
          position: {2, 0, 3},
          status: :alive,
          speed: 1.0
        },
        "Maya" => %{
          position: {5, 0, 5},
          status: :alive,
          speed: 1.2
        },
        "Jordan" => %{
          position: {8, 0, 2},
          status: :alive,
          speed: 0.8
        }
      }
    }
  end

  # Terminal handling
  defp setup_terminal do
    # Hide cursor and enable alternative screen buffer
    IO.write("\e[?25l\e[?1049h")

    # Set up signal handling for clean exit and resize
    Process.flag(:trap_exit, true)

    # Try to set up terminal resize handling (Unix-specific)
    try do
      :os.set_signal(:sigwinch, :handle)
    rescue
      _ -> :ok  # Ignore if not supported
    end
  end

  defp cleanup_terminal do
    # Show cursor and restore normal screen buffer
    IO.write("\e[?25h\e[?1049l")
  end

  defp enhanced_game_loop(game_pid) do
    state = Agent.get(game_pid, & &1)

    # Clear screen and display current state using the display module
    Display.clear_screen()
    Display.display_game_state(state)

    # Update agent positions if not paused
    unless state.paused do
      updated_game_state = update_agent_positions(state.game_state, state.tick_count)
      Agent.update(game_pid, fn s ->
        %{s |
          game_state: updated_game_state,
          tick_count: s.tick_count + 1
        }
      end)
    end

    # Continue the loop
    Process.sleep(@tick_interval)
    enhanced_game_loop(game_pid)
  end

  defp enhanced_input_loop(game_pid) do
    case IO.gets("") do
      " \n" ->  # Spacebar pressed
        Agent.update(game_pid, fn state ->
          try do
            {:ok, new_goal} = GameEngine.generate_next_goal(state.game_state, "Alex")
            message = "🔄 INTERRUPTION! New goal: #{inspect(new_goal)}"
            %{state | last_message: message}
          rescue
            _ ->
              %{state | last_message: "🔄 INTERRUPTION! Replanning agents..."}
          end
        end)
        enhanced_input_loop(game_pid)

      "p\n" ->  # P key pressed
        Agent.update(game_pid, fn state ->
          paused = not state.paused
          message = if paused, do: "⏸️ Game paused", else: "▶️ Game resumed"
          %{state | paused: paused, last_message: message}
        end)
        enhanced_input_loop(game_pid)

      "q\n" ->  # Quit
        cleanup_terminal()
        IO.puts("\n\e[92m👋 Game ended. Thanks for playing!\e[0m")
        System.halt(0)

      _ ->
        enhanced_input_loop(game_pid)
    end
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

  # Handle terminal resize signals (if supported)
  def handle_info({:signal, :sigwinch}, state) do
    # Terminal was resized - the next display update will handle it
    {:noreply, state}
  end
  def handle_info(_, state), do: {:noreply, state}
end
