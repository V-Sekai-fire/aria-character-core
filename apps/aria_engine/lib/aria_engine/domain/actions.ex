# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.Actions do
  @moduledoc """
  Handles action-related operations for the planning domain.
  """

  require Logger
  alias AriaEngine.StateV2

  @type t :: AriaEngine.Domain.Core.t()
  @type action_name :: atom()
  @type action_fn :: (StateV2.t(), list() -> StateV2.t() | false)

  @doc """
  Adds an action to the domain.

  Actions are functions that take a state and arguments, returning either:
  - A new state (success)
  - false (failure)

  When an action is added, it also creates a corresponding task method
  so the action can be used directly in task decompositions.
  
  Optional `metadata` can be provided for the action, e.g., `duration: {min, max}`.
  """
  @spec add_action(t(), action_name(), action_fn(), map()) :: t()
  def add_action(%{actions: actions, action_metadata: action_metadata, task_methods: methods} = domain, name, action_fn, metadata \\ %{})
      when is_atom(name) and is_function(action_fn, 2) and is_map(metadata) do
    
    # Add the action to the actions map
    updated_actions = Map.put(actions, name, action_fn)
    
    # Store action metadata
    updated_action_metadata = Map.put(action_metadata, name, metadata)
    
    # Create a task method that just returns the action as a primitive task
    # This allows the action to be used directly in HTN task decompositions
    task_name = Atom.to_string(name)
    primitive_method_fn = fn _state, args -> [{name, args}] end
    method_name = "primitive_#{task_name}"
    
    # Create a {name, function} tuple for the primitive method
    primitive_method = {method_name, primitive_method_fn}
    
    # Add the primitive method to task methods
    current_methods = Map.get(methods, task_name, [])
    updated_methods = [primitive_method | current_methods]  # Put primitive method first
    updated_task_methods = Map.put(methods, task_name, updated_methods)
    
    %{domain | 
      actions: updated_actions, 
      action_metadata: updated_action_metadata, # Update action metadata
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
  @spec execute_action(t(), StateV2.t(), action_name(), list()) :: {:ok, StateV2.t()} | false
  def execute_action(%{} = domain, %StateV2{} = state, action_name, args) do
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
                %StateV2{} = new_state ->
                  {:ok, new_state}
              end
            else
              false  # Preconditions failed
            end
        end

      action_fn ->
        case action_fn.(state, args) do
          false ->
            false
          %StateV2{} = new_state ->
            {:ok, new_state}
        end
    end
  end

  # Validate durative action preconditions with quantifier support
  @spec validate_durative_preconditions(AriaEngine.Domain.DurativeAction.t(), StateV2.t()) :: boolean()
  defp validate_durative_preconditions(durative_action, state) do
    # Check at_start conditions
    at_start_valid = Enum.all?(durative_action.conditions.at_start, fn condition ->
      validate_temporal_condition(condition, state)
    end)
    
    # Check over_all conditions
    over_all_valid = Enum.all?(durative_action.conditions.over_all, fn condition ->
      validate_temporal_condition(condition, state)
    end)
    
    # Check at_end conditions
    at_end_valid = Enum.all?(durative_action.conditions.at_end, fn condition ->
      validate_temporal_condition(condition, state)
    end)
    
    at_start_valid and over_all_valid and at_end_valid
  end

  # Validate a single temporal condition, supporting both regular and quantified conditions
  @spec validate_temporal_condition(tuple(), StateV2.t()) :: boolean()
  defp validate_temporal_condition(condition, state) do
    case condition do
      # Quantified conditions (delegate to StateV2.evaluate_condition)
      {:exists, _predicate, _fact_value, _subject_filter} ->
        StateV2.evaluate_condition(state, condition)
      
      {:forall, _predicate, _fact_value, _subject_filter} ->
        StateV2.evaluate_condition(state, condition)
      
      # Regular conditions (entity-first format)
      {predicate, subject, required_value} ->
        StateV2.get_fact(state, subject, predicate) == required_value
      
      # Use the general condition evaluator for other formats
      _ ->
        StateV2.evaluate_condition(state, condition)
    end
  end
end
