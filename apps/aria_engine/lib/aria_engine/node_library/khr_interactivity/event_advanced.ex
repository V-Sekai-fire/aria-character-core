defmodule AriaEngine.NodeLibrary.KHRInteractivity.EventAdvanced do
  @moduledoc """
  Advanced event operations for KHR_interactivity specification.
  Implements lifecycle events and debug operations.
  """

  alias AriaEngine.StateV2

  # =============================================================================
  # Lifecycle Events
  # =============================================================================

  @doc """
  Graph start event - triggers when behavior graph begins execution.
  
  ## Parameters
  - state: Current state
  - [node_id]: Node ID for the event
  
  ## Returns
  Updated state with start event triggered
  """
  def on_start(state, [node_id]) do
    current_time = :os.system_time(:millisecond) / 1000.0
    
    # Mark the start event as triggered
    StateV2.set_fact(state, Integer.to_string(node_id), "event_type", "start")
    |> StateV2.set_fact(Integer.to_string(node_id), "triggered_at", current_time)
    |> StateV2.set_fact(Integer.to_string(node_id), "triggered", true)
  end

  @doc """
  Frame tick event - triggers on each frame update.
  
  ## Parameters
  - state: Current state
  - [node_id, delta_time]: Node ID and time since last tick
  
  ## Returns
  Updated state with tick event triggered
  """
  def on_tick(state, [node_id, delta_time]) when is_number(delta_time) do
    current_time = :os.system_time(:millisecond) / 1000.0
    
    # Update tick information
    StateV2.set_fact(state, Integer.to_string(node_id), "event_type", "tick")
    |> StateV2.set_fact(Integer.to_string(node_id), "delta_time", delta_time)
    |> StateV2.set_fact(Integer.to_string(node_id), "triggered_at", current_time)
    |> StateV2.set_fact(Integer.to_string(node_id), "triggered", true)
  end

  def on_tick(state, [node_id, _invalid_delta]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "event_type", "tick")
    |> StateV2.set_fact(Integer.to_string(node_id), "delta_time", 0.0)
    |> StateV2.set_fact(Integer.to_string(node_id), "triggered", false)
  end

  # =============================================================================
  # Debug Operations
  # =============================================================================

  @doc """
  Debug log operation - outputs debug message.
  
  ## Parameters
  - state: Current state
  - [node_id, message, level]: Node ID, message, and log level
  
  ## Returns
  Updated state with debug message logged
  """
  def debug_log(state, [node_id, message, level]) when is_binary(message) do
    current_time = :os.system_time(:millisecond) / 1000.0
    
    # Create log entry
    log_entry = %{
      message: message,
      level: level || "info",
      timestamp: current_time,
      node_id: node_id
    }
    
    # Store in debug logs
    debug_logs = StateV2.get_fact(state, "system", "debug_logs") || []
    updated_logs = [log_entry | debug_logs]
    
    # Also output to console in development
    if Application.get_env(:aria_engine, :debug_output, false) do
      IO.puts("[#{level || "info"}] Node #{node_id}: #{message}")
    end
    
    StateV2.set_fact(state, "system", "debug_logs", updated_logs)
    |> StateV2.set_fact(Integer.to_string(node_id), "last_log_message", message)
  end

  def debug_log(state, [node_id, message]) do
    debug_log(state, [node_id, message, "info"])
  end

  def debug_log(state, [node_id, _invalid_message, _level]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "last_log_message", nil)
  end

  # =============================================================================
  # Event Utilities
  # =============================================================================

  @doc """
  Clear event state - resets event trigger status.
  
  ## Parameters
  - state: Current state
  - [node_id]: Node ID to clear
  
  ## Returns
  Updated state with event cleared
  """
  def clear_event(state, [node_id]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "triggered", false)
    |> StateV2.set_fact(Integer.to_string(node_id), "triggered_at", nil)
  end

  @doc """
  Check if event is triggered.
  
  ## Parameters
  - state: Current state
  - [node_id, target_node_id]: Node ID and target event node to check
  
  ## Returns
  Updated state with trigger status
  """
  def is_triggered(state, [node_id, target_node_id]) do
    is_triggered = StateV2.get_fact(state, Integer.to_string(target_node_id), "triggered") || false
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", is_triggered)
  end

  # =============================================================================
  # System Event Management
  # =============================================================================

  @doc """
  Initialize event system for a behavior graph.
  
  ## Parameters
  - state: Current state
  - [graph_id]: Behavior graph identifier
  
  ## Returns
  Updated state with event system initialized
  """
  def initialize_event_system(state, [graph_id]) do
    current_time = :os.system_time(:millisecond) / 1000.0
    
    # Create event system state
    event_system = %{
      graph_id: graph_id,
      initialized_at: current_time,
      active_events: [],
      event_handlers: %{}
    }
    
    StateV2.set_fact(state, "event_system_#{graph_id}", "state", event_system)
  end

  @doc """
  Trigger start events for all nodes in a graph.
  
  ## Parameters
  - state: Current state
  - [graph_id, node_ids]: Graph ID and list of node IDs
  
  ## Returns
  Updated state with all start events triggered
  """
  def trigger_graph_start(state, [graph_id, node_ids]) when is_list(node_ids) do
    current_time = :os.system_time(:millisecond) / 1000.0
    
    # Trigger start event for each node
    Enum.reduce(node_ids, state, fn node_id, acc_state ->
      on_start(acc_state, [node_id])
    end)
    |> StateV2.set_fact("event_system_#{graph_id}", "graph_started_at", current_time)
  end

  def trigger_graph_start(state, [graph_id, _invalid_nodes]) do
    StateV2.set_fact(state, "event_system_#{graph_id}", "graph_started_at", nil)
  end

  @doc """
  Process frame tick for all active nodes.
  
  ## Parameters
  - state: Current state
  - [graph_id, active_nodes, delta_time]: Graph ID, active node list, and frame delta
  
  ## Returns
  Updated state with frame tick processed
  """
  def process_frame_tick(state, [graph_id, active_nodes, delta_time]) 
      when is_list(active_nodes) and is_number(delta_time) do
    
    # Process tick for each active node
    Enum.reduce(active_nodes, state, fn node_id, acc_state ->
      on_tick(acc_state, [node_id, delta_time])
    end)
    |> StateV2.set_fact("event_system_#{graph_id}", "last_frame_time", delta_time)
  end

  def process_frame_tick(state, [graph_id, _invalid_nodes, _invalid_delta]) do
    StateV2.set_fact(state, "event_system_#{graph_id}", "last_frame_time", 0.0)
  end

  # =============================================================================
  # Task Methods for HTN Planning
  # =============================================================================

  def on_start_task_method(state, [node_id]) do
    [[:khr_event_on_start, node_id]]
  end

  def on_tick_task_method(state, [node_id, delta_time]) do
    [[:khr_event_on_tick, node_id, delta_time]]
  end

  def debug_log_task_method(state, [node_id, message]) do
    [[:khr_debug_log, node_id, message]]
  end

  def debug_log_task_method(state, [node_id, message, level]) do
    [[:khr_debug_log, node_id, message, level]]
  end

  def clear_event_task_method(state, [node_id]) do
    [[:khr_event_clear, node_id]]
  end

  def is_triggered_task_method(state, [node_id, target_node_id]) do
    [[:khr_event_is_triggered, node_id, target_node_id]]
  end

  def initialize_event_system_task_method(state, [graph_id]) do
    [[:khr_event_initialize_system, graph_id]]
  end

  def trigger_graph_start_task_method(state, [graph_id, node_ids]) do
    [[:khr_event_trigger_graph_start, graph_id, node_ids]]
  end

  def process_frame_tick_task_method(state, [graph_id, active_nodes, delta_time]) do
    [[:khr_event_process_frame_tick, graph_id, active_nodes, delta_time]]
  end
end
