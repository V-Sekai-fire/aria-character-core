# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Variable do
  @moduledoc """
  KHR_interactivity Variable Nodes

  Implements variable operations from the glTF KHR_interactivity specification:
  - khr_variable_get: Get variable value
  - khr_variable_set: Set variable value
  - khr_variable_add: Add to variable value
  - khr_variable_subtract: Subtract from variable value
  - khr_variable_multiply: Multiply variable value
  - khr_variable_divide: Divide variable value
  - khr_variable_increment: Increment variable by 1
  - khr_variable_decrement: Decrement variable by 1

  Variables provide persistent state storage within KHR_interactivity graphs.
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all variable actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_variable_get, &variable_get/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/get",
      description: "Get variable value"
    })
    |> Actions.add_action(:khr_variable_set, &variable_set/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/set",
      description: "Set variable value"
    })
    |> Actions.add_action(:khr_variable_add, &variable_add/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/add",
      description: "Add to variable value"
    })
    |> Actions.add_action(:khr_variable_subtract, &variable_subtract/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/subtract",
      description: "Subtract from variable value"
    })
    |> Actions.add_action(:khr_variable_multiply, &variable_multiply/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/multiply",
      description: "Multiply variable value"
    })
    |> Actions.add_action(:khr_variable_divide, &variable_divide/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/divide",
      description: "Divide variable value"
    })
    |> Actions.add_action(:khr_variable_increment, &variable_increment/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/increment",
      description: "Increment variable by 1"
    })
    |> Actions.add_action(:khr_variable_decrement, &variable_decrement/2, %{
      domain: "khr_interactivity",
      category: "variable",
      khr_node_type: "variable/decrement",
      description: "Decrement variable by 1"
    })
  end

  @doc """
  Get variable value.
  
  Retrieves the current value of a named variable.
  Returns the value or a default if the variable doesn't exist.
  """
  def variable_get(state, [node_index, variable_name, default_value \\ nil]) do
    # Variables are stored in a special "variables" subject
    value = StateV2.get_fact(state, "variables", variable_name) || default_value
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
  end

  @doc """
  Set variable value.
  
  Sets a named variable to a specific value.
  Creates the variable if it doesn't exist.
  """
  def variable_set(state, [node_index, variable_name, new_value]) do
    # Store the variable and output the set value
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "set")
  end

  @doc """
  Add to variable value.
  
  Adds a value to the current variable value.
  If the variable doesn't exist, treats it as 0.
  """
  def variable_add(state, [node_index, variable_name, add_value]) do
    current_value = StateV2.get_fact(state, "variables", variable_name) || 0
    new_value = current_value + add_value
    
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "add")
    |> StateV2.set_fact(Integer.to_string(node_index), "previous_value", current_value)
  end

  @doc """
  Subtract from variable value.
  
  Subtracts a value from the current variable value.
  If the variable doesn't exist, treats it as 0.
  """
  def variable_subtract(state, [node_index, variable_name, subtract_value]) do
    current_value = StateV2.get_fact(state, "variables", variable_name) || 0
    new_value = current_value - subtract_value
    
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "subtract")
    |> StateV2.set_fact(Integer.to_string(node_index), "previous_value", current_value)
  end

  @doc """
  Multiply variable value.
  
  Multiplies the current variable value by a factor.
  If the variable doesn't exist, treats it as 0.
  """
  def variable_multiply(state, [node_index, variable_name, multiply_value]) do
    current_value = StateV2.get_fact(state, "variables", variable_name) || 0
    new_value = current_value * multiply_value
    
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "multiply")
    |> StateV2.set_fact(Integer.to_string(node_index), "previous_value", current_value)
  end

  @doc """
  Divide variable value.
  
  Divides the current variable value by a divisor.
  If the variable doesn't exist, treats it as 0.
  Handles division by zero by returning NaN.
  """
  def variable_divide(state, [node_index, variable_name, divide_value]) do
    current_value = StateV2.get_fact(state, "variables", variable_name) || 0
    
    new_value = cond do
      divide_value == 0 -> :nan
      is_number(current_value) and is_number(divide_value) -> current_value / divide_value
      true -> :nan
    end
    
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "divide")
    |> StateV2.set_fact(Integer.to_string(node_index), "previous_value", current_value)
  end

  @doc """
  Increment variable by 1.
  
  Increases the variable value by 1.
  If the variable doesn't exist, treats it as 0.
  """
  def variable_increment(state, [node_index, variable_name]) do
    current_value = StateV2.get_fact(state, "variables", variable_name) || 0
    new_value = current_value + 1
    
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "increment")
    |> StateV2.set_fact(Integer.to_string(node_index), "previous_value", current_value)
  end

  @doc """
  Decrement variable by 1.
  
  Decreases the variable value by 1.
  If the variable doesn't exist, treats it as 0.
  """
  def variable_decrement(state, [node_index, variable_name]) do
    current_value = StateV2.get_fact(state, "variables", variable_name) || 0
    new_value = current_value - 1
    
    state
    |> StateV2.set_fact("variables", variable_name, new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "value", new_value)
    |> StateV2.set_fact(Integer.to_string(node_index), "variable_name", variable_name)
    |> StateV2.set_fact(Integer.to_string(node_index), "operation", "decrement")
    |> StateV2.set_fact(Integer.to_string(node_index), "previous_value", current_value)
  end

  @doc """
  List all variables and their values.
  
  Helper function to get all currently defined variables.
  """
  def list_variables(state) do
    # Get all facts for the "variables" subject
    case StateV2.get_all_facts_for_subject(state, "variables") do
      facts when is_map(facts) -> facts
      _ -> %{}
    end
  end

  @doc """
  Check if a variable exists.
  
  Helper function to test variable existence.
  """
  def variable_exists?(state, variable_name) do
    case StateV2.get_fact(state, "variables", variable_name) do
      nil -> false
      _ -> true
    end
  end

  @doc """
  Delete a variable.
  
  Helper function to remove a variable from state.
  """
  def delete_variable(state, variable_name) do
    StateV2.remove_fact(state, "variables", variable_name)
  end

  @doc """
  Initialize variables with default values.
  
  Helper function to set up initial variable state.
  """
  def initialize_variables(state, variable_defaults) when is_map(variable_defaults) do
    Enum.reduce(variable_defaults, state, fn {var_name, default_value}, acc_state ->
      # Only set if variable doesn't already exist
      case variable_exists?(acc_state, var_name) do
        false -> StateV2.set_fact(acc_state, "variables", var_name, default_value)
        true -> acc_state
      end
    end)
  end
end
