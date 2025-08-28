# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Examples.GltfInteractivityDomain do
  @moduledoc """
  Simple glTF interactivity domain demonstrating basic behavior graph concepts.

  Based on the KHR_interactivity extension specification, this domain showcases:
  - Basic node transformations (move_node)
  - Animation control (start_animation)
  - Temporal control flow (wait_time)

  This minimal domain replaces the complex restaurant example with simple,
  relevant concepts for 3D interactive content development.

  ## Domain Overview

  Models a basic glTF scene with:
  - **Nodes**: 3D objects with position, rotation, scale
  - **Animations**: Predefined animation clips that can be started/stopped
  - **Timing**: Simple delay mechanisms for sequencing behaviors

  ## Example Usage

      # Create domain
      domain = AriaCore.UnifiedDomain.create_from_module(GltfInteractivityDomain)

      # Set up initial state
      state = AriaState.new()
      |> AriaState.set_fact("node_position", "cube_1", [0.0, 0.0, 0.0])
      |> AriaState.set_fact("animation_status", "rotate_anim", "stopped")

      # Define goals
      goals = [{"node_position", "cube_1", [5.0, 0.0, 0.0]}]

      # Plan and execute
      {:ok, plan} = AriaCore.plan(domain, state, goals)
  """

  use AriaCore.Domain
  use AriaCore.ActionAttributes

  # ============================================================================
  # SIMPLE DURATIVE ACTIONS (ADR-181 COMPLIANT)
  # ============================================================================

  # Move a glTF node to a new position over time
  @action duration: "PT2S",
          requires_entities: [
            %{type: "node", capabilities: [:transformable]}
          ]
  def move_node(state, [node_id, target_position, duration_seconds]) do
    state
    |> AriaState.set_fact("node_position", node_id, target_position)
    |> AriaState.set_fact("movement_duration", node_id, duration_seconds)
    |> AriaState.set_fact("movement_status", node_id, "moving")
  end

  # Start a glTF animation with specified speed
  @action duration: "PT1S",
          requires_entities: [
            %{type: "animation", capabilities: [:playable]}
          ]
  def start_animation(state, [animation_id, speed]) do
    state
    |> AriaState.set_fact("animation_status", animation_id, "playing")
    |> AriaState.set_fact("animation_speed", animation_id, speed)
    |> AriaState.set_fact("animation_start_time", animation_id, DateTime.utc_now())
  end

  # Simple delay action for timing control
  @action duration: "PT3S",
          requires_entities: []
  def wait_time(state, [duration_seconds]) do
    state
    |> AriaState.set_fact("wait_completed", "timer", true)
    |> AriaState.set_fact("wait_duration", "timer", duration_seconds)
  end

  # ============================================================================
  # UNIGOAL METHODS (SINGLE GOAL ACHIEVEMENT)
  # ============================================================================

  # Unigoal method for node position achievement
  @unigoal_method predicate: "node_position"
  def node_position_goal(_state, [subject, target_position]) do
    {:ok, [
      # Prerequisites
      {"node_exists", subject, true},
      {"node_transformable", subject, true},

      # Main movement action
      {:move_node, [subject, target_position, 2.0]},

      # Verification
      {"node_position", subject, target_position},
      {"movement_status", subject, "completed"}
    ]}
  end

  # Unigoal method for animation status achievement
  @unigoal_method predicate: "animation_status"
  def animation_status_goal(_state, [subject, value]) when value == "playing" do
    {:ok, [
      # Prerequisites
      {"animation_exists", subject, true},
      {"animation_loaded", subject, true},

      # Main animation action
      {:start_animation, [subject, 1.0]},

      # Verification
      {"animation_status", subject, "playing"}
    ]}
  end

  # ============================================================================
  # TASK METHODS (COMPLEX WORKFLOW DECOMPOSITION)
  # ============================================================================

  # Task method for sequenced movement and animation
  @task_method true
  def move_and_animate_method(_state, [node_id, animation_id]) do
    {:ok, [
      # First move the node
      {"node_position", node_id, [5.0, 0.0, 0.0]},

      # Wait a moment
      {:wait_time, [1.0]},

      # Then start animation
      {"animation_status", animation_id, "playing"}
    ]}
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @doc """
  Sets up a simple glTF scene state for testing.
  """
  def create_simple_test_state() do
    AriaState.new()
    |> AriaState.set_fact("node_exists", "cube_1", true)
    |> AriaState.set_fact("node_transformable", "cube_1", true)
    |> AriaState.set_fact("node_position", "cube_1", [0.0, 0.0, 0.0])
    |> AriaState.set_fact("animation_exists", "rotate_anim", true)
    |> AriaState.set_fact("animation_loaded", "rotate_anim", true)
    |> AriaState.set_fact("animation_status", "rotate_anim", "stopped")
  end

  @doc """
  Creates simple glTF scene goals for testing.
  """
  def create_simple_test_goals() do
    [
      {"node_position", "cube_1", [5.0, 0.0, 0.0]},
      {"animation_status", "rotate_anim", "playing"}
    ]
  end

  @doc """
  Demonstrates the complete workflow from domain creation to execution.
  """
  def demo_workflow() do
    # Create domain using unified system
    domain = AriaCore.UnifiedDomain.create_from_module(__MODULE__)

    # Set up state and goals
    initial_state = create_simple_test_state()
    goals = create_simple_test_goals()

    # This would integrate with existing planning system
    %{
      domain: domain,
      initial_state: initial_state,
      goals: goals,
      actions_available: AriaCore.Domain.list_actions(domain),
      methods_available: AriaCore.Domain.list_methods(domain)
    }
  end
end
