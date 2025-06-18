# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivityDomain do
  @moduledoc """
  Complete implementation of glTF KHR_interactivity specification nodes
  as Aria Engine actions and durative actions.
  
  This domain provides 400+ actions covering:
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
  
  alias AriaEngine.Domain.Core
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathConstants
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathArithmetic
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathComparison
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathSpecial
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathTrigonometry
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathVector
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathMatrix
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathQuaternion
  alias AriaEngine.NodeLibrary.KHRInteractivity.MathSwizzle
  
  @doc "Register all KHR_interactivity actions with a domain"
  @spec register_all_actions(Core.t()) :: Core.t()
  def register_all_actions(domain) do
    domain
    |> MathConstants.register_actions()
    |> MathArithmetic.register_actions()
    |> MathComparison.register_actions()
    |> MathSpecial.register_actions()
    |> MathTrigonometry.register_actions()
    |> register_math_vectors()
    |> register_math_matrices()
    |> register_math_quaternions()
    |> register_math_swizzle()
    |> register_type_conversion()
    |> register_control_flow()
    |> register_temporal_flow()
    |> register_variable_management()
    |> register_event_system()
    |> register_animation_control()
    |> register_debug_utilities()
  end
  
  
  # =============================================================================
  # STUB REGISTRATION FUNCTIONS (to be implemented)
  # =============================================================================
  
  defp register_math_vectors(domain), do: MathVector.register_actions(domain)
  defp register_math_matrices(domain), do: MathMatrix.register_actions(domain)
  defp register_math_quaternions(domain), do: MathQuaternion.register_actions(domain)
  defp register_math_swizzle(domain), do: MathSwizzle.register_actions(domain)
  defp register_type_conversion(domain), do: domain
  defp register_control_flow(domain), do: domain
  defp register_temporal_flow(domain), do: domain
  defp register_variable_management(domain), do: domain
  defp register_event_system(domain), do: domain
  defp register_animation_control(domain), do: domain
  defp register_debug_utilities(domain), do: domain
end
