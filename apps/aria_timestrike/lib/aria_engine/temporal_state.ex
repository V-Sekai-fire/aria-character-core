# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TemporalState do
  @moduledoc """
  Temporal state management for the Aria game engine.

  This module manages time-aware game state, including:
  - Agent positions and movement tracking
  - Mission status and progression
  - Temporal snapshots and state transitions
  """

  @doc """
  Gets the current position of an agent.
  """
  def get_agent_position(game_state, agent_id) do
    # First check if there's an updated position in the job system
    case Agent.get(:game_state_store, fn state -> Map.get(state, agent_id) end) do
      nil ->
        # Fall back to game state
        case game_state.agents[agent_id] do
          %{position: position} -> position
          nil -> nil
        end
      position ->
        position
    end
  rescue
    # If the agent doesn't exist yet, fall back to game state
    _ ->
      case game_state.agents[agent_id] do
        %{position: position} -> position
        nil -> nil
      end
  end

  @doc """
  Updates an agent's position in the game state.
  """
  def update_agent_position(game_state, agent_id, new_position) do
    case game_state.agents[agent_id] do
      nil ->
        {:error, :agent_not_found}
      agent ->
        updated_agent = %{agent | position: new_position}
        updated_agents = Map.put(game_state.agents, agent_id, updated_agent)
        updated_state = %{game_state | agents: updated_agents}
        {:ok, updated_state}
    end
  end

  @doc """
  Gets the current mission status.
  """
  def get_mission_status(game_state) do
    # First check if there's an updated status in the job system
    case Agent.get(:game_state_store, fn state -> Map.get(state, :mission_status) end) do
      nil ->
        # Fall back to game state
        Map.get(game_state, :mission_status, :active)
      status ->
        status
    end
  rescue
    # If the agent doesn't exist yet, fall back to game state
    _ ->
      Map.get(game_state, :mission_status, :active)
  end

  @doc """
  Updates the mission status.
  """
  def set_mission_status(game_state, status) when status in [:active, :complete, :failed] do
    %{game_state | mission_status: status}
  end

  @doc """
  Gets the game start time.
  """
  def get_start_time(game_state) do
    Map.get(game_state, :started_at)
  end

  @doc """
  Gets the current game time (milliseconds since start).
  """
  def get_game_time(game_state) do
    start_time = get_start_time(game_state)
    if start_time do
      System.monotonic_time(:millisecond) - start_time
    else
      0
    end
  end

  @doc """
  Creates a temporal snapshot of the current state.
  """
  def create_snapshot(game_state) do
    %{
      snapshot_id: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
      timestamp: System.monotonic_time(:millisecond),
      game_time: get_game_time(game_state),
      state: game_state
    }
  end

  @doc """
  Interpolates an agent's position at a specific time during movement.
  This is used for real-time position updates during movement.
  """
  def interpolate_position(from_pos, to_pos, start_time, duration, current_time) do
    if current_time <= start_time do
      from_pos
    else
      elapsed = current_time - start_time
      if elapsed >= duration do
        to_pos
      else
        progress = elapsed / duration
        interpolate_coordinates(from_pos, to_pos, progress)
      end
    end
  end

  # Private helper functions

  defp interpolate_coordinates({x1, y1}, {x2, y2}, progress) do
    x = x1 + (x2 - x1) * progress
    y = y1 + (y2 - y1) * progress
    {x, y}
  end
end
