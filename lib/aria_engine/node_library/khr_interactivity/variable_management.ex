defmodule AriaEngine.NodeLibrary.KHRInteractivity.VariableManagement do
  @moduledoc """
  KHR_interactivity Variable Management Nodes

  Implements variable and pointer operations from the glTF KHR_interactivity specification:
  - khr_variable_get: Read variable values from state
  - khr_variable_set: Write variable values to state
  - khr_pointer_get: Dereference pointer values
  - khr_pointer_set: Set pointer target values
  - khr_variable_exists: Check if variable exists
  - khr_variable_delete: Remove variable from state

  Variables are stored as state facts using the variable name as the subject.
  Pointers reference other variables by name and support indirection.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.{Actions, Methods, Core}

  @doc "Register instant action operations"
  @spec register_instant_actions(Core.t()) :: Core.t()
  def register_instant_actions(domain), do: register_actions(domain)

  @doc "Register task methods using exact KHR specification names"
  @spec register_task_methods(Core.t()) :: Core.t()
  def register_task_methods(domain) do
    domain
    |> Methods.add_task_methods("variable/get", [
      {"basic_get", &variable_get_task_method/2}
    ])
    |> Methods.add_task_methods("variable/set", [
      {"basic_set", &variable_set_task_method/2}
    ])
    |> Methods.add_task_methods("pointer/get", [
      {"basic_get", &pointer_get_task_method/2}
    ])
    |> Methods.add_task_methods("pointer/set", [
      {"basic_set", &pointer_set_task_method/2}
    ])
    |> Methods.add_task_methods("variable/exists", [
      {"basic_check", &variable_exists_task_method/2}
    ])
    |> Methods.add_task_methods("variable/delete", [
      {"basic_delete", &variable_delete_task_method/2}
    ])
  end

  @doc "Register all variable management actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_variable_get, &variable_get/2, %{
      domain: "khr_interactivity",
      category: "variable_management",
      khr_node_type: "variable/get",
      description: "Read variable value from state"
    })
    |> Actions.add_action(:khr_variable_set, &variable_set/2, %{
      domain: "khr_interactivity",
      category: "variable_management",
      khr_node_type: "variable/set",
      description: "Write variable value to state"
    })
    |> Actions.add_action(:khr_pointer_get, &pointer_get/2, %{
      domain: "khr_interactivity",
      category: "variable_management",
      khr_node_type: "pointer/get",
      description: "Dereference pointer value"
    })
    |> Actions.add_action(:khr_pointer_set, &pointer_set/2, %{
      domain: "khr_interactivity",
      category: "variable_management",
      khr_node_type: "pointer/set",
      description: "Set pointer target value"
    })
    |> Actions.add_action(:khr_variable_exists, &variable_exists/2, %{
      domain: "khr_interactivity",
      category: "variable_management",
      khr_node_type: "variable/exists",
      description: "Check if variable exists in state"
    })
    |> Actions.add_action(:khr_variable_delete, &variable_delete/2, %{
      domain: "khr_interactivity",
      category: "variable_management",
      khr_node_type: "variable/delete",
      description: "Remove variable from state"
    })
  end

  @doc "Read variable value from state"
  def variable_get(state, [node_index, variable_name]) when is_binary(variable_name) do
    value = StateV2.get_fact(state, variable_name, "value")
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", value)
  end

  def variable_get(state, [node_index, _variable_name]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", nil)
  end

  @doc "Write variable value to state"
  def variable_set(state, [node_index, variable_name, value]) when is_binary(variable_name) do
    state
    |> StateV2.set_fact(variable_name, "value", value)
    |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
  end

  def variable_set(state, [node_index, _variable_name, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
  end

  @doc "Dereference pointer value (read value from variable that pointer points to)"
  def pointer_get(state, [node_index, pointer_name]) when is_binary(pointer_name) do
    # Get the target variable name from the pointer
    target_variable = StateV2.get_fact(state, pointer_name, "target")
    
    if is_binary(target_variable) do
      # Get the value from the target variable
      value = StateV2.get_fact(state, target_variable, "value")
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "value", value)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "value", nil)
    end
  end

  def pointer_get(state, [node_index, _pointer_name]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", nil)
  end

  @doc "Set pointer target value (write value to variable that pointer points to)"
  def pointer_set(state, [node_index, pointer_name, value]) when is_binary(pointer_name) do
    # Get the target variable name from the pointer
    target_variable = StateV2.get_fact(state, pointer_name, "target")
    
    if is_binary(target_variable) do
      # Set the value in the target variable
      state
      |> StateV2.set_fact(target_variable, "value", value)
      |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
    end
  end

  def pointer_set(state, [node_index, _pointer_name, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
  end

  @doc "Check if variable exists in state"
  def variable_exists(state, [node_index, variable_name]) when is_binary(variable_name) do
    exists = StateV2.get_fact(state, variable_name, "value") != nil
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", exists)
  end

  def variable_exists(state, [node_index, _variable_name]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", false)
  end

  @doc "Remove variable from state"
  def variable_delete(state, [node_index, variable_name]) when is_binary(variable_name) do
    # Remove the variable's value fact
    state
    |> StateV2.remove_fact(variable_name, "value")
    |> StateV2.set_fact(Integer.to_string(node_index), "success", true)
  end

  def variable_delete(state, [node_index, _variable_name]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "success", false)
  end

  # Task method functions - decompose KHR spec strings to atom-based actions

  @doc "Task method for variable/get - decomposes to atom-based action"
  def variable_get_task_method(_state, [node_id, variable_name]) do
    [[:khr_variable_get, node_id, variable_name]]
  end

  @doc "Task method for variable/set - decomposes to atom-based action"
  def variable_set_task_method(_state, [node_id, variable_name, value]) do
    [[:khr_variable_set, node_id, variable_name, value]]
  end

  @doc "Task method for pointer/get - decomposes to atom-based action"
  def pointer_get_task_method(_state, [node_id, pointer_name]) do
    [[:khr_pointer_get, node_id, pointer_name]]
  end

  @doc "Task method for pointer/set - decomposes to atom-based action"
  def pointer_set_task_method(_state, [node_id, pointer_name, value]) do
    [[:khr_pointer_set, node_id, pointer_name, value]]
  end

  @doc "Task method for variable/exists - decomposes to atom-based action"
  def variable_exists_task_method(_state, [node_id, variable_name]) do
    [[:khr_variable_exists, node_id, variable_name]]
  end

  @doc "Task method for variable/delete - decomposes to atom-based action"
  def variable_delete_task_method(_state, [node_id, variable_name]) do
    [[:khr_variable_delete, node_id, variable_name]]
  end

  @doc "Helper function to create a pointer that references a variable"
  def create_pointer(state, pointer_name, target_variable_name) 
      when is_binary(pointer_name) and is_binary(target_variable_name) do
    state
    |> StateV2.set_fact(pointer_name, "target", target_variable_name)
    |> StateV2.set_fact(pointer_name, "type", "pointer")
  end
end
