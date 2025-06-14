# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.GameEngine do
  @moduledoc """
  Game engine for Timestrike - manages game state, planning, and execution.

  This module provides the core game loop and state management for the temporal
  planner system. It handles:
  - Game initialization and shutdown
  - Goal planning and replanning
  - Integration with the temporal state system
  """

  use GenServer

  alias AriaEngine.TemporalState
  alias AriaTimestrike.Planner

  @doc """
  Starts a new game session with initial state.
  """
  def start_game do
    initial_state = %{
      id: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
      agents: %{
        "Alex" => %{
          position: {2, 0, 3},  # Godot coordinates: Y=0 ground level
          speed: 4.0,
          status: :alive
        },
        "Maya" => %{
          position: {3, 0, 5},  # Godot coordinates: Y=0 ground level
          speed: 3.0,
          status: :alive
        },
        "Jordan" => %{
          position: {4, 0, 6},  # Godot coordinates: Y=0 ground level
          speed: 3.0,
          status: :alive
        }
      },
      mission_status: :active,
      started_at: System.monotonic_time(:millisecond)
    }

    {:ok, initial_state}
  end

  @doc """
  GenServer callback for initialization.
  """
  def init(init_arg) do
    {:ok, init_arg}
  end

  @doc """
  Plans a sequence of actions to reach a goal.
  """
  def plan_to_goal(game_state, agent_id, target_position) do
    agent = game_state.agents[agent_id]

    if agent do
      current_pos = agent.position

      # Simple plan: direct movement to target
      actions = [
        %{
          type: :move_to,
          agent_id: agent_id,
          from: current_pos,
          to: target_position,
          duration: calculate_movement_duration(current_pos, target_position, agent.speed)
        }
      ]

      {:ok, actions}
    else
      {:error, :agent_not_found}
    end
  end

  @doc """
  Replans after an interruption occurs.
  """
  def replan_after_interruption(game_state, agent_id, target_position) do
    # Get current position (which may have changed due to interruption)
    current_position = TemporalState.get_agent_position(game_state, agent_id)

    # Create new plan from current position to target
    plan_to_goal(game_state, agent_id, target_position)
  end

  @doc """
  Stops the game and cleans up resources.
  """
  def stop_game(_game_state) do
    # For now, just return :ok
    # In a full implementation, this would clean up processes, save state, etc.
    :ok
  end

  # Private helper functions

  defp calculate_movement_duration(from_pos, to_pos, speed) do
    distance = calculate_distance(from_pos, to_pos)
    trunc(distance / speed * 1000)  # Convert to milliseconds
  end

  defp calculate_distance({x1, y1, _z1}, {x2, y2, _z2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end
end
