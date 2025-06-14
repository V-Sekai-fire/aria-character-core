# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.WebInterface do
  @moduledoc """
  Web interface for TimeStrike temporal planner with real-time updates.

  Provides:
  - Text-based status display
  - SVG map visualization
  - Real-time temporal planning execution
  - User input handling (SPACEBAR, Q, C)
  """

  use GenServer

  alias AriaEngine.TemporalState
  alias AriaTimestrike.GameEngine

  defstruct [
    :game_state,
    :start_time,
    :current_time,
    :display_messages,
    :user_input_handler,
    :svg_map_data
  ]

  @doc """
  Starts real-time display for the game.
  """
  def start_real_time_display(game_state) do
    GenServer.start_link(__MODULE__, game_state)
  end

  @doc """
  Stops the real-time display.
  """
  def stop_real_time_display(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Handles user input (SPACEBAR, Q, C).
  """
  def handle_user_input(pid, input) do
    GenServer.cast(pid, {:user_input, input})
  end

  @doc """
  Gets the last displayed message.
  """
  def get_last_displayed_message(pid) do
    GenServer.call(pid, :get_last_message)
  end

  @doc """
  Gets current SVG map data for web display.
  """
  def get_svg_map(pid) do
    GenServer.call(pid, :get_svg_map)
  end

  # GenServer callbacks

  @impl true
  def init(game_state) do
    # Start the display loop
    send(self(), :update_display)

    state = %__MODULE__{
      game_state: game_state,
      start_time: System.monotonic_time(:millisecond),
      current_time: 0,
      display_messages: [],
      svg_map_data: generate_initial_map(game_state)
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:update_display, state) do
    # Update current time
    elapsed_ms = System.monotonic_time(:millisecond) - state.start_time
    current_time_seconds = elapsed_ms / 1000.0

    # Generate status display
    status_text = generate_status_display(state.game_state, current_time_seconds)

    # Update SVG map
    updated_svg = update_svg_map(state.svg_map_data, state.game_state, current_time_seconds)

    # Print status to console (for terminal display)
    IO.puts("\n#{status_text}")

    # Add message to history
    new_messages = [status_text | Enum.take(state.display_messages, 10)]

    new_state = %{state |
      current_time: current_time_seconds,
      display_messages: new_messages,
      svg_map_data: updated_svg
    }

    # Schedule next update (60 FPS = ~16.67ms)
    Process.send_after(self(), :update_display, 17)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:user_input, :spacebar}, state) do
    IO.puts("\n🚫 GAME PAUSED - Press SPACE again to resume")
    # In a full implementation, this would pause/resume the game loop
    {:noreply, state}
  end

  @impl true
  def handle_cast({:user_input, :q}, state) do
    IO.puts("\n👋 Quitting TimeStrike...")
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:user_input, :c}, state) do
    IO.puts("\n🎯 CONVICTION CHANGE - Replanning...")
    # In a full implementation, this would trigger replanning
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_last_message, _from, state) do
    last_message = List.first(state.display_messages) || "No messages"
    {:reply, last_message, state}
  end

  @impl true
  def handle_call(:get_svg_map, _from, state) do
    {:reply, state.svg_map_data, state}
  end

  # Private helper functions

  defp generate_status_display(game_state, current_time) do
    time_str = format_time(current_time)

    # Get agent positions (with interpolated movement)
    alex_pos = get_interpolated_position(game_state, "Alex", current_time)
    maya_pos = get_interpolated_position(game_state, "Maya", current_time)
    jordan_pos = get_interpolated_position(game_state, "Jordan", current_time)

    # Generate status text matching the mockup
    """
    === TimeStrike - Temporal Planner Test ===
    Time: #{time_str} | Goal: rescue_hostage | Plan Status: Executing

    Current State:
    - Alex: #{format_position(alex_pos)} HP:120/120 [#{get_agent_status("Alex", current_time)}]
    - Maya: #{format_position(maya_pos)} HP:80/80 [#{get_agent_status("Maya", current_time)}]
    - Jordan: #{format_position(jordan_pos)} HP:95/95 [#{get_agent_status("Jordan", current_time)}]

    Enemies:
    - Soldier1: (15,4,0) HP:70/70
    - Soldier2: (15,5,0) HP:70/70 [Will take 45 damage from Scorch]
    - Archer1: (18,3,0) HP:50/50

    Scheduled Actions:
    #{generate_scheduled_actions(current_time)}

    [Press SPACE to pause | Q to quit | C to change conviction]
    """
  end

  defp get_interpolated_position(game_state, agent_name, current_time) do
    # Get current position from temporal state
    base_pos = TemporalState.get_agent_position(game_state, agent_name) || {2, 3, 0}

    # For MVP, simulate movement toward {8,3,0} for Alex
    if agent_name == "Alex" do
      target = {8, 3, 0}
      progress = min(current_time / 6.0, 1.0)  # 6 seconds to reach target
      interpolate_position_3d(base_pos, target, progress)
    else
      ensure_3d_position(base_pos)
    end
  end

  defp interpolate_position_3d({x1, y1}, {x2, y2, z2}, progress) do
    interpolate_position_3d({x1, y1, 0}, {x2, y2, z2}, progress)
  end

  defp interpolate_position_3d({x1, y1, z1}, {x2, y2, z2}, progress) do
    x = x1 + (x2 - x1) * progress
    y = y1 + (y2 - y1) * progress
    z = z1 + (z2 - z1) * progress
    {Float.round(x, 1), Float.round(y, 1), Float.round(z, 1)}
  end

  defp ensure_3d_position({x, y}), do: {x, y, 0}
  defp ensure_3d_position({x, y, z}), do: {x, y, z}

  defp get_agent_status("Alex", current_time) do
    cond do
      current_time < 6.1 -> "Moving to (8,4,0), ETA: #{format_time(6.1 - current_time)}"
      current_time < 7.1 -> "Ready"
      true -> "Moving to (10,4,0)"
    end
  end

  defp get_agent_status("Maya", current_time) do
    if current_time < 7.0 do
      "Casting Scorch at (15,5,0), ETA: #{format_time(7.0 - current_time)}"
    else
      "Ready"
    end
  end

  defp get_agent_status("Jordan", _current_time), do: "Ready"

  defp generate_scheduled_actions(current_time) do
    actions = [
      {6.1, "Alex reaches (8,4,0)"},
      {6.1, "Jordan uses \"Now!\" on Alex"},
      {7.0, "Maya's Scorch hits (15,5,0)"},
      {7.1, "Alex moves to (10,4,0)"}
    ]

    actions
    |> Enum.filter(fn {time, _} -> time > current_time end)
    |> Enum.take(4)
    |> Enum.map(fn {time, action} -> "#{format_time(time)} - #{action}" end)
    |> Enum.join("\n")
    |> case do
      "" -> "No pending actions"
      text -> text
    end
  end

  defp format_time(seconds) when is_float(seconds) do
    minutes = trunc(seconds / 60)
    secs = rem(trunc(seconds * 10), 600) / 10
    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{secs}", 4, "0")}s"
  end

  defp format_position({x, y, z}) do
    "(#{x},#{y},#{z})"
  end

  defp generate_initial_map(game_state) do
    """
    <svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">
      <!-- Grid background -->
      <defs>
        <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
          <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#333" stroke-width="1"/>
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill="url(#grid)" />

      <!-- Map boundaries -->
      <rect x="20" y="20" width="760" height="560" fill="none" stroke="#666" stroke-width="2"/>

      <!-- Initial agent positions will be updated dynamically -->
      #{generate_svg_agents(game_state, 0)}

      <!-- Enemy positions -->
      <circle cx="320" cy="100" r="8" fill="#ff4444" stroke="#fff" stroke-width="2"/>
      <text x="320" y="85" text-anchor="middle" fill="#fff" font-size="12">Soldier1</text>

      <circle cx="320" cy="120" r="8" fill="#ff4444" stroke="#fff" stroke-width="2"/>
      <text x="320" y="135" text-anchor="middle" fill="#fff" font-size="12">Soldier2</text>

      <circle cx="380" cy="80" r="6" fill="#ff6666" stroke="#fff" stroke-width="2"/>
      <text x="380" y="75" text-anchor="middle" fill="#fff" font-size="10">Archer1</text>

      <!-- Objective marker -->
      <rect x="370" y="110" width="16" height="16" fill="#44ff44" stroke="#fff" stroke-width="2"/>
      <text x="378" y="105" text-anchor="middle" fill="#fff" font-size="10">Hostage</text>
    </svg>
    """
  end

  defp update_svg_map(base_svg, game_state, current_time) do
    # Update agent positions in the SVG
    String.replace(base_svg, ~r/<!-- Initial agent positions will be updated dynamically -->.*?(?=<!-- Enemy positions -->)/s,
      "<!-- Agent positions -->\n      #{generate_svg_agents(game_state, current_time)}\n      ")
  end

  defp generate_svg_agents(game_state, current_time) do
    alex_pos = get_interpolated_position(game_state, "Alex", current_time)
    maya_pos = get_interpolated_position(game_state, "Maya", current_time)
    jordan_pos = get_interpolated_position(game_state, "Jordan", current_time)

    """
    <!-- Alex -->
    <circle cx="#{svg_x(alex_pos)}" cy="#{svg_y(alex_pos)}" r="10" fill="#4488ff" stroke="#fff" stroke-width="2"/>
    <text x="#{svg_x(alex_pos)}" y="#{svg_y(alex_pos) - 15}" text-anchor="middle" fill="#fff" font-size="12" font-weight="bold">Alex</text>

    <!-- Maya -->
    <circle cx="#{svg_x(maya_pos)}" cy="#{svg_y(maya_pos)}" r="8" fill="#ff8844" stroke="#fff" stroke-width="2"/>
    <text x="#{svg_x(maya_pos)}" y="#{svg_y(maya_pos) - 12}" text-anchor="middle" fill="#fff" font-size="11">Maya</text>

    <!-- Jordan -->
    <circle cx="#{svg_x(jordan_pos)}" cy="#{svg_y(jordan_pos)}" r="8" fill="#44ff88" stroke="#fff" stroke-width="2"/>
    <text x="#{svg_x(jordan_pos)}" y="#{svg_y(jordan_pos) - 12}" text-anchor="middle" fill="#fff" font-size="11">Jordan</text>
    """
  end

  # Convert game coordinates to SVG coordinates
  defp svg_x({x, _y, _z}), do: 20 + x * 20  # 20px grid, 20px offset
  defp svg_y({_x, y, _z}), do: 580 - y * 20  # Invert Y axis, 20px from bottom
end
