# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.Actions do
  @moduledoc """
  Core action execution functions for domains.
  """
  alias AriaEngine.StateV2

  require Logger

  @type t :: AriaEngine.Domain.Core.t()
  @type action_name :: atom()
  @type action_fn :: (AriaEngine.StateV2.t(), list() -> AriaEngine.StateV2.t() | false)

  # Validates action metadata according to the unified durative action specification.
  # Supports:
  # - Fixed schedule: start/end ISO 8601 datetime strings
  # - Floating duration: ISO 8601 duration strings (PT format)
  # - Entity requirements: structured entity specifications
  @spec validate_action_metadata(map()) :: map()
  defp validate_action_metadata(metadata) when is_map(metadata) do
    # Check temporal specification validity and get updated metadata
    updated_metadata = validate_temporal_specification(metadata)

    # Validate entity requirements if present
    if Map.has_key?(updated_metadata, :requires_entities) do
      validate_entity_requirements(updated_metadata.requires_entities)
    end

    updated_metadata
  end

  # Validates temporal specification according to unified durative action spec
  # Returns updated metadata with default duration if none provided
  @spec validate_temporal_specification(map()) :: map()
  defp validate_temporal_specification(metadata) do
    has_duration = Map.has_key?(metadata, :duration)
    has_start = Map.has_key?(metadata, :start)
    has_end = Map.has_key?(metadata, :end)

    cond do
      # Case 1: Duration with start/end is invalid
      has_duration and (has_start or has_end) ->
        raise ArgumentError, "invalid temporal specification: cannot mix duration with start/end times"

      # Case 2: No temporal specification - default to zero duration
      not (has_duration or has_start or has_end) ->
        Map.put(metadata, :duration, "PT0S")

      # Case 3: Validate ISO 8601 datetime formats for start/end
      has_start ->
        validate_iso8601_datetime(metadata.start, "start")
        if has_end do
          validate_iso8601_datetime(metadata.end, "end")
          validate_start_before_end(metadata.start, metadata.end)
        end
        metadata

      # Case 4: Validate end time only
      has_end ->
        validate_iso8601_datetime(metadata.end, "end")
        metadata

      # Case 5: Duration only (existing floating duration support)
      has_duration ->
        validate_duration_format(metadata.duration)
        metadata
    end
  end

  # Validates ISO 8601 datetime string format using AriaEngine.Utils
  @spec validate_iso8601_datetime(String.t(), String.t()) :: :ok
  defp validate_iso8601_datetime(datetime_string, field_name) when is_binary(datetime_string) do
    case AriaEngine.Utils.validate_iso8601_datetime(datetime_string) do
      {:ok, _datetime} ->
        :ok
      {:error, reason} ->
        raise ArgumentError, "invalid ISO 8601 datetime for #{field_name}: #{reason}"
    end
  end

  defp validate_iso8601_datetime(value, field_name) do
    raise ArgumentError, "invalid ISO 8601 datetime for #{field_name}: expected string, got #{inspect(value)}"
  end

  # Validates that start time is before end time using AriaEngine.Utils
  @spec validate_start_before_end(String.t(), String.t()) :: :ok
  defp validate_start_before_end(start_string, end_string) do
    case AriaEngine.Utils.validate_datetime_order(start_string, end_string) do
      :ok ->
        :ok
      {:error, reason} ->
        raise ArgumentError, reason
    end
  end

  # Validates entity requirements structure
  @spec validate_entity_requirements(list()) :: :ok
  defp validate_entity_requirements(requires_entities) when is_list(requires_entities) do
    Enum.each(requires_entities, &validate_single_entity_requirement/1)
    :ok
  end

  defp validate_entity_requirements(value) do
    raise ArgumentError, "requires_entities must be a list, got #{inspect(value)}"
  end

  # Validates a single entity requirement
  @spec validate_single_entity_requirement(map()) :: :ok
  defp validate_single_entity_requirement(entity_req) when is_map(entity_req) do
    # Must have :type field
    unless Map.has_key?(entity_req, :type) do
      raise ArgumentError, "entity requirement must have :type field"
    end

    # If capabilities are present, they must be a list of atoms
    if Map.has_key?(entity_req, :capabilities) do
      capabilities = entity_req.capabilities
      unless is_list(capabilities) and Enum.all?(capabilities, &is_atom/1) do
        raise ArgumentError, "capabilities must be list of atoms"
      end
    end

    :ok
  end

  defp validate_single_entity_requirement(value) do
    raise ArgumentError, "entity requirement must be a map, got #{inspect(value)}"
  end

  # Validates duration format (must be string and valid ISO 8601 duration)
  @spec validate_duration_format(term()) :: :ok
  defp validate_duration_format(duration) when is_binary(duration) do
    # Check if it's a valid ISO 8601 duration string
    if String.starts_with?(duration, "PT") do
      case AriaEngine.Utils.validate_iso8601_duration(duration) do
        {:ok, _} -> :ok
        {:error, reason} -> raise ArgumentError, "invalid ISO 8601 duration: #{reason}"
      end
    else
      raise ArgumentError, "duration must be ISO 8601 format starting with 'PT', got: #{inspect(duration)}"
    end
  end

  defp validate_duration_format(duration) do
    raise ArgumentError, "duration must be a string, got #{inspect(duration)}"
  end

  @spec add_action(t(), action_name(), action_fn() | AriaEngine.Domain.DurativeAction.t(), map()) :: t()
  def add_action(
        domain,
        name,
        action_or_durative,
        metadata \\ %{}
      )
      when is_atom(name) and is_map(metadata) do
    cond do
      # Case 1: Regular function (instantaneous action)
      is_function(action_or_durative, 2) ->
        add_instantaneous_action(domain, name, action_or_durative, metadata)

      # Case 2: DurativeAction struct
      match?(%AriaEngine.Domain.DurativeAction{}, action_or_durative) ->
        case action_or_durative.duration do
          # Duration = 0: treat as instantaneous action
          {:fixed, 0} ->
            add_instantaneous_action(domain, name, action_or_durative.action_fn, metadata)

          # Duration > 0: treat as durative action
          _ ->
            add_durative_action_to_domain(domain, name, action_or_durative, metadata)
        end

      # Case 3: Unknown type
      true ->
        Logger.warning("Invalid action type for #{name}: #{inspect(action_or_durative)}")
        domain
    end
  end

  # Helper function to add instantaneous actions
  defp add_instantaneous_action(
         %{actions: actions, action_metadata: action_metadata, task_methods: methods} = domain,
         name,
         action_fn,
         metadata
       ) do
    # Validate metadata according to unified durative action specification
    validated_metadata = validate_action_metadata(metadata)

    # Normalize duration in metadata if present
    normalized_metadata =
      if Map.has_key?(validated_metadata, :duration) do
        duration = validated_metadata[:duration]

        # Check if duration is an ISO 8601 string and convert to Interval
        normalized_duration =
          if is_binary(duration) and String.starts_with?(duration, "PT") do
            # Create a floating duration interval from ISO 8601 string
            AriaEngine.Timeline.Interval.from_iso8601_duration(duration)
          else
            # Use existing normalization for other duration formats
            AriaEngine.Utils.normalize_duration(duration)
          end

        Map.put(validated_metadata, :duration, normalized_duration)
      else
        validated_metadata
      end

    # Add the action to the actions map
    updated_actions = Map.put(actions, name, action_fn)

    # Store action metadata
    updated_action_metadata = Map.put(action_metadata, name, normalized_metadata)

    # Create a task method that just returns the action as a primitive task
    # This allows the action to be used directly in HTN task decompositions
    task_name = Atom.to_string(name)
    primitive_method_fn = fn _state, args -> [{name, args}] end
    method_name = "primitive_#{task_name}"

    # Create a {name, function} tuple for the primitive method
    primitive_method = {method_name, primitive_method_fn}

    # Add the primitive method to task methods
    current_methods = Map.get(methods, task_name, [])
    # Put primitive method first
    updated_methods = [primitive_method | current_methods]
    updated_task_methods = Map.put(methods, task_name, updated_methods)

    %{
      domain
      | actions: updated_actions,
        action_metadata: updated_action_metadata,
        task_methods: updated_task_methods
    }
  end

  # Helper function to add durative actions
  defp add_durative_action_to_domain(
         %{durative_actions: durative_actions, task_methods: methods} = domain,
         name,
         durative_action,
         _metadata
       ) do
    # Store the durative action
    updated_durative_actions = Map.put(durative_actions, name, durative_action)

    # Create a task method for the durative action
    task_name = Atom.to_string(name)
    primitive_method_fn = fn _state, args -> [{name, args}] end
    method_name = "primitive_#{task_name}"

    # Create a {name, function} tuple for the primitive method
    primitive_method = {method_name, primitive_method_fn}

    # Add the primitive method to task methods
    current_methods = Map.get(methods, task_name, [])
    # Put primitive method first
    updated_methods = [primitive_method | current_methods]
    updated_task_methods = Map.put(methods, task_name, updated_methods)

    %{
      domain
      | durative_actions: updated_durative_actions,
        task_methods: updated_task_methods
    }
  end

  @doc """
  Adds multiple actions to the domain.

  Each action will be properly registered with its corresponding task method.
  `new_actions` can be a map of `%{action_name => action_fn}` or `%{action_name => {action_fn, metadata}}`.
  """
  @spec add_actions(t(), %{action_name() => action_fn() | {action_fn(), map()}}) :: t()
  def add_actions(%{} = domain, new_actions) do
    Enum.reduce(new_actions, domain, fn {name, action_def}, acc_domain ->
      case action_def do
        {action_fn, metadata} when is_function(action_fn, 2) and is_map(metadata) ->
          add_action(acc_domain, name, action_fn, metadata)

        action_fn when is_function(action_fn, 2) ->
          add_action(acc_domain, name, action_fn)

        _ ->
          Logger.warning("Invalid action definition for #{name}: #{inspect(action_def)}", [])
          acc_domain
      end
    end)
  end

  @doc """
  Gets an action function by name.
  """
  @spec get_action(t(), action_name()) :: action_fn() | nil
  def get_action(%{actions: actions}, name) do
    Map.get(actions, name)
  end

  @doc """
  Gets metadata for a given action.
  """
  @spec get_action_metadata(t(), action_name()) :: map() | nil
  def get_action_metadata(%{action_metadata: action_metadata}, name) do
    Map.get(action_metadata, name)
  end

  @doc """
  Checks if an action exists in the domain.
  """
  @spec has_action?(t(), action_name()) :: boolean()
  def has_action?(%{actions: actions}, name) do
    Map.has_key?(actions, name)
  end

  @doc """
  Executes an action with the given state and arguments.
  """
  @spec execute_action(t(), AriaEngine.StateV2.t(), action_name(), list()) ::
          {:ok, AriaEngine.StateV2.t()} | false
  def execute_action(%{} = domain, %AriaEngine.StateV2{} = state, action_name, args) do
    # First check if it's a regular action
    case get_action(domain, action_name) do
      nil ->
        # Check if it's a durative action
        case AriaEngine.Domain.Core.get_durative_action(domain, action_name) do
          nil ->
            false

          durative_action ->
            # Validate durative action preconditions
            if validate_durative_preconditions(durative_action, state) do
              # Execute the durative action
              case durative_action.action_fn.(state, args) do
                false ->
                  false

                %AriaEngine.StateV2{} = new_state ->
                  {:ok, new_state}
              end
            else
              # Preconditions failed
              false
            end
        end

      action_fn ->
        cond do
          is_function(action_fn, 2) ->
            case action_fn.(state, args) do
              false ->
                false

              %AriaEngine.StateV2{} = new_state ->
                {:ok, new_state}
            end

          match?(%AriaEngine.Domain.DurativeAction{}, action_fn) ->
            # If the action is a DurativeAction struct, validate preconditions first
            if validate_durative_preconditions(action_fn, state) do
              case action_fn.action_fn.(state, args) do
                false ->
                  false

                %AriaEngine.StateV2{} = new_state ->
                  {:ok, new_state}
              end
            else
              false
            end

          true ->
            false
        end
    end
  end

  # Validate durative action preconditions with quantifier support
  @spec validate_durative_preconditions(AriaEngine.Domain.DurativeAction.t(), AriaEngine.StateV2.t()) ::
          boolean()
  defp validate_durative_preconditions(durative_action, state) do
    # Check at_start conditions
    at_start_valid =
      Enum.all?(durative_action.conditions.at_start, fn condition ->
        validate_temporal_condition(condition, state)
      end)

    # Check over_all conditions
    over_all_valid =
      Enum.all?(durative_action.conditions.over_all, fn condition ->
        validate_temporal_condition(condition, state)
      end)

    # Check at_end conditions
    at_end_valid =
      Enum.all?(durative_action.conditions.at_end, fn condition ->
        validate_temporal_condition(condition, state)
      end)

    at_start_valid and over_all_valid and at_end_valid
  end

  # Validate a single temporal condition, supporting both regular and quantified conditions
  @spec validate_temporal_condition(tuple(), AriaEngine.StateV2.t()) :: boolean()
  defp validate_temporal_condition(condition, state) do
    case condition do
      # Quantified conditions (delegate to StateV2.evaluate_condition)
      # New StateV2 format: {:exists, subject_filter, predicate, fact_value}
      {:exists, _subject_filter, _predicate, _fact_value} ->
        StateV2.evaluate_condition(state, condition)

      {:forall, _subject_filter, _predicate, _fact_value} ->
        StateV2.evaluate_condition(state, condition)

      # Regular conditions (entity-first format)
      {entity, predicate, required_value} ->
        AriaEngine.StateV2.get_fact(state, entity, predicate) == required_value

      # Use the general condition evaluator for other formats
      _ ->
        StateV2.evaluate_condition(state, condition)
    end
  end
end
