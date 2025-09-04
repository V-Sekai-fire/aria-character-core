defmodule AriaInteractivity.StateOperations do
  @moduledoc """
  glTF State Operations Domain

  Implements state management operations from glTF Interactivity Extension as planning domain methods.
  Supports variable get/set operations and state manipulation.

  Based on glTF Specification.adoc variable and state nodes
  """

  use AriaCore.ActionAttributes

  # ============================================================================
  # VARIABLE OPERATIONS
  # ============================================================================

  # Variable Set
  @unigoal_method predicate: "variable_set"
  @spec set_variable(AriaState.t(), {atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_variable(_state, {variable_name, value}) do
    {:ok, [
      {:action, {:update_variable, [variable_name, value]}}
    ]}
  end

  # Variable Get
  @unigoal_method predicate: "variable_get"
  @spec get_variable(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def get_variable(_state, {variable_name}) do
    {:ok, [
      {:action, {:read_variable, [variable_name]}}
    ]}
  end

  # Variable Increment
  @unigoal_method predicate: "variable_incremented"
  @spec increment_variable(AriaState.t(), {atom(), number()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def increment_variable(_state, {variable_name, amount}) do
    {:ok, [
      {:action, {:increment_variable, [variable_name, amount]}}
    ]}
  end

  # Variable Decrement
  @unigoal_method predicate: "variable_decremented"
  @spec decrement_variable(AriaState.t(), {atom(), number()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def decrement_variable(_state, {variable_name, amount}) do
    {:ok, [
      {:action, {:decrement_variable, [variable_name, amount]}}
    ]}
  end

  # ============================================================================
  # STATE PREDICATES
  # ============================================================================

  # Check if variable equals value
  @unigoal_method predicate: "variable_equals"
  @spec variable_equals(AriaState.t(), {atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def variable_equals(_state, {variable_name, expected_value}) do
    {:ok, [
      {:goal, {:variable_equals, variable_name, expected_value}}
    ]}
  end

  # Check if variable is greater than value
  @unigoal_method predicate: "variable_greater_than"
  @spec variable_greater_than(AriaState.t(), {atom(), number()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def variable_greater_than(_state, {variable_name, threshold}) do
    {:ok, [
      {:goal, {:variable_greater_than, variable_name, threshold}}
    ]}
  end

  # Check if variable is less than value
  @unigoal_method predicate: "variable_less_than"
  @spec variable_less_than(AriaState.t(), {atom(), number()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def variable_less_than(_state, {variable_name, threshold}) do
    {:ok, [
      {:goal, {:variable_less_than, variable_name, threshold}}
    ]}
  end

  # ============================================================================
  # STATE TRANSITIONS
  # ============================================================================

  # Transition to state
  @unigoal_method predicate: "state_transitioned"
  @spec transition_to_state(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def transition_to_state(_state, {from_state, to_state}) do
    {:ok, [
      {:action, {:transition_state, [from_state, to_state]}}
    ]}
  end

  # Set state flag
  @unigoal_method predicate: "flag_set"
  @spec set_flag(AriaState.t(), {atom(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_flag(_state, {flag_name, value}) do
    {:ok, [
      {:action, {:set_flag, [flag_name, value]}}
    ]}
  end

  # Toggle state flag
  @unigoal_method predicate: "flag_toggled"
  @spec toggle_flag(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def toggle_flag(_state, {flag_name}) do
    {:ok, [
      {:action, {:toggle_flag, [flag_name]}}
    ]}
  end

  # ============================================================================
  # STATE VALIDATION
  # ============================================================================

  # Validate state consistency
  @unigoal_method predicate: "state_valid"
  @spec validate_state(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def validate_state(_state, {validation_type}) do
    {:ok, [
      {:action, {:validate_state, [validation_type]}}
    ]}
  end

  # Check state invariants
  @unigoal_method predicate: "invariants_checked"
  @spec check_invariants(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def check_invariants(_state, {invariant_set}) do
    {:ok, [
      {:action, {:check_invariants, [invariant_set]}}
    ]}
  end

  # ============================================================================
  # STATE HISTORY
  # ============================================================================

  # Record state change
  @unigoal_method predicate: "state_recorded"
  @spec record_state_change(AriaState.t(), {atom(), term(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def record_state_change(_state, {variable_name, old_value, new_value}) do
    {:ok, [
      {:action, {:record_state_change, [variable_name, old_value, new_value]}}
    ]}
  end

  # Undo state change
  @unigoal_method predicate: "state_undone"
  @spec undo_state_change(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def undo_state_change(_state, {variable_name}) do
    {:ok, [
      {:action, {:undo_state_change, [variable_name]}}
    ]}
  end

  # ============================================================================
  # STATE PERSISTENCE
  # ============================================================================

  # Save state
  @unigoal_method predicate: "state_saved"
  @spec save_state(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def save_state(_state, {save_slot}) do
    {:ok, [
      {:action, {:save_state, [save_slot]}}
    ]}
  end

  # Load state
  @unigoal_method predicate: "state_loaded"
  @spec load_state(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def load_state(_state, {save_slot}) do
    {:ok, [
      {:action, {:load_state, [save_slot]}}
    ]}
  end

  # Reset state
  @unigoal_method predicate: "state_reset"
  @spec reset_state(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def reset_state(_state, {reset_type}) do
    {:ok, [
      {:action, {:reset_state, [reset_type]}}
    ]}
  end
end
