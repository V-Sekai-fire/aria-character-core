defmodule AriaInteractivity.Domain do
  @moduledoc "glTF 2.0 Interactivity Extension as Temporal Planning Domain"
  use AriaCore.ActionAttributes

  @type gltf_float :: float()
  @type gltf_float2 :: {float(), float()}
  @type gltf_float3 :: {float(), float(), float()}
  @type gltf_float4 :: {float(), float(), float(), float()}
  @type gltf_int :: integer()
  @type gltf_bool :: boolean()
  @type result :: {:ok, AriaState.t()} | {:error, atom()}

  # Math operations that exist in MathOperations module
  @spec add(AriaState.t(), [number()]) :: result()
  defdelegate add(state, args), to: AriaInteractivity.MathOperations

  @spec add_command(AriaState.t(), [number()]) :: result()
  defdelegate add_command(state, args), to: AriaInteractivity.MathOperations

  @spec subtract(AriaState.t(), [number()]) :: result()
  defdelegate subtract(state, args), to: AriaInteractivity.MathOperations

  @spec subtract_command(AriaState.t(), [number()]) :: result()
  defdelegate subtract_command(state, args), to: AriaInteractivity.MathOperations

  @spec multiply(AriaState.t(), [number()]) :: result()
  defdelegate multiply(state, args), to: AriaInteractivity.MathOperations

  @spec multiply_command(AriaState.t(), [number()]) :: result()
  defdelegate multiply_command(state, args), to: AriaInteractivity.MathOperations

  @spec divide(AriaState.t(), [number()]) :: result()
  defdelegate divide(state, args), to: AriaInteractivity.MathOperations

  @spec divide_command(AriaState.t(), [number()]) :: result()
  defdelegate divide_command(state, args), to: AriaInteractivity.MathOperations

  @spec equal(AriaState.t(), [number()]) :: result()
  defdelegate equal(state, args), to: AriaInteractivity.MathOperations

  @spec less_than(AriaState.t(), [number()]) :: result()
  defdelegate less_than(state, args), to: AriaInteractivity.MathOperations

  @spec greater_than(AriaState.t(), [number()]) :: result()
  defdelegate greater_than(state, args), to: AriaInteractivity.MathOperations

  @spec sine(AriaState.t(), [number()]) :: result()
  defdelegate sine(state, args), to: AriaInteractivity.MathOperations

  @spec cosine(AriaState.t(), [number()]) :: result()
  defdelegate cosine(state, args), to: AriaInteractivity.MathOperations

  @spec vector_add(AriaState.t(), [list()]) :: result()
  defdelegate vector_add(state, args), to: AriaInteractivity.MathOperations

  @spec vector_dot(AriaState.t(), [list()]) :: result()
  defdelegate vector_dot(state, args), to: AriaInteractivity.MathOperations

  @spec clamp(AriaState.t(), [number()]) :: result()
  defdelegate clamp(state, args), to: AriaInteractivity.MathOperations

  @spec lerp(AriaState.t(), [number()]) :: result()
  defdelegate lerp(state, args), to: AriaInteractivity.MathOperations

  # State operations that exist in StateOperations module
  @spec set_variable(AriaState.t(), {atom(), term()}) :: result()
  defdelegate set_variable(state, args), to: AriaInteractivity.StateOperations

  @spec get_variable(AriaState.t(), {atom()}) :: result()
  defdelegate get_variable(state, args), to: AriaInteractivity.StateOperations

  @spec increment_variable(AriaState.t(), {atom(), number()}) :: result()
  defdelegate increment_variable(state, args), to: AriaInteractivity.StateOperations

  @spec decrement_variable(AriaState.t(), {atom(), number()}) :: result()
  defdelegate decrement_variable(state, args), to: AriaInteractivity.StateOperations

  @spec variable_equals(AriaState.t(), {atom(), term()}) :: result()
  defdelegate variable_equals(state, args), to: AriaInteractivity.StateOperations

  @spec variable_greater_than(AriaState.t(), {atom(), number()}) :: result()
  defdelegate variable_greater_than(state, args), to: AriaInteractivity.StateOperations

  @spec variable_less_than(AriaState.t(), {atom(), number()}) :: result()
  defdelegate variable_less_than(state, args), to: AriaInteractivity.StateOperations

  @spec transition_to_state(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate transition_to_state(state, args), to: AriaInteractivity.StateOperations

  @spec set_flag(AriaState.t(), {atom(), boolean()}) :: result()
  defdelegate set_flag(state, args), to: AriaInteractivity.StateOperations

  @spec toggle_flag(AriaState.t(), {atom()}) :: result()
  defdelegate toggle_flag(state, args), to: AriaInteractivity.StateOperations

  @spec validate_state(AriaState.t(), {atom()}) :: result()
  defdelegate validate_state(state, args), to: AriaInteractivity.StateOperations

  @spec check_invariants(AriaState.t(), {atom()}) :: result()
  defdelegate check_invariants(state, args), to: AriaInteractivity.StateOperations

  @spec record_state_change(AriaState.t(), {atom(), term(), term()}) :: result()
  defdelegate record_state_change(state, args), to: AriaInteractivity.StateOperations

  @spec undo_state_change(AriaState.t(), {atom()}) :: result()
  defdelegate undo_state_change(state, args), to: AriaInteractivity.StateOperations

  @spec save_state(AriaState.t(), {atom()}) :: result()
  defdelegate save_state(state, args), to: AriaInteractivity.StateOperations

  @spec load_state(AriaState.t(), {atom()}) :: result()
  defdelegate load_state(state, args), to: AriaInteractivity.StateOperations

  @spec reset_state(AriaState.t(), {atom()}) :: result()
  defdelegate reset_state(state, args), to: AriaInteractivity.StateOperations

  # Animation operations that exist in AnimationControl module
  @spec play_animation(AriaState.t(), {integer(), boolean()}) :: result()
  defdelegate play_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec stop_animation(AriaState.t(), {integer(), boolean()}) :: result()
  defdelegate stop_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec pause_animation(AriaState.t(), {integer(), boolean()}) :: result()
  defdelegate pause_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec resume_animation(AriaState.t(), {integer(), boolean()}) :: result()
  defdelegate resume_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec seek_animation(AriaState.t(), {integer(), float()}) :: result()
  defdelegate seek_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec set_animation_speed(AriaState.t(), {integer(), float()}) :: result()
  defdelegate set_animation_speed(state, args), to: AriaInteractivity.AnimationControl

  @spec set_animation_loop(AriaState.t(), {integer(), boolean()}) :: result()
  defdelegate set_animation_loop(state, args), to: AriaInteractivity.AnimationControl

  @spec is_animation_playing(AriaState.t(), {integer()}) :: result()
  defdelegate is_animation_playing(state, args), to: AriaInteractivity.AnimationControl

  @spec is_animation_completed(AriaState.t(), {integer()}) :: result()
  defdelegate is_animation_completed(state, args), to: AriaInteractivity.AnimationControl

  @spec get_animation_time(AriaState.t(), {integer()}) :: result()
  defdelegate get_animation_time(state, args), to: AriaInteractivity.AnimationControl

  @spec crossfade_animations(AriaState.t(), {integer(), integer(), float()}) :: result()
  defdelegate crossfade_animations(state, args), to: AriaInteractivity.AnimationControl

  @spec blend_animations(AriaState.t(), {integer(), integer(), float()}) :: result()
  defdelegate blend_animations(state, args), to: AriaInteractivity.AnimationControl

  @spec play_animation_sequence(AriaState.t(), {[integer()], float()}) :: result()
  defdelegate play_animation_sequence(state, args), to: AriaInteractivity.AnimationControl

  @spec queue_animation(AriaState.t(), {integer(), integer()}) :: result()
  defdelegate queue_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec trigger_animation_event(AriaState.t(), {integer(), atom(), term()}) :: result()
  defdelegate trigger_animation_event(state, args), to: AriaInteractivity.AnimationControl

  @spec wait_for_animation_event(AriaState.t(), {integer(), atom()}) :: result()
  defdelegate wait_for_animation_event(state, args), to: AriaInteractivity.AnimationControl

  @spec create_temporal_animation(AriaState.t(), [term()]) :: result()
  defdelegate create_temporal_animation(state, args), to: AriaInteractivity.AnimationControl

  @spec synchronize_animations(AriaState.t(), {[integer()], float()}) :: result()
  defdelegate synchronize_animations(state, args), to: AriaInteractivity.AnimationControl

  @spec set_animation_phase_offset(AriaState.t(), {integer(), float()}) :: result()
  defdelegate set_animation_phase_offset(state, args), to: AriaInteractivity.AnimationControl

  # Event operations that exist in EventHandling module
  @spec trigger_event(AriaState.t(), {atom(), term()}) :: result()
  defdelegate trigger_event(state, args), to: AriaInteractivity.EventHandling

  @spec trigger_custom_event(AriaState.t(), {String.t(), term()}) :: result()
  defdelegate trigger_custom_event(state, args), to: AriaInteractivity.EventHandling

  @spec broadcast_event(AriaState.t(), {atom(), term()}) :: result()
  defdelegate broadcast_event(state, args), to: AriaInteractivity.EventHandling

  @spec receive_event(AriaState.t(), {atom()}) :: result()
  defdelegate receive_event(state, args), to: AriaInteractivity.EventHandling

  @spec wait_for_custom_event(AriaState.t(), {String.t()}) :: result()
  defdelegate wait_for_custom_event(state, args), to: AriaInteractivity.EventHandling

  @spec setup_event_listener(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate setup_event_listener(state, args), to: AriaInteractivity.EventHandling

  @spec filter_events(AriaState.t(), {atom(), term()}) :: result()
  defdelegate filter_events(state, args), to: AriaInteractivity.EventHandling

  @spec debounce_event(AriaState.t(), {atom(), float()}) :: result()
  defdelegate debounce_event(state, args), to: AriaInteractivity.EventHandling

  @spec throttle_event(AriaState.t(), {atom(), float()}) :: result()
  defdelegate throttle_event(state, args), to: AriaInteractivity.EventHandling

  @spec event_sequence(AriaState.t(), {[atom()], float()}) :: result()
  defdelegate event_sequence(state, args), to: AriaInteractivity.EventHandling

  @spec event_race(AriaState.t(), {[atom()], float()}) :: result()
  defdelegate event_race(state, args), to: AriaInteractivity.EventHandling

  @spec wait_for_all_events(AriaState.t(), {[atom()], float()}) :: result()
  defdelegate wait_for_all_events(state, args), to: AriaInteractivity.EventHandling

  @spec extract_event_data(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate extract_event_data(state, args), to: AriaInteractivity.EventHandling

  @spec transform_event_data(AriaState.t(), {atom(), atom(), term()}) :: result()
  defdelegate transform_event_data(state, args), to: AriaInteractivity.EventHandling

  @spec validate_event_data(AriaState.t(), {atom(), term()}) :: result()
  defdelegate validate_event_data(state, args), to: AriaInteractivity.EventHandling

  @spec schedule_event(AriaState.t(), {atom(), term(), float()}) :: result()
  defdelegate schedule_event(state, args), to: AriaInteractivity.EventHandling

  @spec cancel_scheduled_event(AriaState.t(), {atom()}) :: result()
  defdelegate cancel_scheduled_event(state, args), to: AriaInteractivity.EventHandling

  @spec start_periodic_event(AriaState.t(), {atom(), term(), float()}) :: result()
  defdelegate start_periodic_event(state, args), to: AriaInteractivity.EventHandling

  @spec stop_periodic_event(AriaState.t(), {atom()}) :: result()
  defdelegate stop_periodic_event(state, args), to: AriaInteractivity.EventHandling

  @spec log_event(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate log_event(state, args), to: AriaInteractivity.EventHandling

  @spec monitor_event_frequency(AriaState.t(), {atom(), float()}) :: result()
  defdelegate monitor_event_frequency(state, args), to: AriaInteractivity.EventHandling

  @spec get_event_statistics(AriaState.t(), {atom()}) :: result()
  defdelegate get_event_statistics(state, args), to: AriaInteractivity.EventHandling

  @spec set_event_error_handler(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate set_event_error_handler(state, args), to: AriaInteractivity.EventHandling

  @spec retry_failed_event(AriaState.t(), {atom(), integer()}) :: result()
  defdelegate retry_failed_event(state, args), to: AriaInteractivity.EventHandling

  @spec handle_event_timeout(AriaState.t(), {atom(), float(), atom()}) :: result()
  defdelegate handle_event_timeout(state, args), to: AriaInteractivity.EventHandling

  # Flow control operations that exist in FlowControl module
  @spec sequence(AriaState.t(), [term()]) :: result()
  defdelegate sequence(state, args), to: AriaInteractivity.FlowControl

  @spec branch(AriaState.t(), [term()]) :: result()
  defdelegate branch(state, args), to: AriaInteractivity.FlowControl

  @spec switch(AriaState.t(), [term()]) :: result()
  defdelegate switch(state, args), to: AriaInteractivity.FlowControl

  @spec while_loop(AriaState.t(), [term()]) :: result()
  defdelegate while_loop(state, args), to: AriaInteractivity.FlowControl

  @spec for_loop(AriaState.t(), [term()]) :: result()
  defdelegate for_loop(state, args), to: AriaInteractivity.FlowControl

  @spec repeat_n(AriaState.t(), [term()]) :: result()
  defdelegate repeat_n(state, args), to: AriaInteractivity.FlowControl

  @spec wait_all(AriaState.t(), [term()]) :: result()
  defdelegate wait_all(state, args), to: AriaInteractivity.FlowControl

  @spec wait_any(AriaState.t(), [term()]) :: result()
  defdelegate wait_any(state, args), to: AriaInteractivity.FlowControl

  @spec delay(AriaState.t(), [term()]) :: result()
  defdelegate delay(state, args), to: AriaInteractivity.FlowControl

  @spec timeout(AriaState.t(), [term()]) :: result()
  defdelegate timeout(state, args), to: AriaInteractivity.FlowControl

  @spec parallel(AriaState.t(), [term()]) :: result()
  defdelegate parallel(state, args), to: AriaInteractivity.FlowControl

  @spec execute_if(AriaState.t(), [term()]) :: result()
  defdelegate execute_if(state, args), to: AriaInteractivity.FlowControl

  @spec execute_unless(AriaState.t(), [term()]) :: result()
  defdelegate execute_unless(state, args), to: AriaInteractivity.FlowControl

  # Temporal operations that exist in TemporalIntegration module
  @spec set_temporal_constraint(AriaState.t(), {atom(), atom(), float()}) :: result()
  defdelegate set_temporal_constraint(state, args), to: AriaInteractivity.TemporalIntegration

  @spec remove_temporal_constraint(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate remove_temporal_constraint(state, args), to: AriaInteractivity.TemporalIntegration

  @spec validate_temporal_constraints(AriaState.t(), {atom()}) :: result()
  defdelegate validate_temporal_constraints(state, args), to: AriaInteractivity.TemporalIntegration

  @spec set_action_duration(AriaState.t(), {atom(), String.t()}) :: result()
  defdelegate set_action_duration(state, args), to: AriaInteractivity.TemporalIntegration

  @spec get_action_duration(AriaState.t(), {atom()}) :: result()
  defdelegate get_action_duration(state, args), to: AriaInteractivity.TemporalIntegration

  @spec calculate_total_duration(AriaState.t(), {[atom()]}) :: result()
  defdelegate calculate_total_duration(state, args), to: AriaInteractivity.TemporalIntegration

  @spec define_time_window(AriaState.t(), {atom(), String.t(), String.t()}) :: result()
  defdelegate define_time_window(state, args), to: AriaInteractivity.TemporalIntegration

  @spec check_time_window(AriaState.t(), {atom(), String.t()}) :: result()
  defdelegate check_time_window(state, args), to: AriaInteractivity.TemporalIntegration

  @spec extend_time_window(AriaState.t(), {atom(), String.t()}) :: result()
  defdelegate extend_time_window(state, args), to: AriaInteractivity.TemporalIntegration

  @spec synchronize_actions(AriaState.t(), {[atom()], String.t()}) :: result()
  defdelegate synchronize_actions(state, args), to: AriaInteractivity.TemporalIntegration

  @spec sequence_actions_temporally(AriaState.t(), {[atom()], [float()]}) :: result()
  defdelegate sequence_actions_temporally(state, args), to: AriaInteractivity.TemporalIntegration

  @spec start_parallel_actions(AriaState.t(), {[atom()], String.t()}) :: result()
  defdelegate start_parallel_actions(state, args), to: AriaInteractivity.TemporalIntegration

  @spec monitor_action_timing(AriaState.t(), {atom()}) :: result()
  defdelegate monitor_action_timing(state, args), to: AriaInteractivity.TemporalIntegration

  @spec get_timing_statistics(AriaState.t(), {atom()}) :: result()
  defdelegate get_timing_statistics(state, args), to: AriaInteractivity.TemporalIntegration

  @spec check_timing_violations(AriaState.t(), {atom()}) :: result()
  defdelegate check_timing_violations(state, args), to: AriaInteractivity.TemporalIntegration

  @spec schedule_action_at_time(AriaState.t(), {atom(), String.t(), [term()]}) :: result()
  defdelegate schedule_action_at_time(state, args), to: AriaInteractivity.TemporalIntegration

  @spec cancel_scheduled_action(AriaState.t(), {atom()}) :: result()
  defdelegate cancel_scheduled_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec reschedule_action(AriaState.t(), {atom(), String.t()}) :: result()
  defdelegate reschedule_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec instant_action(AriaState.t(), [term()]) :: result()
  defdelegate instant_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec floating_duration_action(AriaState.t(), [term()]) :: result()
  defdelegate floating_duration_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec deadline_action(AriaState.t(), [term()]) :: result()
  defdelegate deadline_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec scheduled_start_action(AriaState.t(), [term()]) :: result()
  defdelegate scheduled_start_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec fixed_interval_action(AriaState.t(), [term()]) :: result()
  defdelegate fixed_interval_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec validation_action(AriaState.t(), [term()]) :: result()
  defdelegate validation_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec get_current_time(AriaState.t(), {atom()}) :: result()
  defdelegate get_current_time(state, args), to: AriaInteractivity.TemporalIntegration

  @spec check_time_elapsed(AriaState.t(), {String.t(), String.t()}) :: result()
  defdelegate check_time_elapsed(state, args), to: AriaInteractivity.TemporalIntegration

  @spec calculate_time_difference(AriaState.t(), {String.t(), String.t()}) :: result()
  defdelegate calculate_time_difference(state, args), to: AriaInteractivity.TemporalIntegration

  @spec handle_temporal_violation(AriaState.t(), {atom(), atom()}) :: result()
  defdelegate handle_temporal_violation(state, args), to: AriaInteractivity.TemporalIntegration

  @spec retry_temporal_action(AriaState.t(), {atom(), integer()}) :: result()
  defdelegate retry_temporal_action(state, args), to: AriaInteractivity.TemporalIntegration

  @spec handle_temporal_timeout(AriaState.t(), {atom(), float(), atom()}) :: result()
  defdelegate handle_temporal_timeout(state, args), to: AriaInteractivity.TemporalIntegration

  @spec create_domain() :: AriaHybridPlanner.domain()
  def create_domain do
    AriaHybridPlanner.new_domain(:gltf_interactivity)
    |> register_modules()
  end

  defp register_modules(domain) do
    # Register all available actions with the planner domain
    domain
    |> AriaHybridPlanner.add_action_to_domain(:add, &add/2)
    |> AriaHybridPlanner.add_action_to_domain(:greater_than, &greater_than/2)
    |> AriaHybridPlanner.add_action_to_domain(:set_variable, &set_variable/2)
    |> AriaHybridPlanner.add_action_to_domain(:get_variable, &get_variable/2)
    |> AriaHybridPlanner.add_action_to_domain(:increment_variable, &increment_variable/2)
    |> AriaHybridPlanner.add_action_to_domain(:variable_equals, &variable_equals/2)
    |> AriaHybridPlanner.add_action_to_domain(:variable_greater_than, &variable_greater_than/2)
    |> AriaHybridPlanner.add_action_to_domain(:variable_less_than, &variable_less_than/2)
    |> AriaHybridPlanner.add_action_to_domain(:set_flag, &set_flag/2)
    |> AriaHybridPlanner.add_action_to_domain(:play_animation, &play_animation/2)
    |> AriaHybridPlanner.add_action_to_domain(:stop_animation, &stop_animation/2)
    |> AriaHybridPlanner.add_action_to_domain(:trigger_event, &trigger_event/2)
    |> AriaHybridPlanner.add_action_to_domain(:wait_for_custom_event, &wait_for_custom_event/2)
    |> AriaHybridPlanner.add_action_to_domain(:delay, &delay/2)
    |> AriaHybridPlanner.add_action_to_domain(:sequence, &sequence/2)
    |> AriaHybridPlanner.add_action_to_domain(:execute_if, &execute_if/2)
    |> AriaHybridPlanner.add_action_to_domain(:parallel, &parallel/2)
  end
end
