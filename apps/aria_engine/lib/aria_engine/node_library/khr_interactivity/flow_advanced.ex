defmodule AriaEngine.NodeLibrary.KHRInteractivity.FlowAdvanced do
  @moduledoc """
  Advanced control flow operations for KHR_interactivity specification.
  Implements loops, conditionals, delays, and flow control.
  """

  alias AriaEngine.StateV2

  # =============================================================================
  # Switch Operations
  # =============================================================================

  @doc """
  Switch operation - routes execution based on selection value.
  
  ## Parameters
  - state: Current state
  - [node_id, selection, cases, default_action]: Node ID, selection value, case map, default action
  
  ## Returns
  Updated state with selected action executed
  """
  def switch(state, [node_id, selection, cases, default_action]) when is_map(cases) do
    selected_action = Map.get(cases, selection, default_action)
    
    # Execute the selected action and store result
    result = execute_action(state, selected_action)
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Math switch operation - selects value based on selection.
  
  ## Parameters
  - state: Current state
  - [node_id, selection, cases, default_value]: Node ID, selection value, case map, default value
  
  ## Returns
  Updated state with selected value
  """
  def math_switch(state, [node_id, selection, cases, default_value]) when is_map(cases) do
    result = Map.get(cases, selection, default_value)
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Loop Operations
  # =============================================================================

  @doc """
  While loop operation.
  
  ## Parameters
  - state: Current state
  - [node_id, condition_node, body_action]: Node ID, condition node reference, body action
  
  ## Returns
  Updated state after loop completion
  """
  def while_loop(state, [node_id, condition_node, body_action]) do
    loop_state = while_loop_iteration(state, condition_node, body_action, 0)
    StateV2.set_fact(loop_state, Integer.to_string(node_id), "completed", true)
  end

  defp while_loop_iteration(state, condition_node, body_action, iteration) do
    # Safety limit to prevent infinite loops
    if iteration > 10000 do
      state
    else
      condition = StateV2.get_fact(state, Integer.to_string(condition_node), "value")
      
      if condition do
        updated_state = execute_action(state, body_action)
        while_loop_iteration(updated_state, condition_node, body_action, iteration + 1)
      else
        state
      end
    end
  end

  @doc """
  For loop operation with index.
  
  ## Parameters
  - state: Current state
  - [node_id, start_index, end_index, body_action]: Node ID, start index, end index, body action
  
  ## Returns
  Updated state after loop completion
  """
  def for_loop(state, [node_id, start_index, end_index, body_action]) do
    loop_state = for_loop_iteration(state, start_index, end_index, body_action, start_index)
    StateV2.set_fact(loop_state, Integer.to_string(node_id), "completed", true)
  end

  defp for_loop_iteration(state, current_index, end_index, body_action, original_start) do
    if current_index >= end_index do
      state
    else
      # Set current index in state
      index_state = StateV2.set_fact(state, "loop_index", "value", current_index)
      
      # Execute body
      updated_state = execute_action(index_state, body_action)
      
      # Continue loop
      for_loop_iteration(updated_state, current_index + 1, end_index, body_action, original_start)
    end
  end

  @doc """
  Do N times operation.
  
  ## Parameters
  - state: Current state
  - [node_id, n, body_action]: Node ID, number of times to execute, body action
  
  ## Returns
  Updated state after N executions
  """
  def do_n(state, [node_id, n, body_action]) when is_integer(n) and n > 0 do
    loop_state = do_n_iteration(state, n, body_action, 0)
    StateV2.set_fact(loop_state, Integer.to_string(node_id), "current_count", n)
  end

  def do_n(state, [node_id, _n, _body_action]) do
    # Invalid N value
    StateV2.set_fact(state, Integer.to_string(node_id), "current_count", 0)
  end

  defp do_n_iteration(state, n, body_action, current_count) do
    if current_count >= n do
      state
    else
      updated_state = execute_action(state, body_action)
      do_n_iteration(updated_state, n, body_action, current_count + 1)
    end
  end

  # =============================================================================
  # Multi-Gate Operations
  # =============================================================================

  @doc """
  Multi-gate operation - routes to outputs sequentially or randomly.
  
  ## Parameters
  - state: Current state
  - [node_id, outputs, is_random, is_loop]: Node ID, output actions, random flag, loop flag
  
  ## Returns
  Updated state with selected output executed
  """
  def multi_gate(state, [node_id, outputs, is_random, is_loop]) when is_list(outputs) do
    last_index = StateV2.get_fact(state, Integer.to_string(node_id), "last_index") || -1
    used_outputs = StateV2.get_fact(state, Integer.to_string(node_id), "used_outputs") || []
    
    {selected_index, new_used_outputs} = select_next_output(outputs, last_index, used_outputs, is_random, is_loop)
    
    if selected_index >= 0 and selected_index < length(outputs) do
      selected_action = Enum.at(outputs, selected_index)
      execute_action(state, selected_action)
      
      StateV2.set_fact(state, Integer.to_string(node_id), "last_index", selected_index)
      |> StateV2.set_fact(Integer.to_string(node_id), "used_outputs", new_used_outputs)
    else
      StateV2.set_fact(state, Integer.to_string(node_id), "last_index", -1)
    end
  end

  defp select_next_output(outputs, _last_index, used_outputs, is_random, is_loop) do
    available_indices = 
      0..(length(outputs) - 1)
      |> Enum.filter(&(&1 not in used_outputs))
    
    cond do
      length(available_indices) > 0 ->
        selected = if is_random do
          Enum.random(available_indices)
        else
          Enum.min(available_indices)
        end
        {selected, [selected | used_outputs]}
        
      is_loop ->
        # Reset and start over
        if is_random do
          selected = Enum.random(0..(length(outputs) - 1))
          {selected, [selected]}
        else
          {0, [0]}
        end
        
      true ->
        {-1, used_outputs}
    end
  end

  # =============================================================================
  # Wait Operations
  # =============================================================================

  @doc """
  Wait for all inputs operation.
  
  ## Parameters
  - state: Current state
  - [node_id, input_count]: Node ID and number of inputs to wait for
  
  ## Returns
  Updated state with wait status
  """
  def wait_all(state, [node_id, input_count]) when is_integer(input_count) do
    activated_inputs = StateV2.get_fact(state, Integer.to_string(node_id), "activated_inputs") || []
    remaining = input_count - length(activated_inputs)
    
    StateV2.set_fact(state, Integer.to_string(node_id), "remaining_inputs", remaining)
  end

  @doc """
  Activate input for wait_all operation.
  
  ## Parameters
  - state: Current state
  - [node_id, input_index]: Node ID and input index being activated
  
  ## Returns
  Updated state with input marked as activated
  """
  def wait_all_activate_input(state, [node_id, input_index]) do
    activated_inputs = StateV2.get_fact(state, Integer.to_string(node_id), "activated_inputs") || []
    
    if input_index not in activated_inputs do
      new_activated = [input_index | activated_inputs]
      StateV2.set_fact(state, Integer.to_string(node_id), "activated_inputs", new_activated)
    else
      state
    end
  end

  # =============================================================================
  # Throttle Operations
  # =============================================================================

  @doc """
  Throttle operation - limits execution frequency.
  
  ## Parameters
  - state: Current state
  - [node_id, duration]: Node ID and throttle duration in seconds
  
  ## Returns
  Updated state with throttle status
  """
  def throttle(state, [node_id, duration]) when is_number(duration) and duration > 0 do
    current_time = :os.system_time(:second)
    last_activation = StateV2.get_fact(state, Integer.to_string(node_id), "last_activation") || 0
    
    time_since_last = current_time - last_activation
    
    if time_since_last >= duration do
      # Allow execution
      StateV2.set_fact(state, Integer.to_string(node_id), "last_activation", current_time)
      |> StateV2.set_fact(Integer.to_string(node_id), "last_remaining_time", 0.0)
    else
      # Throttled
      remaining_time = duration - time_since_last
      StateV2.set_fact(state, Integer.to_string(node_id), "last_remaining_time", remaining_time)
    end
  end

  def throttle(state, [node_id, _duration]) do
    # Invalid duration
    StateV2.set_fact(state, Integer.to_string(node_id), "last_remaining_time", Float.nan())
  end

  # =============================================================================
  # Delay Operations
  # =============================================================================

  @doc """
  Set delay operation - schedules execution after delay.
  
  ## Parameters
  - state: Current state
  - [node_id, duration, action]: Node ID, delay duration, and action to execute
  
  ## Returns
  Updated state with delay scheduled
  """
  def set_delay(state, [node_id, duration, action]) when is_number(duration) and duration >= 0 do
    delay_index = generate_delay_index()
    current_time = :os.system_time(:second)
    execution_time = current_time + trunc(duration)
    
    # Store delay information
    delay_info = %{
      delay_index: delay_index,
      execution_time: execution_time,
      action: action,
      node_id: node_id
    }
    
    # Add to global delay registry
    delays = StateV2.get_fact(state, "system", "active_delays") || []
    updated_delays = [delay_info | delays]
    
    StateV2.set_fact(state, "system", "active_delays", updated_delays)
    |> StateV2.set_fact(Integer.to_string(node_id), "last_delay_index", delay_index)
  end

  def set_delay(state, [node_id, _duration, _action]) do
    # Invalid duration
    StateV2.set_fact(state, Integer.to_string(node_id), "last_delay_index", -1)
  end

  @doc """
  Cancel delay operation.
  
  ## Parameters
  - state: Current state
  - [node_id, delay_index]: Node ID and delay index to cancel
  
  ## Returns
  Updated state with delay cancelled
  """
  def cancel_delay(state, [node_id, delay_index]) when is_integer(delay_index) do
    delays = StateV2.get_fact(state, "system", "active_delays") || []
    updated_delays = Enum.reject(delays, &(&1.delay_index == delay_index))
    
    StateV2.set_fact(state, "system", "active_delays", updated_delays)
  end

  def cancel_delay(state, [_node_id, _delay_index]) do
    # Invalid delay index
    state
  end

  # =============================================================================
  # Helper Functions
  # =============================================================================

  defp execute_action(state, action) when is_list(action) do
    # For now, just store the action - in a full implementation this would execute it
    StateV2.set_fact(state, "last_action", "value", action)
  end

  defp execute_action(state, action) do
    StateV2.set_fact(state, "last_action", "value", action)
  end

  defp generate_delay_index() do
    :rand.uniform(1_000_000)
  end

  # =============================================================================
  # Task Methods for HTN Planning
  # =============================================================================

  def switch_task_method(state, [node_id, selection, cases, default_action]) do
    [[:khr_flow_switch, node_id, selection, cases, default_action]]
  end

  def math_switch_task_method(state, [node_id, selection, cases, default_value]) do
    [[:khr_math_switch, node_id, selection, cases, default_value]]
  end

  @doc "COMPOSITE: While loop decomposes into condition check + body iterations"
  def while_loop_task_method(state, [node_id, condition_node, body_action]) do
    # COMPOSITE PATTERN: Sequential with conditional loop
    [
      # 1. Initialize loop state
      [:khr_variable_set, "#{node_id}_loop_active", true],
      [:khr_variable_set, "#{node_id}_iterations", 0],
      
      # 2. Loop body (this will be repeated by the planner based on condition)
      ["flow/while_iteration", node_id, condition_node, body_action],
      
      # 3. Finalize loop
      [:khr_flow_while_complete, node_id]
    ]
  end

  @doc "COMPOSITE: For loop decomposes into initialization + iteration sequence + completion"
  def for_loop_task_method(state, [node_id, start_index, end_index, body_action]) do
    # COMPOSITE PATTERN: Sequential iteration pattern
    iteration_count = max(0, end_index - start_index)
    
    initialization = [
      [:khr_variable_set, "#{node_id}_current_index", start_index],
      [:khr_variable_set, "#{node_id}_end_index", end_index]
    ]
    
    # Generate iteration tasks
    iteration_tasks = for i <- start_index..(end_index - 1) do
      ["flow/for_iteration", node_id, i, body_action]
    end
    
    completion = [[:khr_flow_for_complete, node_id]]
    
    initialization ++ iteration_tasks ++ completion
  end

  @doc "COMPOSITE: Do N decomposes into N iterations of the body action"
  def do_n_task_method(state, [node_id, n, body_action]) when is_integer(n) and n > 0 do
    # COMPOSITE PATTERN: Sequential repetition
    initialization = [[:khr_variable_set, "#{node_id}_count", n]]
    
    # Generate N iteration tasks
    iteration_tasks = for i <- 1..n do
      ["flow/do_n_iteration", node_id, i, body_action]
    end
    
    completion = [[:khr_flow_do_n_complete, node_id]]
    
    initialization ++ iteration_tasks ++ completion
  end

  def do_n_task_method(state, [node_id, _n, _body_action]) do
    # Invalid N, just complete immediately
    [[:khr_flow_do_n_complete, node_id]]
  end

  @doc "COMPOSITE: Multi-gate decomposes into alternative output selection"
  def multi_gate_task_method(state, [node_id, outputs, is_random, is_loop]) when is_list(outputs) do
    # COMPOSITE PATTERN: Alternative selection
    setup = [
      [:khr_variable_set, "#{node_id}_is_random", is_random],
      [:khr_variable_set, "#{node_id}_is_loop", is_loop],
      [:khr_variable_set, "#{node_id}_used_outputs", []]
    ]
    
    # Create alternative paths for each output
    output_alternatives = Enum.with_index(outputs, fn output, index ->
      ["flow/multi_gate_output", node_id, index, output]
    end)
    
    # In a full implementation, the planner would choose one alternative
    # For now, we represent this as the first available output
    setup ++ [List.first(output_alternatives) || [:khr_flow_multi_gate_empty, node_id]]
  end

  def multi_gate_task_method(state, [node_id, _outputs, _is_random, _is_loop]) do
    [[:khr_flow_multi_gate_empty, node_id]]
  end

  @doc "COMPOSITE: Wait all decomposes into parallel input monitoring"
  def wait_all_task_method(state, [node_id, input_count]) when is_integer(input_count) and input_count > 0 do
    # COMPOSITE PATTERN: Parallel waiting for multiple inputs
    initialization = [
      [:khr_variable_set, "#{node_id}_input_count", input_count],
      [:khr_variable_set, "#{node_id}_activated_inputs", []]
    ]
    
    # Create parallel monitoring tasks for each input
    input_monitors = for i <- 0..(input_count - 1) do
      ["flow/wait_input", node_id, i]
    end
    
    # Completion check
    completion = [["flow/wait_all_complete", node_id]]
    
    # Sequential setup, then parallel monitoring, then completion
    initialization ++ input_monitors ++ completion
  end

  def wait_all_task_method(state, [node_id, _input_count]) do
    [[:khr_flow_wait_all_complete, node_id]]
  end

  def throttle_task_method(state, [node_id, duration]) do
    [[:khr_flow_throttle, node_id, duration]]
  end

  def set_delay_task_method(state, [node_id, duration, action]) do
    [{:durative_action, :khr_flow_set_delay, [node_id, duration, action], duration}]
  end

  def cancel_delay_task_method(state, [node_id, delay_index]) do
    [[:khr_flow_cancel_delay, node_id, delay_index]]
  end
end
