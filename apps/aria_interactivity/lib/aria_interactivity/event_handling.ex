defmodule AriaInteractivity.EventHandling do
  @moduledoc """
  glTF Event Handling Domain

  Implements event handling operations from glTF Interactivity Extension as planning domain methods.
  Supports event triggering, receiving, and asynchronous communication patterns.

  Based on glTF Specification.adoc event nodes
  """

  use AriaCore.ActionAttributes

  # ============================================================================
  # EVENT TRIGGERING
  # ============================================================================

  # Event Trigger
  @unigoal_method predicate: "event_triggered"
  @spec trigger_event(AriaState.t(), {atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def trigger_event(state, {event_name, event_data}) do
    {:ok, [
      {:action, {:send_event, [event_name, event_data]}}
    ]}
  end

  # Custom Event Trigger
  @unigoal_method predicate: "custom_event_triggered"
  @spec trigger_custom_event(AriaState.t(), {String.t(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def trigger_custom_event(state, {event_id, event_data}) do
    {:ok, [
      {:action, {:send_custom_event, [event_id, event_data]}}
    ]}
  end

  # Broadcast Event
  @unigoal_method predicate: "event_broadcasted"
  @spec broadcast_event(AriaState.t(), {atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def broadcast_event(state, {event_name, event_data}) do
    {:ok, [
      {:action, {:broadcast_event, [event_name, event_data]}}
    ]}
  end

  # ============================================================================
  # EVENT RECEIVING
  # ============================================================================

  # Event Receive
  @unigoal_method predicate: "event_received"
  @spec receive_event(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def receive_event(state, {event_name}) do
    {:ok, [
      {:action, {:wait_for_event, [event_name]}}
    ]}
  end

  # Wait for Custom Event
  @unigoal_method predicate: "custom_event_received"
  @spec wait_for_custom_event(AriaState.t(), {String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def wait_for_custom_event(state, {event_id}) do
    {:ok, [
      {:goal, {:custom_event_received, event_id, true}}
    ]}
  end

  # Event Listener
  @unigoal_method predicate: "event_listener_active"
  @spec setup_event_listener(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def setup_event_listener(state, {event_name, handler_function}) do
    {:ok, [
      {:action, {:setup_event_listener, [event_name, handler_function]}}
    ]}
  end

  # ============================================================================
  # EVENT FILTERING AND PROCESSING
  # ============================================================================

  # Filter Events
  @unigoal_method predicate: "events_filtered"
  @spec filter_events(AriaState.t(), {atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def filter_events(state, {event_name, filter_criteria}) do
    {:ok, [
      {:action, {:filter_events, [event_name, filter_criteria]}}
    ]}
  end

  # Event Debouncing
  @unigoal_method predicate: "event_debounced"
  @spec debounce_event(AriaState.t(), {atom(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def debounce_event(state, {event_name, debounce_time}) do
    {:ok, [
      {:temporal_action, {:debounce_event, [event_name, debounce_time]}}
    ]}
  end

  # Event Throttling
  @unigoal_method predicate: "event_throttled"
  @spec throttle_event(AriaState.t(), {atom(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def throttle_event(state, {event_name, throttle_time}) do
    {:ok, [
      {:temporal_action, {:throttle_event, [event_name, throttle_time]}}
    ]}
  end

  # ============================================================================
  # EVENT SEQUENCES AND PATTERNS
  # ============================================================================

  # Event Sequence
  @unigoal_method predicate: "event_sequence_started"
  @spec event_sequence(AriaState.t(), {[atom()], float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def event_sequence(state, {event_names, timeout}) do
    {:ok, [
      {:temporal_action, {:wait_for_event_sequence, [event_names, timeout]}}
    ]}
  end

  # Event Race
  @unigoal_method predicate: "event_race_completed"
  @spec event_race(AriaState.t(), {[atom()], float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def event_race(state, {event_names, timeout}) do
    {:ok, [
      {:temporal_action, {:wait_for_event_race, [event_names, timeout]}}
    ]}
  end

  # Event All
  @unigoal_method predicate: "all_events_received"
  @spec wait_for_all_events(AriaState.t(), {[atom()], float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def wait_for_all_events(state, {event_names, timeout}) do
    {:ok, [
      {:temporal_action, {:wait_for_all_events, [event_names, timeout]}}
    ]}
  end

  # ============================================================================
  # EVENT DATA PROCESSING
  # ============================================================================

  # Extract Event Data
  @unigoal_method predicate: "event_data_extracted"
  @spec extract_event_data(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def extract_event_data(state, {event_name, data_key}) do
    {:ok, [
      {:action, {:extract_event_data, [event_name, data_key]}}
    ]}
  end

  # Transform Event Data
  @unigoal_method predicate: "event_data_transformed"
  @spec transform_event_data(AriaState.t(), {atom(), atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def transform_event_data(state, {event_name, transformation, new_value}) do
    {:ok, [
      {:action, {:transform_event_data, [event_name, transformation, new_value]}}
    ]}
  end

  # Validate Event Data
  @unigoal_method predicate: "event_data_valid"
  @spec validate_event_data(AriaState.t(), {atom(), term()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def validate_event_data(state, {event_name, validation_rules}) do
    {:ok, [
      {:action, {:validate_event_data, [event_name, validation_rules]}}
    ]}
  end

  # ============================================================================
  # EVENT TIMING AND SCHEDULING
  # ============================================================================

  # Schedule Event
  @unigoal_method predicate: "event_scheduled"
  @spec schedule_event(AriaState.t(), {atom(), term(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def schedule_event(state, {event_name, event_data, delay}) do
    {:ok, [
      {:temporal_action, {:schedule_event, [event_name, event_data, delay]}}
    ]}
  end

  # Cancel Scheduled Event
  @unigoal_method predicate: "scheduled_event_cancelled"
  @spec cancel_scheduled_event(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def cancel_scheduled_event(state, {event_name}) do
    {:ok, [
      {:action, {:cancel_scheduled_event, [event_name]}}
    ]}
  end

  # Periodic Event
  @unigoal_method predicate: "periodic_event_started"
  @spec start_periodic_event(AriaState.t(), {atom(), term(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def start_periodic_event(state, {event_name, event_data, interval}) do
    {:ok, [
      {:temporal_action, {:start_periodic_event, [event_name, event_data, interval]}}
    ]}
  end

  # Stop Periodic Event
  @unigoal_method predicate: "periodic_event_stopped"
  @spec stop_periodic_event(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def stop_periodic_event(state, {event_name}) do
    {:ok, [
      {:action, {:stop_periodic_event, [event_name]}}
    ]}
  end

  # ============================================================================
  # EVENT LOGGING AND MONITORING
  # ============================================================================

  # Log Event
  @unigoal_method predicate: "event_logged"
  @spec log_event(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def log_event(state, {event_name, log_level}) do
    {:ok, [
      {:action, {:log_event, [event_name, log_level]}}
    ]}
  end

  # Monitor Event Frequency
  @unigoal_method predicate: "event_monitoring_started"
  @spec monitor_event_frequency(AriaState.t(), {atom(), float()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def monitor_event_frequency(state, {event_name, time_window}) do
    {:ok, [
      {:action, {:monitor_event_frequency, [event_name, time_window]}}
    ]}
  end

  # Event Statistics
  @unigoal_method predicate: "event_statistics_available"
  @spec get_event_statistics(AriaState.t(), {atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def get_event_statistics(state, {event_name}) do
    {:ok, [
      {:action, {:get_event_statistics, [event_name]}}
    ]}
  end

  # ============================================================================
  # EVENT ERROR HANDLING
  # ============================================================================

  # Event Error Handler
  @unigoal_method predicate: "event_error_handler_set"
  @spec set_event_error_handler(AriaState.t(), {atom(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_event_error_handler(state, {event_name, error_handler}) do
    {:ok, [
      {:action, {:set_event_error_handler, [event_name, error_handler]}}
    ]}
  end

  # Retry Failed Event
  @unigoal_method predicate: "failed_event_retried"
  @spec retry_failed_event(AriaState.t(), {atom(), integer()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def retry_failed_event(state, {event_name, max_retries}) do
    {:ok, [
      {:action, {:retry_failed_event, [event_name, max_retries]}}
    ]}
  end

  # Event Timeout Handler
  @unigoal_method predicate: "event_timeout_handled"
  @spec handle_event_timeout(AriaState.t(), {atom(), float(), atom()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def handle_event_timeout(state, {event_name, timeout, timeout_handler}) do
    {:ok, [
      {:temporal_action, {:handle_event_timeout, [event_name, timeout, timeout_handler]}}
    ]}
  end
end
