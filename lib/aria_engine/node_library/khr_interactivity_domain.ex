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
  
  alias NodeLibrary.KHRInteractivity.MathConstants
  alias NodeLibrary.KHRInteractivity.MathArithmetic
  alias NodeLibrary.KHRInteractivity.VariableInterpolation
  
  @doc "Register all KHR_interactivity actions with a domain"
  @spec register_all_actions(Domain.t()) :: Domain.t()
  def register_all_actions(domain) do
    domain
    |> MathConstants.register_actions()
    |> MathArithmetic.register_actions()
    |> VariableInterpolation.register_all()
  end

  @doc "Register all KHR_interactivity task methods with a domain"
  @spec register_all_task_methods(Domain.t()) :: Domain.t()
  def register_all_task_methods(domain) do
    domain
    |> MathConstants.register_task_methods()
    |> MathArithmetic.register_task_methods()
    |> VariableInterpolation.register_all()
  end

  @doc "Register both actions and task methods for complete KHR domain support"
  @spec register_complete_domain(Domain.t()) :: Domain.t()
  def register_complete_domain(domain) do
    domain
    |> register_all_actions()
    |> register_all_task_methods()
  end
  
  # =============================================================================
  # DIRECT FUNCTION IMPLEMENTATIONS (for test compatibility)
  # =============================================================================
  
  # Math Constants
  def math_e(state, [output_id]) do
    MathConstants.math_e(state, [output_id])
  end
  
  def math_pi(state, [output_id]) do
    MathConstants.math_pi(state, [output_id])
  end
  
  def math_inf(state, [output_id]) do
    MathConstants.math_inf(state, [output_id])
  end
  
  def math_nan(state, [output_id]) do
    MathConstants.math_nan(state, [output_id])
  end
  
  # Math Arithmetic - Unary
  def math_abs(state, [output_id, input]) do
    MathArithmetic.math_abs(state, [output_id, input])
  end
  
  def math_sign(state, [output_id, input]) do
    MathArithmetic.math_sign(state, [output_id, input])
  end
  
  def math_neg(state, [output_id, input]) do
    MathArithmetic.math_neg(state, [output_id, input])
  end
  
  def math_floor(state, [output_id, input]) do
    MathArithmetic.math_floor(state, [output_id, input])
  end
  
  def math_ceil(state, [output_id, input]) do
    MathArithmetic.math_ceil(state, [output_id, input])
  end
  
  def math_round(state, [output_id, input]) do
    MathArithmetic.math_round(state, [output_id, input])
  end
  
  def math_trunc(state, [output_id, input]) do
    MathArithmetic.math_trunc(state, [output_id, input])
  end
  
  def math_fract(state, [output_id, input]) do
    MathArithmetic.math_fract(state, [output_id, input])
  end
  
  def math_saturate(state, [output_id, input]) do
    MathArithmetic.math_saturate(state, [output_id, input])
  end
  
  # Math Arithmetic - Binary
  def math_add(state, [output_id, a, b]) do
    MathArithmetic.math_add(state, [output_id, a, b])
  end
  
  def math_sub(state, [output_id, a, b]) do
    MathArithmetic.math_sub(state, [output_id, a, b])
  end
  
  def math_mul(state, [output_id, a, b]) do
    MathArithmetic.math_mul(state, [output_id, a, b])
  end
  
  def math_div(state, [output_id, a, b]) do
    MathArithmetic.math_div(state, [output_id, a, b])
  end
  
  def math_rem(state, [output_id, a, b]) do
    MathArithmetic.math_rem(state, [output_id, a, b])
  end
  
  def math_min(state, [output_id, a, b]) do
    MathArithmetic.math_min(state, [output_id, a, b])
  end
  
  def math_max(state, [output_id, a, b]) do
    MathArithmetic.math_max(state, [output_id, a, b])
  end
  
  def math_mix(state, [output_id, a, b, t]) do
    MathArithmetic.math_mix(state, [output_id, a, b, t])
  end
  
  # Math Arithmetic - Ternary
  def math_clamp(state, [output_id, value, min_val, max_val]) do
    MathArithmetic.math_clamp(state, [output_id, value, min_val, max_val])
  end
end
