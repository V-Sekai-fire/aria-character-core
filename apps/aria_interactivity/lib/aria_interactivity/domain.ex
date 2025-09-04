defmodule AriaInteractivity.Domain do
  @moduledoc "glTF 2.0 Interactivity Extension as Temporal Planning Domain"
  use AriaCore.ActionAttributes

  # glTF type aliases for specification compliance
  @type gltf_float :: float()
  @type gltf_float2 :: {float(), float()}
  @type gltf_float3 :: {float(), float(), float()}
  @type gltf_float4 :: {float(), float(), float(), float()}
  @type gltf_int :: integer()
  @type gltf_bool :: boolean()
  @type result :: {:ok, AriaState.t()} | {:error, atom()}

  # Delegate only to functions that actually exist in the modules

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

  # Additional domain-specific operations (non-glTF spec)
  for op <- ~w(set get increment decrement equals greater_than less_than transition_to_state set_flag toggle_flag validate_state check_invariants record_state_change undo_state_change save_state load_state reset_state) do
    @spec unquote(:"#{op}_variable")(AriaState.t(), any()) :: result()
    defdelegate unquote(:"#{op}_variable")(state, args), to: AriaInteractivity.StateOperations
  end

  # Animation control operations
  for op <- ~w(play stop pause resume seek set_speed set_loop is_playing is_completed get_time crossfade blend play_sequence queue trigger_animation_event wait_for_animation_event create_temporal play_temporal synchronize set_phase_offset) do
    @spec unquote(:"#{op}_animation")(AriaState.t(), any()) :: result()
    defdelegate unquote(:"#{op}_animation")(state, args), to: AriaInteractivity.AnimationControl
  end

  # Event handling operations
  for op <- ~w(trigger trigger_custom broadcast receive wait_for setup_listener filter debounce throttle sequence race wait_for_all extract transform validate schedule cancel_scheduled start_periodic stop_periodic log monitor_frequency get_statistics set_error_handler retry handle_timeout) do
    @spec unquote(:"#{op}_event")(AriaState.t(), any()) :: result()
    defdelegate unquote(:"#{op}_event")(state, args), to: AriaInteractivity.EventHandling
  end

  # Temporal integration operations
  for op <- ~w(set_constraint remove_constraint validate_constraints set_duration get_duration calculate_total define_window check_window extend_window synchronize sequence_temporally start_parallel monitor_timing get_statistics check_violations schedule_at_time cancel_scheduled reschedule instant floating deadline scheduled_start fixed_interval validation get_current check_elapsed calculate_difference handle_violation retry handle_timeout) do
    @spec unquote(:"#{op}_temporal")(AriaState.t(), any()) :: result()
    defdelegate unquote(:"#{op}_temporal")(state, args), to: AriaInteractivity.TemporalIntegration
  end

  @spec create_domain() :: AriaHybridPlanner.domain()
  def create_domain do
    AriaHybridPlanner.new_domain(:gltf_interactivity)
    |> register_modules()
  end

  defp register_modules(domain) do
    # All modules registered via @action/@command/@task_method/@unigoal_method attributes
    domain
  end
end
