# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivityDomain do
  @moduledoc """
  Complete implementation of glTF KHR_interactivity specification nodes
  as Aria Engine actions and durative actions.
  
  This domain provides all 125 behavior graph nodes covering:
  - Mathematical operations (khr_math_* nodes)
  - Control flow (khr_flow_* nodes)  
  - Temporal operations (khr_flow_delay, khr_animation_* nodes)
  - State management (khr_variable_*, khr_pointer_* nodes)
  - Events (khr_event_* nodes)
  - Type conversion (khr_type_* nodes)
  - Debug utilities (khr_debug_* nodes)
  
  All actions are prefixed with 'khr_' to clearly identify them as belonging
  to the KHR_interactivity domain and prevent naming conflicts.
  
  Based on glTF KHR_interactivity Extension Specification
  """
  
  alias Domain
  alias NodeLibrary.KHRInteractivity.MathConstants
  alias NodeLibrary.KHRInteractivity.MathArithmetic
  alias NodeLibrary.KHRInteractivity.MathComparison
  alias NodeLibrary.KHRInteractivity.MathSpecial
  alias NodeLibrary.KHRInteractivity.MathTrigonometry
  alias NodeLibrary.KHRInteractivity.MathInteger
  alias NodeLibrary.KHRInteractivity.MathBoolean
  alias NodeLibrary.KHRInteractivity.MathBitwise
  alias NodeLibrary.KHRInteractivity.MathVector
  alias NodeLibrary.KHRInteractivity.MathMatrix
  alias NodeLibrary.KHRInteractivity.MathQuaternion
  alias NodeLibrary.KHRInteractivity.MathAdvanced
  alias NodeLibrary.KHRInteractivity.MathSwizzle
  alias NodeLibrary.KHRInteractivity.ControlFlow
  alias NodeLibrary.KHRInteractivity.FlowAdvanced
  alias NodeLibrary.KHRInteractivity.TypeConversion
  alias NodeLibrary.KHRInteractivity.VariableManagement
  alias NodeLibrary.KHRInteractivity.StateAdvanced
  alias NodeLibrary.KHRInteractivity.EventSystem
  alias NodeLibrary.KHRInteractivity.EventAdvanced
  alias NodeLibrary.KHRInteractivity.AnimationSystem
  
  @doc "Register all KHR_interactivity actions with a domain"
  @spec register_all_actions(Domain.t()) :: Domain.t()
  def register_all_actions(domain) do
    domain
    |> MathConstants.register_actions()
    |> MathArithmetic.register_actions()
    |> MathComparison.register_actions()
    |> MathSpecial.register_actions()
    |> MathTrigonometry.register_actions()
    |> register_math_integers()
    |> register_math_booleans()
    |> register_math_bitwise()
    |> register_math_vectors()
    |> register_math_matrices()
    |> register_math_quaternions()
    |> register_math_advanced()
    |> register_math_swizzle()
    |> register_type_conversion()
    |> register_control_flow()
    |> register_flow_advanced()
    |> register_temporal_flow()
    |> register_variable_management()
    |> register_state_advanced()
    |> register_event_system()
    |> register_event_advanced()
    |> register_animation_control()
    |> register_debug_utilities()
  end
  
  
  # =============================================================================
  # REGISTRATION FUNCTIONS
  # =============================================================================
  
  defp register_math_integers(domain) do
    domain
    |> MathInteger.register_instant_actions()
    |> MathInteger.register_task_methods()
  end
  
  defp register_math_booleans(domain) do
    domain
    |> MathBoolean.register_instant_actions()
    |> MathBoolean.register_task_methods()
  end
  
  defp register_math_bitwise(domain) do
    domain
    |> MathBitwise.register_instant_actions()
    |> MathBitwise.register_task_methods()
  end
  
  defp register_math_vectors(domain), do: MathVector.register_actions(domain)
  defp register_math_matrices(domain), do: MathMatrix.register_actions(domain)
  defp register_math_quaternions(domain), do: MathQuaternion.register_actions(domain)
  
  defp register_math_advanced(domain) do
    # Advanced math operations (vectors, matrices, quaternions)
    domain
    |> Domain.add_action(:khr_math_saturate, &MathAdvanced.saturate/2, %{})
    |> Domain.add_action(:khr_math_mix, &MathAdvanced.mix/2, %{})
    |> Domain.add_action(:khr_math_length, &MathAdvanced.length/2, %{})
    |> Domain.add_action(:khr_math_normalize, &MathAdvanced.normalize/2, %{})
    |> Domain.add_action(:khr_math_rotate_2d, &MathAdvanced.rotate_2d/2, %{})
    |> Domain.add_action(:khr_math_rotate_3d, &MathAdvanced.rotate_3d/2, %{})
    |> Domain.add_action(:khr_math_transpose, &MathAdvanced.transpose/2, %{})
    |> Domain.add_action(:khr_math_determinant, &MathAdvanced.determinant/2, %{})
    |> Domain.add_action(:khr_math_inverse, &MathAdvanced.inverse/2, %{})
    |> Domain.add_action(:khr_math_quat_conjugate, &MathAdvanced.quat_conjugate/2, %{})
    |> Domain.add_action(:khr_math_quat_angle_between, &MathAdvanced.quat_angle_between/2, %{})
    |> Domain.add_action(:khr_math_quat_from_axis_angle, &MathAdvanced.quat_from_axis_angle/2, %{})
    |> Domain.add_action(:khr_math_quat_to_axis_angle, &MathAdvanced.quat_to_axis_angle/2, %{})
    |> Domain.add_action(:khr_math_quat_from_directions, &MathAdvanced.quat_from_directions/2, %{})
    # Add task methods
    |> Domain.add_task_methods("math/saturate", [{"saturate", &MathAdvanced.saturate_task_method/2}])
    |> Domain.add_task_methods("math/mix", [{"mix", &MathAdvanced.mix_task_method/2}])
    |> Domain.add_task_methods("math/length", [{"length", &MathAdvanced.length_task_method/2}])
    |> Domain.add_task_methods("math/normalize", [{"normalize", &MathAdvanced.normalize_task_method/2}])
    |> Domain.add_task_methods("math/rotate2D", [{"rotate_2d", &MathAdvanced.rotate_2d_task_method/2}])
    |> Domain.add_task_methods("math/rotate3D", [{"rotate_3d", &MathAdvanced.rotate_3d_task_method/2}])
    |> Domain.add_task_methods("math/transpose", [{"transpose", &MathAdvanced.transpose_task_method/2}])
    |> Domain.add_task_methods("math/determinant", [{"determinant", &MathAdvanced.determinant_task_method/2}])
    |> Domain.add_task_methods("math/inverse", [{"inverse", &MathAdvanced.inverse_task_method/2}])
    |> Domain.add_task_methods("math/quatConjugate", [{"quat_conjugate", &MathAdvanced.quat_conjugate_task_method/2}])
    |> Domain.add_task_methods("math/quatAngleBetween", [{"quat_angle_between", &MathAdvanced.quat_angle_between_task_method/2}])
    |> Domain.add_task_methods("math/quatFromAxisAngle", [{"quat_from_axis_angle", &MathAdvanced.quat_from_axis_angle_task_method/2}])
    |> Domain.add_task_methods("math/quatToAxisAngle", [{"quat_to_axis_angle", &MathAdvanced.quat_to_axis_angle_task_method/2}])
    |> Domain.add_task_methods("math/quatFromDirections", [{"quat_from_directions", &MathAdvanced.quat_from_directions_task_method/2}])
  end
  
  defp register_math_swizzle(domain) do
    # Swizzle operations for vector/matrix combine/extract
    domain
    |> Domain.add_action(:khr_math_combine2, &MathSwizzle.combine2/2, %{})
    |> Domain.add_action(:khr_math_combine3, &MathSwizzle.combine3/2, %{})
    |> Domain.add_action(:khr_math_combine4, &MathSwizzle.combine4/2, %{})
    |> Domain.add_action(:khr_math_extract2, &MathSwizzle.extract2/2, %{})
    |> Domain.add_action(:khr_math_extract3, &MathSwizzle.extract3/2, %{})
    |> Domain.add_action(:khr_math_extract4, &MathSwizzle.extract4/2, %{})
    |> Domain.add_action(:khr_math_combine2x2, &MathSwizzle.combine2x2/2, %{})
    |> Domain.add_action(:khr_math_combine3x3, &MathSwizzle.combine3x3/2, %{})
    |> Domain.add_action(:khr_math_combine4x4, &MathSwizzle.combine4x4/2, %{})
    |> Domain.add_action(:khr_math_extract2x2, &MathSwizzle.extract2x2/2, %{})
    |> Domain.add_action(:khr_math_extract3x3, &MathSwizzle.extract3x3/2, %{})
    |> Domain.add_action(:khr_math_extract4x4, &MathSwizzle.extract4x4/2, %{})
    # Add task methods
    |> Domain.add_task_methods("math/combine2", [{"combine2", &MathSwizzle.combine2_task_method/2}])
    |> Domain.add_task_methods("math/combine3", [{"combine3", &MathSwizzle.combine3_task_method/2}])
    |> Domain.add_task_methods("math/combine4", [{"combine4", &MathSwizzle.combine4_task_method/2}])
    |> Domain.add_task_methods("math/extract2", [{"extract2", &MathSwizzle.extract2_task_method/2}])
    |> Domain.add_task_methods("math/extract3", [{"extract3", &MathSwizzle.extract3_task_method/2}])
    |> Domain.add_task_methods("math/extract4", [{"extract4", &MathSwizzle.extract4_task_method/2}])
    |> Domain.add_task_methods("math/combine2x2", [{"combine2x2", &MathSwizzle.combine2x2_task_method/2}])
    |> Domain.add_task_methods("math/combine3x3", [{"combine3x3", &MathSwizzle.combine3x3_task_method/2}])
    |> Domain.add_task_methods("math/combine4x4", [{"combine4x4", &MathSwizzle.combine4x4_task_method/2}])
    |> Domain.add_task_methods("math/extract2x2", [{"extract2x2", &MathSwizzle.extract2x2_task_method/2}])
    |> Domain.add_task_methods("math/extract3x3", [{"extract3x3", &MathSwizzle.extract3x3_task_method/2}])
    |> Domain.add_task_methods("math/extract4x4", [{"extract4x4", &MathSwizzle.extract4x4_task_method/2}])
  end
  
  defp register_type_conversion(domain) do
    domain
    |> TypeConversion.register_instant_actions()
    |> TypeConversion.register_task_methods()
  end
  
  defp register_control_flow(domain), do: ControlFlow.register_all(domain)
  
  defp register_flow_advanced(domain) do
    # Advanced control flow operations
    domain
    |> Domain.add_action(:khr_flow_switch, &FlowAdvanced.switch/2, %{})
    |> Domain.add_action(:khr_math_switch, &FlowAdvanced.math_switch/2, %{})
    |> Domain.add_action(:khr_flow_while, &FlowAdvanced.while_loop/2, %{})
    |> Domain.add_action(:khr_flow_for, &FlowAdvanced.for_loop/2, %{})
    |> Domain.add_action(:khr_flow_do_n, &FlowAdvanced.do_n/2, %{})
    |> Domain.add_action(:khr_flow_multi_gate, &FlowAdvanced.multi_gate/2, %{})
    |> Domain.add_action(:khr_flow_wait_all, &FlowAdvanced.wait_all/2, %{})
    |> Domain.add_action(:khr_flow_throttle, &FlowAdvanced.throttle/2, %{})
    |> Domain.add_action(:khr_flow_set_delay, &FlowAdvanced.set_delay/2, %{})
    |> Domain.add_action(:khr_flow_cancel_delay, &FlowAdvanced.cancel_delay/2, %{})
    # Add task methods
    |> Domain.add_task_methods("flow/switch", [{"switch", &FlowAdvanced.switch_task_method/2}])
    |> Domain.add_task_methods("math/switch", [{"math_switch", &FlowAdvanced.math_switch_task_method/2}])
    |> Domain.add_task_methods("flow/while", [{"while_loop", &FlowAdvanced.while_loop_task_method/2}])
    |> Domain.add_task_methods("flow/for", [{"for_loop", &FlowAdvanced.for_loop_task_method/2}])
    |> Domain.add_task_methods("flow/doN", [{"do_n", &FlowAdvanced.do_n_task_method/2}])
    |> Domain.add_task_methods("flow/multiGate", [{"multi_gate", &FlowAdvanced.multi_gate_task_method/2}])
    |> Domain.add_task_methods("flow/waitAll", [{"wait_all", &FlowAdvanced.wait_all_task_method/2}])
    |> Domain.add_task_methods("flow/throttle", [{"throttle", &FlowAdvanced.throttle_task_method/2}])
    |> Domain.add_task_methods("flow/setDelay", [{"set_delay", &FlowAdvanced.set_delay_task_method/2}])
    |> Domain.add_task_methods("flow/cancelDelay", [{"cancel_delay", &FlowAdvanced.cancel_delay_task_method/2}])
  end
  
  defp register_temporal_flow(domain), do: domain
  
  defp register_variable_management(domain) do
    domain
    |> VariableManagement.register_instant_actions()
    |> VariableManagement.register_task_methods()
  end
  
  defp register_state_advanced(domain) do
    # Advanced state management operations
    domain
    |> Domain.add_action(:khr_variable_set_multiple, &StateAdvanced.set_multiple/2, %{})
    |> Domain.add_action(:khr_pointer_get, &StateAdvanced.pointer_get/2, %{})
    |> Domain.add_action(:khr_pointer_set, &StateAdvanced.pointer_set/2, %{})
    |> Domain.add_action(:khr_pointer_interpolate, &StateAdvanced.pointer_interpolate/2, %{})
    # Add task methods
    |> Domain.add_task_methods("variable/setMultiple", [{"set_multiple", &StateAdvanced.set_multiple_task_method/2}])
    |> Domain.add_task_methods("pointer/get", [{"pointer_get", &StateAdvanced.pointer_get_task_method/2}])
    |> Domain.add_task_methods("pointer/set", [{"pointer_set", &StateAdvanced.pointer_set_task_method/2}])
    |> Domain.add_task_methods("pointer/interpolate", [{"pointer_interpolate", &StateAdvanced.pointer_interpolate_task_method/2}])
  end
  
  defp register_event_system(domain), do: EventSystem.register_actions(domain)
  
  defp register_event_advanced(domain) do
    # Advanced event system operations
    domain
    |> Domain.add_action(:khr_event_on_start, &EventAdvanced.on_start/2, %{})
    |> Domain.add_action(:khr_event_on_tick, &EventAdvanced.on_tick/2, %{})
    |> Domain.add_action(:khr_debug_log, &EventAdvanced.debug_log/2, %{})
    |> Domain.add_action(:khr_event_clear, &EventAdvanced.clear_event/2, %{})
    |> Domain.add_action(:khr_event_is_triggered, &EventAdvanced.is_triggered/2, %{})
    |> Domain.add_action(:khr_event_initialize_system, &EventAdvanced.initialize_event_system/2, %{})
    |> Domain.add_action(:khr_event_trigger_graph_start, &EventAdvanced.trigger_graph_start/2, %{})
    |> Domain.add_action(:khr_event_process_frame_tick, &EventAdvanced.process_frame_tick/2, %{})
    # Add task methods
    |> Domain.add_task_methods("event/onStart", [{"on_start", &EventAdvanced.on_start_task_method/2}])
    |> Domain.add_task_methods("event/onTick", [{"on_tick", &EventAdvanced.on_tick_task_method/2}])
    |> Domain.add_task_methods("debug/log", [{"debug_log", &EventAdvanced.debug_log_task_method/2}])
  end
  
  defp register_animation_control(domain) do
    # Animation system operations
    domain
    |> Domain.add_action(:khr_animation_start, &AnimationSystem.start/2, %{})
    |> Domain.add_action(:khr_animation_stop, &AnimationSystem.stop/2, %{})
    |> Domain.add_action(:khr_animation_stop_at, &AnimationSystem.stop_at/2, %{})
    |> Domain.add_action(:khr_animation_get_time, &AnimationSystem.get_time/2, %{})
    |> Domain.add_action(:khr_animation_is_playing, &AnimationSystem.is_playing/2, %{})
    |> Domain.add_action(:khr_animation_pause, &AnimationSystem.pause/2, %{})
    |> Domain.add_action(:khr_animation_resume, &AnimationSystem.resume/2, %{})
    # Add task methods
    |> Domain.add_task_methods("animation/start", [{"start", &AnimationSystem.start_task_method/2}])
    |> Domain.add_task_methods("animation/stop", [{"stop", &AnimationSystem.stop_task_method/2}])
    |> Domain.add_task_methods("animation/stopAt", [{"stop_at", &AnimationSystem.stop_at_task_method/2}])
  end
  
  defp register_debug_utilities(domain), do: domain
  
  # =============================================================================
  # DIRECT FUNCTION IMPLEMENTATIONS (for test compatibility)
  # =============================================================================
  
  # Math Constants
  def math_e(state, [output_id]) do
    MathConstants.e(state, [output_id])
  end
  
  def math_pi(state, [output_id]) do
    MathConstants.pi(state, [output_id])
  end
  
  def math_inf(state, [output_id]) do
    MathConstants.inf(state, [output_id])
  end
  
  def math_nan(state, [output_id]) do
    MathConstants.nan(state, [output_id])
  end
  
  # Math Arithmetic - Unary
  def math_abs(state, [output_id, input]) do
    MathArithmetic.abs(state, [output_id, input])
  end
  
  def math_sign(state, [output_id, input]) do
    MathArithmetic.sign(state, [output_id, input])
  end
  
  def math_neg(state, [output_id, input]) do
    MathArithmetic.neg(state, [output_id, input])
  end
  
  def math_floor(state, [output_id, input]) do
    MathArithmetic.floor(state, [output_id, input])
  end
  
  def math_ceil(state, [output_id, input]) do
    MathArithmetic.ceil(state, [output_id, input])
  end
  
  def math_round(state, [output_id, input]) do
    MathArithmetic.round(state, [output_id, input])
  end
  
  def math_trunc(state, [output_id, input]) do
    MathArithmetic.trunc(state, [output_id, input])
  end
  
  def math_fract(state, [output_id, input]) do
    MathArithmetic.fract(state, [output_id, input])
  end
  
  def math_saturate(state, [output_id, input]) do
    MathArithmetic.saturate(state, [output_id, input])
  end
  
  # Math Arithmetic - Binary
  def math_add(state, [output_id, a, b]) do
    MathArithmetic.add(state, [output_id, a, b])
  end
  
  def math_sub(state, [output_id, a, b]) do
    MathArithmetic.sub(state, [output_id, a, b])
  end
  
  def math_mul(state, [output_id, a, b]) do
    MathArithmetic.mul(state, [output_id, a, b])
  end
  
  def math_div(state, [output_id, a, b]) do
    MathArithmetic.div(state, [output_id, a, b])
  end
  
  def math_rem(state, [output_id, a, b]) do
    MathArithmetic.rem(state, [output_id, a, b])
  end
  
  def math_min(state, [output_id, a, b]) do
    MathArithmetic.min(state, [output_id, a, b])
  end
  
  def math_max(state, [output_id, a, b]) do
    MathArithmetic.max(state, [output_id, a, b])
  end
  
  def math_mix(state, [output_id, a, b, t]) do
    MathArithmetic.mix(state, [output_id, a, b, t])
  end
  
  # Math Arithmetic - Ternary
  def math_clamp(state, [output_id, value, min_val, max_val]) do
    MathArithmetic.clamp(state, [output_id, value, min_val, max_val])
  end
end
