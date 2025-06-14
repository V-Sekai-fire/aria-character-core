# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrikeWeb.GameLive do
  use AriaTimestrikeWeb, :live_view

  alias AriaEngine.TemporalState
  alias AriaTimestrike.GameEngine

  @impl true
  def mount(_params, _session, socket) do
    # Start the game
    {:ok, game_state} = GameEngine.start_game()

    # Subscribe to game updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AriaTimestrike.PubSub, "game_updates")
      # Start the game loop
      send(self(), :tick)
    end

    socket =
      socket
      |> assign(:game_state, game_state)
      |> assign(:game_time, 0.0)
      |> assign(:plan_status, "Ready")
      |> assign(:goal, "rescue_hostage")
      |> assign(:scheduled_actions, [])
      |> assign(:paused, false)

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    unless socket.assigns.paused do
      # Update game time
      new_time = socket.assigns.game_time + 0.1  # 100ms tick

      # Update agent positions and actions
      updated_socket =
        socket
        |> assign(:game_time, new_time)
        |> update_agent_positions()
        |> update_scheduled_actions()

      # Schedule next tick
      Process.send_after(self(), :tick, 100)

      {:noreply, updated_socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:push_event, event_name, event_data}, socket) do
    {:noreply, push_event(socket, event_name, event_data)}
  end

  @impl true
  def handle_event("toggle_pause", _params, socket) do
    paused = !socket.assigns.paused

    socket = assign(socket, :paused, paused)

    # Resume ticking if unpaused
    if not paused do
      send(self(), :tick)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("quit_game", _params, socket) do
    GameEngine.stop_game(socket.assigns.game_state)
    {:noreply, redirect(socket, to: "/")}
  end

  @impl true
  def handle_event("change_conviction", _params, socket) do
    # Trigger replanning
    {:ok, new_actions} = GameEngine.plan_to_goal(socket.assigns.game_state, "Alex", {8, 3})

    socket = assign(socket, :scheduled_actions, format_scheduled_actions(new_actions, socket.assigns.game_time))

    {:noreply, socket}
  end

  # Private helper functions

  defp update_agent_positions(socket) do
    game_state = socket.assigns.game_state
    current_time = socket.assigns.game_time

    # Simulate agent movements using Godot coordinate system
    # Godot: +X = right, +Y = up, +Z = forward (toward camera)
    alex_pos = get_interpolated_position_godot("Alex", current_time)
    maya_pos = {3, 0, 5}  # Maya stays put while casting (Y=0 ground level)
    jordan_pos = {4, 0, 6}  # Jordan ready (Y=0 ground level)

    # Check if Alex position changed to send Three.js update
    old_alex_pos = game_state.agents["Alex"].position
    if alex_pos != old_alex_pos do
      # Send position update to Three.js frontend
      {x, y, z} = alex_pos
      send(self(), {:push_event, "agent_moved", %{
        agent_id: "Alex",
        position: %{x: x, y: y, z: z},
        duration: 0.1  # Smooth animation duration
      }})
    end

    updated_agents = %{
      "Alex" => %{game_state.agents["Alex"] | position: alex_pos},
      "Maya" => %{game_state.agents["Maya"] | position: maya_pos},
      "Jordan" => %{game_state.agents["Jordan"] | position: jordan_pos}
    }

    updated_game_state = %{game_state | agents: Map.merge(game_state.agents, updated_agents)}

    assign(socket, :game_state, updated_game_state)
  end

  defp get_interpolated_position_godot("Alex", current_time) do
    # Alex moves from {2,0,3} to {8,0,3} over 1.5 seconds (Godot coordinates)
    # X=2 to X=8 (moving right), Y=0 (ground level), Z=3 (constant depth)
    start_pos = {2, 0, 3}
    end_pos = {8, 0, 3}
    duration = 1.5

    if current_time >= duration do
      end_pos
    else
      progress = current_time / duration
      {x1, y1, z1} = start_pos
      {x2, y2, z2} = end_pos

      x = x1 + (x2 - x1) * progress
      y = y1 + (y2 - y1) * progress
      z = z1 + (z2 - z1) * progress

      {Float.round(x, 1), Float.round(y, 1), Float.round(z, 1)}
    end
  end

  defp update_scheduled_actions(socket) do
    current_time = socket.assigns.game_time

    actions = [
      %{time: 1.1, description: "Alex reaches (8,4,0)"},
      %{time: 1.1, description: "Jordan uses \"Now!\" on Alex"},
      %{time: 2.0, description: "Maya's Scorch hits (15,5,0)"},
      %{time: 2.1, description: "Alex moves to (10,4,0)"}
    ]

    # Filter out past actions
    future_actions = Enum.filter(actions, fn action -> action.time > current_time end)

    assign(socket, :scheduled_actions, future_actions)
  end

  defp format_scheduled_actions(actions, current_time) do
    Enum.map(actions, fn action ->
      eta = current_time + (action.duration || 1.0) / 1000.0
      %{
        time: eta,
        description: "#{action.agent_id} #{action.type} at #{inspect(action.to)}"
      }
    end)
  end

  defp format_time(seconds) do
    minutes = trunc(seconds / 60)
    secs = seconds - minutes * 60
    :io_lib.format("~2..0w:~4.1f", [minutes, secs]) |> to_string()
  end

  defp get_agent_status("Alex", game_state, game_time) do
    pos = game_state.agents["Alex"].position
    if game_time < 1.5 do
      "[Moving to (8,4,0), ETA: #{format_time(1.5)}s]"
    else
      "[Ready]"
    end
  end

  defp get_agent_status("Maya", _game_state, game_time) do
    if game_time < 2.0 do
      "[Casting Scorch at (15,5,0), ETA: #{format_time(2.0)}s]"
    else
      "[Ready]"
    end
  end

  defp get_agent_status("Jordan", _game_state, _game_time) do
    "[Ready]"
  end

  # SVG Map Generation
  defp generate_svg_map(game_state) do
    agents = game_state.agents

    """
    <svg width="600" height="400" viewBox="0 0 25 15" style="border: 1px solid #333; background: #1a1a1a;">
      <!-- Grid lines -->
      #{for x <- 0..25 do
        "<line x1='#{x}' y1='0' x2='#{x}' y2='15' stroke='#333' stroke-width='0.1'/>"
      end |> Enum.join()}
      #{for y <- 0..15 do
        "<line x1='0' y1='#{y}' x2='25' y2='#{y}' stroke='#333' stroke-width='0.1'/>"
      end |> Enum.join()}

      <!-- Agents -->
      #{render_agent("Alex", agents["Alex"], "#4CAF50")}
      #{render_agent("Maya", agents["Maya"], "#FF9800")}
      #{render_agent("Jordan", agents["Jordan"], "#2196F3")}

      <!-- Enemies -->
      #{render_enemy("Soldier1", {15, 4, 0}, "#F44336")}
      #{render_enemy("Soldier2", {15, 5, 0}, "#F44336")}
      #{render_enemy("Archer1", {18, 3, 0}, "#E91E63")}

      <!-- Hostage -->
      <circle cx="20" cy="5" r="0.3" fill="#FFEB3B" stroke="#FBC02D" stroke-width="0.1"/>
      <text x="20" y="5.8" text-anchor="middle" font-size="0.8" fill="#FFEB3B">H</text>
    </svg>
    """
  end

  defp render_agent(name, agent, color) do
    {x, y, _z} = agent.position
    """
    <circle cx="#{x}" cy="#{y}" r="0.4" fill="#{color}" stroke="#fff" stroke-width="0.1"/>
    <text x="#{x}" y="#{y + 1}" text-anchor="middle" font-size="0.6" fill="#{color}">#{String.first(name)}</text>
    """
  end

  defp render_enemy(name, {x, y, _z}, color) do
    """
    <rect x="#{x - 0.3}" y="#{y - 0.3}" width="0.6" height="0.6" fill="#{color}" stroke="#fff" stroke-width="0.1"/>
    <text x="#{x}" y="#{y + 1}" text-anchor="middle" font-size="0.6" fill="#{color}">#{String.first(name)}</text>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="timestrike-container">
      <div class="header">
        <h1>TimeStrike Tactics</h1>
        <div class="status-line">
          Time: <%= format_time(@game_time) %>s | Mission: <%= String.replace(@goal, "_", " ") |> String.capitalize() %> | Status: <%= @plan_status %>
        </div>
      </div>

      <div class="main-display">
        <!-- Party Status Panel -->
        <div class="status-panel">
          <h3>Party Status</h3>
          <ul>
            <li class="agent-alex">Alex: <%= inspect(@game_state.agents["Alex"].position) %> HP:120/120 <%= get_agent_status("Alex", @game_state, @game_time) %></li>
            <li class="agent-maya">Maya: <%= inspect(@game_state.agents["Maya"].position) %> HP:80/80 <%= get_agent_status("Maya", @game_state, @game_time) %></li>
            <li class="agent-jordan">Jordan: <%= inspect(@game_state.agents["Jordan"].position) %> HP:95/95 <%= get_agent_status("Jordan", @game_state, @game_time) %></li>
          </ul>

          <h3>Enemy Forces</h3>
          <ul>
            <li class="enemy">Soldier1: (15,0,4) HP:70/70</li>
            <li class="enemy">Soldier2: (15,0,5) HP:70/70 [Will take 45 damage from Scorch]</li>
            <li class="enemy">Archer1: (18,0,3) HP:50/50</li>
          </ul>

          <h3>Battle Plan</h3>
          <ul>
            <%= for action <- @scheduled_actions do %>
              <li><%= format_time(action.time) %>s - <%= action.description %></li>
            <% end %>
          </ul>

          <div class="controls">
            <button phx-click="toggle_pause">
              <%= if @paused, do: "RESUME", else: "PAUSE" %> (SPACE)
            </button>
            <button phx-click="quit_game">
              RETREAT (Q)
            </button>
            <button phx-click="change_conviction">
              REPLAN (C)
            </button>
          </div>
        </div>

        <!-- Tactical Map Panel -->
        <div class="map-panel">
          <h3>Battlefield Map</h3>
          <div style="background: linear-gradient(135deg, #1a0f08 0%, #2c1810 100%); padding: 10px; border: 2px solid #8b6914; border-radius: 8px; position: relative;">
            <!-- Three.js container -->
            <div id="timestrike-3d-container" phx-hook="TimeStrike3D">
              <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #d4af37; z-index: 100; font-family: Georgia, serif; text-shadow: 2px 2px 4px rgba(0,0,0,0.7);">
                Loading Battlefield...
              </div>
            </div>

            <!-- Coordinate System Legend -->
            <div class="coordinate-legend">
              <div style="color: #ff6b6b;">+X (East)</div>
              <div style="color: #4ecdc4;">+Y (Up)</div>
              <div style="color: #45b7d1;">+Z (North)</div>
              <div style="color: #d4af37; margin-top: 5px;">Mouse: Orbit View</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Three.js 3D Map will be initialized via Phoenix Hooks -->
    </div>
    """
  end
end
