defmodule AriaInteractivity.AnimationControl do
  @moduledoc """
  glTF Animation Control Domain

  Implements animation control operations from glTF Interactivity Extension as planning domain methods.
  Supports animation playback, timing, and temporal coordination.

  Based on glTF Specification.adoc animation nodes
  """

  use AriaCore.ActionAttributes

  # ============================================================================
  # ANIMATION PLAYBACK CONTROL
  # ============================================================================

  @unigoal_method predicate: "animation_playing"
  @spec play_animation(AriaState.t(), {integer(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def play_animation(state, {animation_id, true}) do
    {:ok, [
      {:temporal_action, create_temporal_animation(state, [animation_id, "PT2S", nil, nil, 1.0])}
    ]}
  end

  @unigoal_method predicate: "animation_stopped"
  @spec stop_animation(AriaState.t(), {integer(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def stop_animation(_state, {animation_id, true}) do
    {:ok, [
      {:action, {:stop_animation, [animation_id]}}
    ]}
  end

  @unigoal_method predicate: "animation_paused"
  @spec pause_animation(AriaState.t(), {integer(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def pause_animation(_state, {animation_id, true}) do
    {:ok, [
      {:action, {:pause_animation, [animation_id]}}
    ]}
  end

  @unigoal_method predicate: "animation_resumed"
  @spec resume_animation(AriaState.t(), {integer(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def resume_animation(_state, {animation_id, true}) do
    {:ok, [
      {:action, {:resume_animation, [animation_id]}}
    ]}
  end

  # ============================================================================
  # ANIMATION TIMING CONTROL
  # ============================================================================

  @unigoal_method predicate: "animation_seeked"
  @spec seek_animation(AriaState.t(), {integer(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def seek_animation(_state, {animation_id, time_position}) do
    {:ok, [
      {:action, {:seek_animation, [animation_id, time_position]}}
    ]}
  end

  @unigoal_method predicate: "animation_speed_set"
  @spec set_animation_speed(AriaState.t(), {integer(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_animation_speed(_state, {animation_id, speed}) do
    {:ok, [
      {:action, {:set_animation_speed, [animation_id, speed]}}
    ]}
  end

  @unigoal_method predicate: "animation_loop_set"
  @spec set_animation_loop(AriaState.t(), {integer(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_animation_loop(_state, {animation_id, loop}) do
    {:ok, [
      {:action, {:set_animation_loop, [animation_id, loop]}}
    ]}
  end

  # ============================================================================
  # ANIMATION STATE QUERIES
  # ============================================================================

  # Check if animation is playing
  @unigoal_method predicate: "animation_is_playing"
  @spec is_animation_playing(AriaState.t(), {integer()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def is_animation_playing(_state, {animation_id}) do
    {:ok, [
      {:goal, {:animation_is_playing, animation_id, true}}
    ]}
  end

  @unigoal_method predicate: "animation_completed"
  @spec is_animation_completed(AriaState.t(), {integer()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def is_animation_completed(_state, {animation_id}) do
    {:ok, [
      {:goal, {:animation_completed, animation_id, true}}
    ]}
  end

  @unigoal_method predicate: "animation_time"
  @spec get_animation_time(AriaState.t(), {integer()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def get_animation_time(_state, {animation_id}) do
    {:ok, [
      {:action, {:get_animation_time, [animation_id]}}
    ]}
  end

  # ============================================================================
  # ANIMATION BLENDING
  # ============================================================================

  # Crossfade between animations
  @unigoal_method predicate: "animations_crossfaded"
  @spec crossfade_animations(AriaState.t(), {integer(), integer(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def crossfade_animations(_state, {from_animation, to_animation, duration}) do
    {:ok, [
      {:temporal_action, {:crossfade_animations, [from_animation, to_animation, duration]}}
    ]}
  end

  # Blend animations
  @unigoal_method predicate: "animations_blended"
  @spec blend_animations(AriaState.t(), {integer(), integer(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def blend_animations(_state, {animation1, animation2, blend_weight}) do
    {:ok, [
      {:action, {:blend_animations, [animation1, animation2, blend_weight]}}
    ]}
  end

  # ============================================================================
  # ANIMATION SEQUENCES
  # ============================================================================

  # Play animation sequence
  @unigoal_method predicate: "animation_sequence_started"
  @spec play_animation_sequence(AriaState.t(), {[integer()], float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def play_animation_sequence(_state, {animation_ids, transition_time}) do
    {:ok, [
      {:temporal_action, {:play_animation_sequence, [animation_ids, transition_time]}}
    ]}
  end

  # Queue animation
  @unigoal_method predicate: "animation_queued"
  @spec queue_animation(AriaState.t(), {integer(), integer()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def queue_animation(_state, {current_animation, next_animation}) do
    {:ok, [
      {:action, {:queue_animation, [current_animation, next_animation]}}
    ]}
  end

  # ============================================================================
  # ANIMATION EVENTS
  # ============================================================================

  # Animation event trigger
  @unigoal_method predicate: "animation_event_triggered"
  @spec trigger_animation_event(AriaState.t(), {integer(), atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def trigger_animation_event(_state, {animation_id, event_name, event_data}) do
    {:ok, [
      {:action, {:trigger_animation_event, [animation_id, event_name, event_data]}}
    ]}
  end

  # Wait for animation event
  @unigoal_method predicate: "animation_event_received"
  @spec wait_for_animation_event(AriaState.t(), {integer(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def wait_for_animation_event(_state, {animation_id, event_name}) do
    {:ok, [
      {:goal, {:animation_event_received, animation_id, event_name}}
    ]}
  end

  # ============================================================================
  # TEMPORAL ANIMATION INTEGRATION
  # ============================================================================

  # Create temporal animation with manual lambda annotation
  @task_method true
  @spec create_temporal_animation(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def create_temporal_animation(_state, [animation_index, duration, start_time, end_time, speed]) do
    # Use task decomposition to create temporal workflow
    {:ok, [
      # Set up temporal constraints as goals
      {"animation_duration", animation_index, duration},
      {"animation_start_time", animation_index, start_time},
      {"animation_end_time", animation_index, end_time},

      # Execute the temporal animation action
      {:play_animation_temporal, [animation_index, speed]},

      # Verify completion
      {"animation_completed", animation_index, true}
    ]}
  end

  # Temporal animation action using proper @action attributes
  @action duration: "PT2S",
          requires_entities: [%{type: "animation_system", capabilities: [:playback]}]
  @spec play_animation_temporal(AriaState.t(), [term]) :: {:ok, AriaState.t()} | {:error, atom()}
  def play_animation_temporal(state, [animation_index, _speed]) do
    # Direct state transformation - planner handles temporal constraints
    {:ok, AriaState.set_fact(state, "animation_playing", animation_index, true)}
  end

  # ============================================================================
  # ANIMATION SYNCHRONIZATION
  # ============================================================================

  # Synchronize animations
  @unigoal_method predicate: "animations_synchronized"
  @spec synchronize_animations(AriaState.t(), {[integer()], float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def synchronize_animations(_state, {animation_ids, sync_time}) do
    {:ok, [
      {:temporal_action, {:synchronize_animations, [animation_ids, sync_time]}}
    ]}
  end

  # Animation phase offset
  @unigoal_method predicate: "animation_phase_offset"
  @spec set_animation_phase_offset(AriaState.t(), {integer(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_animation_phase_offset(_state, {animation_id, phase_offset}) do
    {:ok, [
      {:action, {:set_animation_phase_offset, [animation_id, phase_offset]}}
    ]}
  end
end
