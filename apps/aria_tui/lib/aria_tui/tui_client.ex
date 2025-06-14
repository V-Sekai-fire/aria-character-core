# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Client do
  @moduledoc """
  Enhanced Terminal User Interface (TUI) client providing a rich, interactive terminal interface.

  This module provides a responsive terminal interface that displays
  application state in real-time with a beautiful layout, colors, and responsive controls.
  Uses ANSI escape codes for cross-platform terminal enhancement.
  """

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
        test_mode: "overview",
        content_provider: AriaTui.DefaultContentProvider,
        last_message: "🎯 TUI Component Test Suite started! Press 1-4 for tests, Q to quit.",
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
        "r" -> %{state | last_message: "🔄 Display refreshed"}
        "1" -> %{state | test_mode: "colors", last_message: "🎨 Color test mode"}
        "2" -> %{state | test_mode: "layout", last_message: "📐 Layout test mode"}
        "3" -> %{state | test_mode: "responsive", last_message: "📱 Responsive test mode"}
        "4" -> %{state | test_mode: "components", last_message: "🧩 Component test mode"}
        "0" -> %{state | test_mode: "overview", last_message: "🎯 Overview mode"}
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
    
    # Clear screen once at startup
    IO.write("\e[2J\e[H")

    # Set up signal handling for clean exit and resize
    Process.flag(:trap_exit, true)

    # Try to set up terminal resize handling (Unix-specific)
    try do
      :os.set_signal(:sigwinch, :handle)
    rescue
      _ -> :ok  # Ignore if not supported
    end

    # Try to set up interrupt handling (Unix-specific)
    try do
      :os.set_signal(:sigint, :handle)
      :os.set_signal(:sigterm, :handle)
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

    # Display current state using the display module (it handles screen clearing)
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
          paused = not state.paused
          message = if paused, do: "⏸️ TUI paused", else: "▶️ TUI resumed"
          %{state | paused: paused, last_message: message}
        end)
        enhanced_input_loop(game_pid)

      "1\n" ->  # Color test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "colors", last_message: "🎨 Color test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "2\n" ->  # Layout test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "layout", last_message: "📐 Layout test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "3\n" ->  # Responsive test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "responsive", last_message: "📱 Responsive test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "4\n" ->  # Component test
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "components", last_message: "🧩 Component test mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "0\n" ->  # Overview
        Agent.update(game_pid, fn state ->
          %{state | test_mode: "overview", last_message: "🏠 Overview mode activated"}
        end)
        enhanced_input_loop(game_pid)

      "r\n" ->  # Refresh
        Agent.update(game_pid, fn state ->
          %{state | last_message: "🔄 Display refreshed", last_update: DateTime.utc_now()}
        end)
        enhanced_input_loop(game_pid)

      "p\n" ->  # P key pressed (legacy pause)
        Agent.update(game_pid, fn state ->
          paused = not state.paused
          message = if paused, do: "⏸️ TUI paused", else: "▶️ TUI resumed"
          %{state | paused: paused, last_message: message}
        end)
        enhanced_input_loop(game_pid)

      "q\n" ->  # Quit
        cleanup_terminal()
        IO.puts("\n\e[92m👋 TUI test suite ended. Thanks for testing!\e[0m")
        System.halt(0)

      input when input in ["\e", "\e[", <<3>>, <<4>>] ->  # Escape sequences or Ctrl+C/D
        cleanup_terminal()
        IO.puts("\n\e[92m👋 TUI test suite ended. Thanks for testing!\e[0m")
        System.halt(0)

      _ ->
        enhanced_input_loop(game_pid)
    end
  rescue
    # Handle any unexpected errors during input processing
    _ ->
      cleanup_terminal()
      IO.puts("\n\e[91m⚠️ TUI ended unexpectedly. Terminal cleaned up.\e[0m")
      System.halt(1)
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

  # Handle interrupt signals for clean exit
  def handle_info({:signal, :sigint}, _state) do
    cleanup_terminal()
    IO.puts("\n\e[92m👋 TUI interrupted. Terminal cleaned up.\e[0m")
    System.halt(0)
  end

  def handle_info({:signal, :sigterm}, _state) do
    cleanup_terminal()
    IO.puts("\n\e[92m👋 TUI terminated. Terminal cleaned up.\e[0m")
    System.halt(0)
  end

  def handle_info(_, state), do: {:noreply, state}
end
