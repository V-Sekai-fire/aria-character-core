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
  Generates a new random goal for an agent to move to.
  This creates the looping behavior where agents continuously pick new destinations.
  """
  def generate_next_goal(game_state, agent_id) do
    # Define possible movement destinations
    possible_destinations = [
      {2, 0, 3},  # Starting position
      {8, 0, 3},  # Forward destination
      {5, 0, 7},  # Side destination
      {3, 0, 1},  # Back destination
      {7, 0, 5},  # Diagonal destination
      {1, 0, 6},  # Corner destination
    ]

    agent = game_state.agents[agent_id]
    current_pos = agent.position

    # Filter out current position to avoid standing still
    available_destinations = Enum.reject(possible_destinations, fn pos -> pos == current_pos end)

    # Pick a random destination
    if length(available_destinations) > 0 do
      destination = Enum.random(available_destinations)
      {:ok, destination}
    else
      # Fallback destination if somehow no options available
      {:ok, {5, 0, 5}}
    end
  end

  @doc """
  Handles completion of a movement action and automatically plans the next goal.
  This implements the continuous movement loop.
  """
  def handle_action_completion(game_state, agent_id, completed_action) do
    case completed_action.type do
      :move_to ->
        # Agent reached destination, now pick a new goal
        {:ok, next_goal} = generate_next_goal(game_state, agent_id)

        # Update agent position to the completed destination
        updated_game_state = put_in(game_state.agents[agent_id].position, completed_action.to)

        # Plan to the new goal
        {:ok, next_actions} = plan_to_goal(updated_game_state, agent_id, next_goal)

        # Schedule an intent job using Membrane for the next movement
        schedule_intent_job_membrane(updated_game_state, agent_id, next_goal, next_actions)

        {:ok, updated_game_state, next_actions}

      _ ->
        # For other action types, just update state without replanning
        {:ok, game_state, []}
    end
  end

  @doc """
  Schedules an intent job using Membrane pipeline for traveling to another place.
  This creates the continuous movement loop by automatically processing the next movement.
  """
  def schedule_intent_job_membrane(game_state, agent_id, destination, _planned_actions) do
    # Use the Membrane-based GameActionJob to process the intent
    case AriaEngine.GameActionJob.schedule_action(game_state, agent_id, {:travel_to_location, destination}) do
      {:ok, job} ->
        {:ok, job}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Replans after an interruption occurs.
  """
  def replan_after_interruption(game_state, agent_id, target_position) do
    # Get current position (which may have changed due to interruption)
    _current_position = TemporalState.get_agent_position(game_state, agent_id)

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
