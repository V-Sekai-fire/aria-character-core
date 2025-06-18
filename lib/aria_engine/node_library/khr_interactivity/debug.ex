# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Debug do
  @moduledoc """
  KHR_interactivity Debug Nodes

  Implements debug operations from the glTF KHR_interactivity specification:
  - khr_debug_log: Output debug message with template parameters

  Debug nodes provide development and troubleshooting capabilities for
  KHR_interactivity graphs, allowing developers to inspect values and
  execution flow during runtime.
  """

  alias StateV2
  alias Domain.Actions
  require Logger

  @doc "Register all debug actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_debug_log, &debug_log/2, %{
      domain: "khr_interactivity",
      category: "debug",
      khr_node_type: "debug/log",
      description: "Output debug message with template parameters"
    })
  end

  @doc """
  Output debug message with template parameters.
  
  Formats and outputs a debug message using template string substitution.
  Supports multiple parameter types and provides timestamped logging.
  
  Template format supports:
  - {0}, {1}, {2}, etc. for positional parameter substitution
  - Basic type conversion for numbers, booleans, and strings
  - Automatic JSON encoding for complex data structures
  """
  def debug_log(state, [node_index, message_template | parameters]) do
    timestamp = System.system_time(:millisecond)
    
    # Format the message with parameter substitution
    formatted_message = format_debug_message(message_template, parameters)
    
    # Log the message using Elixir's Logger
    Logger.debug("[KHR_interactivity:#{node_index}] #{formatted_message}")
    
    # Store debug information in state for potential inspection
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "logged", true)
    |> StateV2.set_fact(Integer.to_string(node_index), "timestamp", timestamp)
    |> StateV2.set_fact(Integer.to_string(node_index), "message_template", message_template)
    |> StateV2.set_fact(Integer.to_string(node_index), "formatted_message", formatted_message)
    |> StateV2.set_fact(Integer.to_string(node_index), "parameter_count", length(parameters))
  end

  @doc """
  Format debug message with parameter substitution.
  
  Replaces {0}, {1}, {2}, etc. placeholders in the template with
  corresponding parameters from the list.
  """
  def format_debug_message(template, parameters) when is_binary(template) and is_list(parameters) do
    # Convert parameters to strings with type-appropriate formatting
    string_params = Enum.map(parameters, &format_parameter/1)
    
    # Replace {0}, {1}, etc. with corresponding parameters
    Enum.with_index(string_params)
    |> Enum.reduce(template, fn {param_str, index}, acc_template ->
      String.replace(acc_template, "{#{index}}", param_str)
    end)
  end

  def format_debug_message(template, parameters) do
    # Fallback for non-string templates or invalid parameters
    "Template: #{inspect(template)}, Parameters: #{inspect(parameters)}"
  end

  @doc """
  Format individual parameter for debug output.
  
  Converts various data types to appropriate string representations
  for debug logging purposes.
  """
  def format_parameter(param) do
    case param do
      # Numbers
      num when is_number(num) -> to_string(num)
      
      # Booleans
      bool when is_boolean(bool) -> to_string(bool)
      
      # Strings
      str when is_binary(str) -> str
      
      # Atoms (including special values like :nan, :positive_infinity)
      :nan -> "NaN"
      :positive_infinity -> "+∞"
      :negative_infinity -> "-∞"
      atom when is_atom(atom) -> to_string(atom)
      
      # Lists (vectors, arrays)
      list when is_list(list) ->
        if is_vector?(list) do
          format_vector(list)
        else
          "[#{Enum.map(list, &format_parameter/1) |> Enum.join(", ")}]"
        end
      
      # Maps and other complex structures
      complex ->
        case Jason.encode(complex) do
          {:ok, json} -> json
          {:error, _} -> inspect(complex)
        end
    end
  end

  @doc """
  Check if a list represents a mathematical vector.
  
  Simple heuristic: list of 2-4 numbers.
  """
  def is_vector?(list) when is_list(list) do
    length = length(list)
    length >= 2 and length <= 4 and Enum.all?(list, &is_number/1)
  end

  def is_vector?(_), do: false

  @doc """
  Format vector for readable debug output.
  
  Displays vectors in mathematical notation: (x, y, z)
  """
  def format_vector(vector) when is_list(vector) do
    components = Enum.map(vector, fn
      num when is_number(num) -> :erlang.float_to_binary(num / 1, [:compact, {:decimals, 3}])
      other -> format_parameter(other)
    end)
    
    "(#{Enum.join(components, ", ")})"
  end

  @doc """
  Enable or disable debug logging for specific node types.
  
  Helper function to control debug verbosity during development.
  """
  def set_debug_level(state, level) when level in [:debug, :info, :warn, :error, :off] do
    state
    |> StateV2.set_fact("debug_config", "log_level", level)
  end

  @doc """
  Check if debug logging is enabled for the current level.
  
  Helper function to conditionally execute debug operations.
  """
  def debug_enabled?(state, level \\ :debug) do
    current_level = StateV2.get_fact(state, "debug_config", "log_level") || :debug
    
    level_priority = %{
      debug: 0,
      info: 1, 
      warn: 2,
      error: 3,
      off: 4
    }
    
    level_priority[level] >= level_priority[current_level]
  end

  @doc """
  Get debug history for a specific node.
  
  Helper function to retrieve debug logs for inspection.
  """
  def get_debug_history(state, node_index) do
    node_id = Integer.to_string(node_index)
    
    %{
      logged: StateV2.get_fact(state, node_id, "logged"),
      timestamp: StateV2.get_fact(state, node_id, "timestamp"),
      message_template: StateV2.get_fact(state, node_id, "message_template"),
      formatted_message: StateV2.get_fact(state, node_id, "formatted_message"),
      parameter_count: StateV2.get_fact(state, node_id, "parameter_count")
    }
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Map.new()
  end

  @doc """
  Clear debug history for a node.
  
  Helper function to reset debug state.
  """
  def clear_debug_history(state, node_index) do
    node_id = Integer.to_string(node_index)
    
    state
    |> StateV2.remove_fact(node_id, "logged")
    |> StateV2.remove_fact(node_id, "timestamp")
    |> StateV2.remove_fact(node_id, "message_template")
    |> StateV2.remove_fact(node_id, "formatted_message")
    |> StateV2.remove_fact(node_id, "parameter_count")
  end
end
