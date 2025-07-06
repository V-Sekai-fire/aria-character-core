# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionAttributes.Converters do
  @moduledoc """
  Metadata conversion functions for AriaCore.ActionAttributes.

  This module handles converting attribute metadata to Domain specifications,
  bridging the new attribute syntax to existing Domain systems.
  """

  @type action_metadata :: keyword()
  @type duration_spec :: AriaCore.Temporal.Interval.duration()

  @doc """
  Converts @multigoal_method metadata to Domain multigoal method specification.
  """
  @spec convert_multigoal_metadata(map(), atom(), module()) :: function()
  def convert_multigoal_metadata(_metadata, method_name, module) do
    Function.capture(module, method_name, 2)
  end

  @doc """
  Converts @multitodo_method metadata to Domain multitodo method specification.
  """
  @spec convert_multitodo_metadata(map(), atom(), module()) :: function()
  def convert_multitodo_metadata(_metadata, method_name, module) do
    Function.capture(module, method_name, 2)
  end

  @doc """
  Converts @action metadata to Domain action specification.

  This function bridges the new attribute syntax to existing Domain.add_action format.
  """
  @spec convert_action_metadata(true, atom(), module()) :: map()
  def convert_action_metadata(true, action_name, module) do
    %{
      duration: convert_duration(nil), # Default to instant action
      entity_requirements: [],
      preconditions: [],
      effects: [],
      action_fn: Function.capture(module, action_name, 2)
    }
  end

  @spec convert_action_metadata(action_metadata(), atom(), module()) :: map()
  def convert_action_metadata(metadata, action_name, module) do
    %{
      duration: convert_duration(metadata[:duration]),
      entity_requirements: convert_entity_requirements(metadata[:requires_entities] || []),
      preconditions: metadata[:preconditions] || [],
      effects: metadata[:effects] || [],
      action_fn: Function.capture(module, action_name, 2),
      start_time: metadata[:start], # Add start_time
      end_time: metadata[:end] # Add end_time
    }
  end

  @doc """
  Converts @command metadata to Domain action specification.

  Commands are execution-time logic with failure handling according to ADR-181.
  They use the same specification format as actions but are intended for execution.
  """
  @spec convert_command_metadata(true, atom(), module()) :: map()
  def convert_command_metadata(true, command_name, module) do
    %{
      duration: convert_duration(nil), # Default to instant action
      entity_requirements: [],
      preconditions: [],
      effects: [],
      action_fn: Function.capture(module, command_name, 2),
      command: true  # Mark as command for execution-time logic
    }
  end

  @spec convert_command_metadata(action_metadata(), atom(), module()) :: map()
  def convert_command_metadata(metadata, command_name, module) do
    %{
      duration: convert_duration(metadata[:duration]),
      entity_requirements: convert_entity_requirements(metadata[:requires_entities] || []),
      preconditions: metadata[:preconditions] || [],
      effects: metadata[:effects] || [],
      action_fn: Function.capture(module, command_name, 2),
      command: true,  # Mark as command for execution-time logic
      start_time: metadata[:start], # Add start_time
      end_time: metadata[:end] # Add end_time
    }
  end

  @doc """
  Converts @task_method metadata to Domain method specification.

  According to ADR-181, @task_method attributes do not support priority or goal_pattern fields.
  Task methods are for workflow decomposition only.
  """
  def convert_method_metadata(_metadata, method_name, module) do
    # Return just the function for task method registration
    Function.capture(module, method_name, 2)
  end

  @doc """
  Converts @unigoal_method metadata to Domain unigoal method specification.

  According to ADR-181, @unigoal_method attributes only support the predicate field.
  Priority handling belongs in the planner's method selection logic, not in attribute metadata.
  """
  def convert_unigoal_metadata(true, method_name, module) do
    # For @unigoal_method true, infer predicate from method name
    # In unified namespace, method name should directly indicate the predicate
    predicate = method_name |> Atom.to_string() |> String.to_atom()
    %{
      predicate: predicate,
      goal_fn: Function.capture(module, method_name, 2)
    }
  end

  def convert_unigoal_metadata(metadata, method_name, module) when is_list(metadata) or is_map(metadata) do
    predicate = case metadata do
      %{predicate: pred} -> pred
      [predicate: pred] -> pred
      _ ->
        # Fallback: use method name directly in unified namespace
        method_name |> Atom.to_string() |> String.to_atom()
    end

    %{
      predicate: predicate,
      goal_fn: Function.capture(module, method_name, 2)
    }
  end

  # Private helper functions

  defp convert_duration(duration) when is_binary(duration) do
    # Convert ISO 8601 duration to internal format
    # LEVERAGE existing temporal parsing (sociable approach)
    AriaCore.Temporal.Interval.parse_iso8601(duration)
  end

  defp convert_duration(duration) when is_integer(duration) do
    # Convert seconds to internal format
    AriaCore.Temporal.Interval.fixed(duration)
  end

  defp convert_duration(nil) do
    # Default duration if not specified
    AriaCore.Temporal.Interval.fixed(1)
  end

  defp convert_entity_requirements(requirements) when is_list(requirements) do
    # LEVERAGE existing entity requirement processing (sociable approach)
    Enum.map(requirements, &AriaCore.Entity.Management.normalize_requirement/1)
  end

  defp convert_entity_requirements(_invalid_requirements) do
    # Handle invalid input gracefully by providing empty list
    # This allows the system to continue functioning with reasonable defaults
    []
  end
end
