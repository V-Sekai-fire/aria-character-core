defmodule AriaInteractivity.TemporalIntegration do
  @moduledoc """
  glTF Temporal Integration Domain

  Implements temporal integration operations from glTF Interactivity Extension as planning domain methods.
  Supports temporal constraints, duration handling, and time-based coordination.

  Based on glTF Specification.adoc temporal nodes and ADR R25W1398085
  """

  use AriaCore.ActionAttributes

  # ============================================================================
  # TEMPORAL CONSTRAINT MANAGEMENT
  # ============================================================================

  # Set Temporal Constraint
  @unigoal_method predicate: "temporal_constraint_set"
  @spec set_temporal_constraint(AriaState.t(), {atom(), atom(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_temporal_constraint(_state, {from_action, to_action, min_delay}) do
    {:ok, [
      {:action, {:set_temporal_constraint, [from_action, to_action, min_delay]}}
    ]}
  end

  # Remove Temporal Constraint
  @unigoal_method predicate: "temporal_constraint_removed"
  @spec remove_temporal_constraint(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def remove_temporal_constraint(_state, {from_action, to_action}) do
    {:ok, [
      {:action, {:remove_temporal_constraint, [from_action, to_action]}}
    ]}
  end

  # Validate Temporal Constraints
  @unigoal_method predicate: "temporal_constraints_valid"
  @spec validate_temporal_constraints(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def validate_temporal_constraints(_state, {constraint_set}) do
    {:ok, [
      {:action, {:validate_temporal_constraints, [constraint_set]}}
    ]}
  end

  # ============================================================================
  # DURATION MANAGEMENT
  # ============================================================================

  # Set Action Duration
  @unigoal_method predicate: "action_duration_set"
  @spec set_action_duration(AriaState.t(), {atom(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_action_duration(_state, {action_name, duration}) do
    {:ok, [
      {:action, {:set_action_duration, [action_name, duration]}}
    ]}
  end

  # Get Action Duration
  @unigoal_method predicate: "action_duration_retrieved"
  @spec get_action_duration(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def get_action_duration(_state, {action_name}) do
    {:ok, [
      {:action, {:get_action_duration, [action_name]}}
    ]}
  end

  # Calculate Total Duration
  @unigoal_method predicate: "total_duration_calculated"
  @spec calculate_total_duration(AriaState.t(), {[atom()]}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def calculate_total_duration(_state, {action_names}) do
    {:ok, [
      {:action, {:calculate_total_duration, [action_names]}}
    ]}
  end

  # ============================================================================
  # TIME WINDOW MANAGEMENT
  # ============================================================================

  # Define Time Window
  @unigoal_method predicate: "time_window_defined"
  @spec define_time_window(AriaState.t(), {atom(), String.t(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def define_time_window(_state, {window_name, start_time, end_time}) do
    {:ok, [
      {:action, {:define_time_window, [window_name, start_time, end_time]}}
    ]}
  end

  # Check Time Window
  @unigoal_method predicate: "time_window_checked"
  @spec check_time_window(AriaState.t(), {atom(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def check_time_window(_state, {window_name, current_time}) do
    {:ok, [
      {:action, {:check_time_window, [window_name, current_time]}}
    ]}
  end

  # Extend Time Window
  @unigoal_method predicate: "time_window_extended"
  @spec extend_time_window(AriaState.t(), {atom(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def extend_time_window(_state, {window_name, new_end_time}) do
    {:ok, [
      {:action, {:extend_time_window, [window_name, new_end_time]}}
    ]}
  end

  # ============================================================================
  # TEMPORAL COORDINATION
  # ============================================================================

  # Synchronize Actions
  @unigoal_method predicate: "actions_synchronized"
  @spec synchronize_actions(AriaState.t(), {[atom()], String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def synchronize_actions(_state, {action_names, sync_time}) do
    {:ok, [
      {:temporal_action, {:synchronize_actions, [action_names, sync_time]}}
    ]}
  end

  # Sequence Actions Temporally
  @unigoal_method predicate: "actions_sequenced"
  @spec sequence_actions_temporally(AriaState.t(), {[atom()], [float()]}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def sequence_actions_temporally(_state, {action_names, delays}) do
    {:ok, [
      {:temporal_action, {:sequence_actions_temporally, [action_names, delays]}}
    ]}
  end

  # Parallel Actions with Duration
  @unigoal_method predicate: "parallel_actions_started"
  @spec start_parallel_actions(AriaState.t(), {[atom()], String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def start_parallel_actions(_state, {action_names, max_duration}) do
    {:ok, [
      {:temporal_action, {:start_parallel_actions, [action_names, max_duration]}}
    ]}
  end

  # ============================================================================
  # TEMPORAL MONITORING
  # ============================================================================

  # Monitor Action Timing
  @unigoal_method predicate: "action_timing_monitored"
  @spec monitor_action_timing(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def monitor_action_timing(_state, {action_name}) do
    {:ok, [
      {:action, {:monitor_action_timing, [action_name]}}
    ]}
  end

  # Get Timing Statistics
  @unigoal_method predicate: "timing_statistics_available"
  @spec get_timing_statistics(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def get_timing_statistics(_state, {action_name}) do
    {:ok, [
      {:action, {:get_timing_statistics, [action_name]}}
    ]}
  end

  # Check Timing Violations
  @unigoal_method predicate: "timing_violations_checked"
  @spec check_timing_violations(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def check_timing_violations(_state, {constraint_set}) do
    {:ok, [
      {:action, {:check_timing_violations, [constraint_set]}}
    ]}
  end

  # ============================================================================
  # TEMPORAL SCHEDULING
  # ============================================================================

  # Schedule Action at Time
  @unigoal_method predicate: "action_scheduled"
  @spec schedule_action_at_time(AriaState.t(), {atom(), String.t(), [term()]}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def schedule_action_at_time(_state, {action_name, scheduled_time, args}) do
    {:ok, [
      {:temporal_action, {:schedule_action_at_time, [action_name, scheduled_time, args]}}
    ]}
  end

  # Cancel Scheduled Action
  @unigoal_method predicate: "scheduled_action_cancelled"
  @spec cancel_scheduled_action(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def cancel_scheduled_action(_state, {action_name}) do
    {:ok, [
      {:action, {:cancel_scheduled_action, [action_name]}}
    ]}
  end

  # Reschedule Action
  @unigoal_method predicate: "action_rescheduled"
  @spec reschedule_action(AriaState.t(), {atom(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def reschedule_action(_state, {action_name, new_time}) do
    {:ok, [
      {:temporal_action, {:reschedule_action, [action_name, new_time]}}
    ]}
  end

  # ============================================================================
  # TEMPORAL PATTERNS (ADR R25W1398085)
  # ============================================================================

  # Pattern 1: Instant action, anytime
  @action true
  @spec instant_action(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def instant_action(state, [action_data]) do
    # No temporal constraints - can execute anytime
    {:ok, AriaState.set_fact(state, "instant_action_executed", "current", action_data)}
  end

  # Pattern 2: Floating duration
  @action duration: "PT2H"
  @spec floating_duration_action(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def floating_duration_action(state, [action_data]) do
    # Fixed duration, planner chooses start time
    {:ok, AriaState.set_fact(state, "floating_duration_executed", "current", action_data)}
  end

  # Pattern 4: Calculated start (deadline)
  @action end: "2025-06-22T14:00:00-07:00", duration: "PT2H"
  @spec deadline_action(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def deadline_action(state, [action_data]) do
    # Must start by 12 PM to finish by 2 PM
    {:ok, AriaState.set_fact(state, "deadline_action_executed", "current", action_data)}
  end

  # Pattern 6: Calculated end
  @action start: "2025-06-22T10:00:00-07:00", duration: "PT2H"
  @spec scheduled_start_action(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def scheduled_start_action(state, [action_data]) do
    # Starts at 10 AM, ends at 12 PM
    {:ok, AriaState.set_fact(state, "scheduled_start_executed", "current", action_data)}
  end

  # Pattern 7: Fixed interval
  @action start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"
  @spec fixed_interval_action(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def fixed_interval_action(state, [action_data]) do
    # Must execute exactly from 10 AM to 12 PM
    {:ok, AriaState.set_fact(state, "fixed_interval_executed", "current", action_data)}
  end

  # Pattern 8: Validation
  @action start: "2025-06-22T10:00:00-07:00",
          end: "2025-06-22T12:00:00-07:00",
          duration: "PT2H"
  @spec validation_action(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def validation_action(state, [action_data]) do
    # System validates that start + duration = end
    {:ok, AriaState.set_fact(state, "validation_action_executed", "current", action_data)}
  end

  # ============================================================================
  # TEMPORAL QUERYING
  # ============================================================================

  # Query Current Time
  @unigoal_method predicate: "current_time_retrieved"
  @spec get_current_time(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def get_current_time(_state, {time_format}) do
    {:ok, [
      {:action, {:get_current_time, [time_format]}}
    ]}
  end

  # Check Time Elapsed
  @unigoal_method predicate: "time_elapsed_checked"
  @spec check_time_elapsed(AriaState.t(), {String.t(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def check_time_elapsed(_state, {start_time, end_time}) do
    {:ok, [
      {:action, {:check_time_elapsed, [start_time, end_time]}}
    ]}
  end

  # Calculate Time Difference
  @unigoal_method predicate: "time_difference_calculated"
  @spec calculate_time_difference(AriaState.t(), {String.t(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def calculate_time_difference(_state, {time1, time2}) do
    {:ok, [
      {:action, {:calculate_time_difference, [time1, time2]}}
    ]}
  end

  # ============================================================================
  # TEMPORAL ERROR HANDLING
  # ============================================================================

  # Handle Temporal Violation
  @unigoal_method predicate: "temporal_violation_handled"
  @spec handle_temporal_violation(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def handle_temporal_violation(_state, {violation_type, recovery_action}) do
    {:ok, [
      {:action, {:handle_temporal_violation, [violation_type, recovery_action]}}
    ]}
  end

  # Retry Temporal Action
  @unigoal_method predicate: "temporal_action_retried"
  @spec retry_temporal_action(AriaState.t(), {atom(), integer()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def retry_temporal_action(_state, {action_name, max_retries}) do
    {:ok, [
      {:action, {:retry_temporal_action, [action_name, max_retries]}}
    ]}
  end

  # Temporal Timeout Handler
  @unigoal_method predicate: "temporal_timeout_handled"
  @spec handle_temporal_timeout(AriaState.t(), {atom(), float(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def handle_temporal_timeout(_state, {action_name, timeout, timeout_handler}) do
    {:ok, [
      {:temporal_action, {:handle_temporal_timeout, [action_name, timeout, timeout_handler]}}
    ]}
  end
end
