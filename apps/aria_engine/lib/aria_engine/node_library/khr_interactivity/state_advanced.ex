defmodule AriaEngine.NodeLibrary.KHRInteractivity.StateAdvanced do
  @moduledoc """
  Advanced state management operations for KHR_interactivity specification.
  Implements variable sets, pointer operations, and state manipulation.
  """

  alias AriaEngine.StateV2

  # =============================================================================
  # Variable Operations
  # =============================================================================

  @doc """
  Set multiple variables at once.
  
  ## Parameters
  - state: Current state
  - [node_id, variable_map]: Node ID and map of variable_name -> value pairs
  
  ## Returns
  Updated state with all variables set
  """
  def set_multiple(state, [node_id, variable_map]) when is_map(variable_map) do
    final_state = 
      Enum.reduce(variable_map, state, fn {var_name, value}, acc_state ->
        StateV2.set_fact(acc_state, var_name, "value", value)
      end)
    
    StateV2.set_fact(final_state, Integer.to_string(node_id), "variables_set", Map.keys(variable_map))
  end

  def set_multiple(state, [node_id, _invalid_map]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "variables_set", [])
  end

  # =============================================================================
  # Pointer Operations
  # =============================================================================

  @doc """
  Get object model property value.
  
  ## Parameters
  - state: Current state
  - [node_id, object_id, property_path]: Node ID, object identifier, and property path
  
  ## Returns
  Updated state with property value
  """
  def pointer_get(state, [node_id, object_id, property_path]) when is_binary(property_path) do
    # Parse property path (e.g., "transform.position.x")
    path_parts = String.split(property_path, ".")
    
    # Navigate through the property hierarchy
    result = get_nested_property(state, object_id, path_parts)
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  def pointer_get(state, [node_id, _object_id, _invalid_path]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "value", nil)
  end

  @doc """
  Set object model property value.
  
  ## Parameters
  - state: Current state
  - [node_id, object_id, property_path, value]: Node ID, object identifier, property path, and new value
  
  ## Returns
  Updated state with property modified
  """
  def pointer_set(state, [node_id, object_id, property_path, value]) when is_binary(property_path) do
    # Parse property path
    path_parts = String.split(property_path, ".")
    
    # Set the nested property
    updated_state = set_nested_property(state, object_id, path_parts, value)
    
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "property_set", property_path)
  end

  def pointer_set(state, [node_id, _object_id, _invalid_path, _value]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "property_set", nil)
  end

  @doc """
  Interpolate object model property value.
  
  ## Parameters
  - state: Current state
  - [node_id, object_id, property_path, target_value, t]: Node ID, object, property, target, interpolation factor
  
  ## Returns
  Updated state with interpolated property value
  """
  def pointer_interpolate(state, [node_id, object_id, property_path, target_value, t]) 
      when is_binary(property_path) and is_number(t) do
    # Get current value
    path_parts = String.split(property_path, ".")
    current_value = get_nested_property(state, object_id, path_parts)
    
    # Interpolate based on value type
    interpolated_value = interpolate_values(current_value, target_value, t)
    
    # Set the interpolated value
    updated_state = set_nested_property(state, object_id, path_parts, interpolated_value)
    
    StateV2.set_fact(updated_state, Integer.to_string(node_id), "interpolated_value", interpolated_value)
  end

  def pointer_interpolate(state, [node_id, _object_id, _invalid_path, _target_value, _t]) do
    StateV2.set_fact(state, Integer.to_string(node_id), "interpolated_value", nil)
  end

  # =============================================================================
  # Helper Functions
  # =============================================================================

  defp get_nested_property(state, object_id, [property | rest_path]) do
    current_value = StateV2.get_fact(state, object_id, property)
    
    case rest_path do
      [] -> current_value
      _ -> 
        # For nested properties, we'd need more complex object model support
        # For now, just return the current level
        current_value
    end
  end

  defp get_nested_property(_state, _object_id, []) do
    nil
  end

  defp set_nested_property(state, object_id, [property], value) do
    StateV2.set_fact(state, object_id, property, value)
  end

  defp set_nested_property(state, object_id, [property | rest_path], value) do
    # For nested properties, we'd need more complex object model support
    # For now, just set at the current level
    StateV2.set_fact(state, object_id, property, value)
  end

  defp set_nested_property(state, _object_id, [], _value) do
    state
  end

  defp interpolate_values(current, target, t) when is_number(current) and is_number(target) do
    current * (1 - t) + target * t
  end

  defp interpolate_values(current, target, t) when is_list(current) and is_list(target) do
    if length(current) == length(target) do
      Enum.zip_with(current, target, fn c, t_val -> c * (1 - t) + t_val * t end)
    else
      current
    end
  end

  defp interpolate_values(current, _target, _t) do
    # For non-numeric types, just return current
    current
  end

  # =============================================================================
  # Task Methods for HTN Planning
  # =============================================================================

  def set_multiple_task_method(state, [node_id, variable_map]) do
    [[:khr_variable_set_multiple, node_id, variable_map]]
  end

  def pointer_get_task_method(state, [node_id, object_id, property_path]) do
    [[:khr_pointer_get, node_id, object_id, property_path]]
  end

  def pointer_set_task_method(state, [node_id, object_id, property_path, value]) do
    [[:khr_pointer_set, node_id, object_id, property_path, value]]
  end

  def pointer_interpolate_task_method(state, [node_id, object_id, property_path, target_value, t]) do
    [[:khr_pointer_interpolate, node_id, object_id, property_path, target_value, t]]
  end
end
