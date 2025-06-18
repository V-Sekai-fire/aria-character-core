# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.VariableInterpolation do
  @moduledoc """
  KHR_interactivity Variable Interpolation Durative Actions

  Implements temporal variable interpolation from the glTF KHR_interactivity specification:
  - khr_variable_interpolate: Interpolate variable value over time (durative action)
  - khr_variable_animate: Animate variable between values with easing (durative action)

  These are durative actions that modify variables over time, essential for:
  - PERT chart task progress simulation
  - Animation and tweening systems
  - Temporal state transitions
  """

  alias StateV2
  alias Domain.{Actions, Methods, Core, DurativeAction}

  @doc "Register durative action operations"
  @spec register_durative_actions(Core.t()) :: Core.t()
  def register_durative_actions(domain) do
    # Variable interpolation durative action - interpolates from current to target value
    interpolate_durative = DurativeAction.new(
      :khr_variable_interpolate,
      {:fixed, 1.0}, # Default duration, can be overridden
      %{
        at_start: [],
        over_all: [],
        at_end: []
      },
      %{
        at_start: [],
        over_all: [],
        at_end: []
      },
      &variable_interpolate_durative_action/2
    )

    # Variable animation durative action - animates with easing functions
    animate_durative = DurativeAction.new(
      :khr_variable_animate,
      {:fixed, 2.0}, # Default duration, can be overridden
      %{
        at_start: [],
        over_all: [],
        at_end: []
      },
      %{
        at_start: [],
        over_all: [],
        at_end: []
      },
      &variable_animate_durative_action/2
    )

    domain
    |> Core.add_durative_action(:khr_variable_interpolate, interpolate_durative)
    |> Core.add_durative_action(:khr_variable_animate, animate_durative)
  end

  @doc "Register instant action operations"
  @spec register_instant_actions(Core.t()) :: Core.t()
  def register_instant_actions(domain) do
    domain
    |> Actions.add_action(:khr_variable_interpolate_instant, &variable_interpolate_instant/2, %{
      domain: "khr_interactivity",
      category: "variable_interpolation",
      khr_node_type: "variable/interpolate",
      description: "Instantly interpolate variable to target value"
    })
    |> Actions.add_action(:khr_variable_set_progress, &variable_set_progress/2, %{
      domain: "khr_interactivity",
      category: "variable_interpolation",
      khr_node_type: "variable/set_progress",
      description: "Set variable progress value (0.0 to 1.0)"
    })
    |> Actions.add_action(:khr_variable_set, &variable_set/2, %{
      domain: "khr_interactivity",
      category: "variable_interpolation",
      khr_node_type: "variable/set",
      description: "Set variable to specific value"
    })
  end

  @doc "Register task methods using exact KHR specification names"
  @spec register_task_methods(Core.t()) :: Core.t()
  def register_task_methods(domain) do
    domain
    |> Methods.add_task_methods("variable/interpolate", [
      {"durative_interpolate", &variable_interpolate_task_method/2},
      {"instant_interpolate", &variable_interpolate_instant_task_method/2}
    ])
    |> Methods.add_task_methods("variable/animate", [
      {"durative_animate", &variable_animate_task_method/2}
    ])
    |> Methods.add_task_methods("variable/set_progress", [
      {"basic_progress", &variable_set_progress_task_method/2}
    ])
    |> Methods.add_task_methods("khr_variable_set", [
      {"basic_set", &variable_set_task_method/2}
    ])
  end

  @doc "Register all variable interpolation operations"
  @spec register_all(Core.t()) :: Core.t()
  def register_all(domain) do
    domain
    |> register_instant_actions()
    |> register_task_methods()
    |> register_durative_actions()
  end

  # ==================== DURATIVE ACTIONS ====================

  @doc """
  Durative action function for variable interpolation.
  
  Interpolates a variable from its current value to a target value over the duration.
  This is the core action for PERT chart task progress simulation.
  """
  def variable_interpolate_durative_action(state, [node_index, variable_name, target_value, duration]) do
    # Get current value or default to 0
    current_value = StateV2.get_fact(state, variable_name, "value") || 0.0
    
    # For durative actions, we simulate the interpolation by setting intermediate values
    # In a real temporal system, this would be called at different time points
    progress_steps = max(1, trunc(duration * 10)) # 10 steps per time unit
    
    # Simulate progress over time by setting multiple progress values
    final_state = Enum.reduce(0..progress_steps, state, fn step, acc_state ->
      t = step / progress_steps
      interpolated_value = linear_interpolate(current_value, target_value, t)
      
      acc_state
      |> StateV2.set_fact(variable_name, "value", interpolated_value)
      |> StateV2.set_fact(variable_name, "progress", t)
      |> StateV2.set_fact(Integer.to_string(node_index), "current_progress", t)
      |> StateV2.set_fact(Integer.to_string(node_index), "current_value", interpolated_value)
    end)
    
    # Set final completion state
    final_state
    |> StateV2.set_fact(variable_name, "value", target_value)
    |> StateV2.set_fact(variable_name, "progress", 1.0)
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "duration", duration)
    |> StateV2.set_fact(Integer.to_string(node_index), "target_value", target_value)
  end

  @doc """
  Durative action function for variable animation with easing.
  """
  def variable_animate_durative_action(state, [node_index, variable_name, target_value, duration, easing_type]) do
    current_value = StateV2.get_fact(state, variable_name, "value") || 0.0
    progress_steps = max(1, trunc(duration * 10))
    
    final_state = Enum.reduce(0..progress_steps, state, fn step, acc_state ->
      t = step / progress_steps
      eased_t = apply_easing(t, easing_type)
      interpolated_value = linear_interpolate(current_value, target_value, eased_t)
      
      acc_state
      |> StateV2.set_fact(variable_name, "value", interpolated_value)
      |> StateV2.set_fact(variable_name, "progress", t)
      |> StateV2.set_fact(Integer.to_string(node_index), "current_progress", t)
      |> StateV2.set_fact(Integer.to_string(node_index), "current_value", interpolated_value)
      |> StateV2.set_fact(Integer.to_string(node_index), "easing_type", easing_type)
    end)
    
    final_state
    |> StateV2.set_fact(variable_name, "value", target_value)
    |> StateV2.set_fact(variable_name, "progress", 1.0)
    |> StateV2.set_fact(Integer.to_string(node_index), "completed", true)
  end

  # ==================== INSTANT ACTIONS ====================

  @doc """
  Instantly interpolate variable to target value at specified progress.
  """
  def variable_interpolate_instant(state, [node_index, variable_name, target_value, progress]) 
      when is_number(progress) and progress >= 0.0 and progress <= 1.0 do
    current_value = StateV2.get_fact(state, variable_name, "value") || 0.0
    interpolated_value = linear_interpolate(current_value, target_value, progress)
    
    state
    |> StateV2.set_fact(variable_name, "value", interpolated_value)
    |> StateV2.set_fact(variable_name, "progress", progress)
    |> StateV2.set_fact(Integer.to_string(node_index), "interpolated_value", interpolated_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "progress", progress)
  end

  def variable_interpolate_instant(state, [node_index, _variable_name, _target_value, _invalid_progress]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "error", "Invalid progress value")
  end

  @doc """
  Set variable progress value directly (0.0 to 1.0).
  """
  def variable_set_progress(state, [node_index, variable_name, progress]) 
      when is_number(progress) and progress >= 0.0 and progress <= 1.0 do
    state
    |> StateV2.set_fact(variable_name, "progress", progress)
    |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "progress_set", progress)
  end

  def variable_set_progress(state, [node_index, _variable_name, _invalid_progress]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
    |> StateV2.set_fact(Integer.to_string(node_index), "error", "Invalid progress value")
  end

  @doc """
  Set variable to specific value.
  """
  def variable_set(state, [node_index, variable_name, value]) do
    state
    |> StateV2.set_fact(variable_name, "value", value)
    |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "value_set", value)
  end

  # ==================== TASK METHODS ====================

  @doc "Task method for durative variable interpolation"
  def variable_interpolate_task_method(_state, [variable_name, target_value, duration]) do
    # For planning phase, use instant action with progress calculation
    progress = min(1.0, duration / 10.0) # Simple progress calculation
    [{:khr_variable_interpolate_instant, [1, variable_name, target_value, progress]}]
  end

  def variable_interpolate_task_method(_state, [node_id, variable_name, target_value, duration]) do
    # For planning phase, use instant action with progress calculation
    progress = min(1.0, duration / 10.0) # Simple progress calculation
    [{:khr_variable_interpolate_instant, [node_id, variable_name, target_value, progress]}]
  end

  @doc "Task method for instant variable interpolation"
  def variable_interpolate_instant_task_method(_state, [node_id, variable_name, target_value, progress]) do
    [{:khr_variable_interpolate_instant, [node_id, variable_name, target_value, progress]}]
  end

  @doc "Task method for durative variable animation"
  def variable_animate_task_method(_state, [node_id, variable_name, target_value, duration, _easing_type]) do
    # For planning phase, use instant action with progress calculation
    progress = min(1.0, duration / 10.0) # Simple progress calculation
    [{:khr_variable_interpolate_instant, [node_id, variable_name, target_value, progress]}]
  end

  @doc "Task method for setting progress"
  def variable_set_progress_task_method(_state, [node_id, variable_name, progress]) do
    [{:khr_variable_set_progress, [node_id, variable_name, progress]}]
  end

  def variable_set_progress_task_method(_state, [variable_name, progress]) do
    [{:khr_variable_set_progress, [1, variable_name, progress]}]
  end

  @doc "Task method for setting variable value"
  def variable_set_task_method(_state, [node_id, variable_name, value]) do
    [{:khr_variable_set, [node_id, variable_name, value]}]
  end

  # ==================== HELPER FUNCTIONS ====================

  @doc """
  Linear interpolation between two values.
  """
  def linear_interpolate(start_value, end_value, t) when is_number(start_value) and is_number(end_value) and is_number(t) do
    start_value * (1.0 - t) + end_value * t
  end

  def linear_interpolate(_start_value, end_value, t) when t >= 1.0 do
    end_value
  end

  def linear_interpolate(start_value, _end_value, t) when t <= 0.0 do
    start_value
  end

  def linear_interpolate(_start_value, _end_value, _t) do
    0.0 # Fallback for invalid inputs
  end

  @doc """
  Apply easing function to interpolation parameter.
  """
  def apply_easing(t, :linear), do: t
  def apply_easing(t, :ease_in), do: t * t
  def apply_easing(t, :ease_out), do: 1.0 - (1.0 - t) * (1.0 - t)
  def apply_easing(t, :ease_in_out) do
    cond do
      t < 0.5 -> 2.0 * t * t
      true -> 1.0 - 2.0 * (1.0 - t) * (1.0 - t)
    end
  end
  def apply_easing(t, _unknown_easing), do: t # Default to linear

  @doc """
  Create a progress tracking variable with initial state.
  """
  def create_progress_variable(state, variable_name, initial_value \\ 0.0) do
    state
    |> StateV2.set_fact(variable_name, "value", initial_value)
    |> StateV2.set_fact(variable_name, "progress", 0.0)
    |> StateV2.set_fact(variable_name, "type", "progress_variable")
  end

  @doc """
  Get progress information for a variable.
  """
  def get_progress_info(state, variable_name) do
    %{
      value: StateV2.get_fact(state, variable_name, "value"),
      progress: StateV2.get_fact(state, variable_name, "progress"),
      type: StateV2.get_fact(state, variable_name, "type")
    }
  end
end
