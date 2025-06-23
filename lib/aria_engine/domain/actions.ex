# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain.Actions do
  @moduledoc "Core action execution functions for domains.\n"
  alias AriaEngine.State
  require Logger
  @type t :: Domain.Core.t()
  @type action_name :: atom()
  @type action_fn :: (AriaEngine.State.t(), list() -> AriaEngine.State.t() | false)
  @doc "Adds an action to the domain using the unified API.\n\nActions can be:\n- Functions (for instantaneous actions)\n- DurativeAction structs with duration = 0 (instantaneous actions)\n- DurativeAction structs with duration > 0 (durative actions)\n\nWhen an action is added, it also creates a corresponding task method\nso the action can be used directly in task decompositions.\n\nOptional `metadata` can be provided for the action, e.g., `duration: {min, max}`.\n"
  @spec add_action(t(), action_name(), action_fn() | Domain.DurativeAction.t(), map()) :: t()
  def add_action(
        domain,
        name,
        action_or_durative,
        metadata \\ %{}
      )
      when is_atom(name) and is_map(metadata) do
    cond do
      is_function(action_or_durative, 2) ->
        add_instantaneous_action(domain, name, action_or_durative, metadata)

      match?(%Domain.DurativeAction{}, action_or_durative) ->
        case action_or_durative.duration do
          {:fixed, 0} ->
            add_instantaneous_action(domain, name, action_or_durative.action_fn, metadata)

          _ ->
            add_durative_action_to_domain(domain, name, action_or_durative, metadata)
        end

      true ->
        Logger.warning("Invalid action type for #{name}: #{inspect(action_or_durative)}")
        domain
    end
  end

  defp add_instantaneous_action(
         %{actions: actions, action_metadata: action_metadata, task_methods: methods} = domain,
         name,
         action_fn,
         metadata
       ) do
    normalized_metadata =
      if Map.has_key?(metadata, :duration) do
        duration = metadata[:duration]
        Map.put(metadata, :duration, AriaEngine.Utils.normalize_duration(duration))
      else
        metadata
      end

    updated_actions = Map.put(actions, name, action_fn)
    updated_action_metadata = Map.put(action_metadata, name, normalized_metadata)
    task_name = Atom.to_string(name)
    primitive_method_fn = fn _state, args -> [{name, args}] end
    method_name = "primitive_#{task_name}"
    primitive_method = {method_name, primitive_method_fn}
    current_methods = Map.get(methods, task_name, [])
    updated_methods = [primitive_method | current_methods]
    updated_task_methods = Map.put(methods, task_name, updated_methods)

    %{
      domain
      | actions: updated_actions,
        action_metadata: updated_action_metadata,
        task_methods: updated_task_methods
    }
  end

  defp add_durative_action_to_domain(
         %{durative_actions: durative_actions, task_methods: methods} = domain,
         name,
         durative_action,
         _metadata
       ) do
    updated_durative_actions = Map.put(durative_actions, name, durative_action)
    task_name = Atom.to_string(name)
    primitive_method_fn = fn _state, args -> [{name, args}] end
    method_name = "primitive_#{task_name}"
    primitive_method = {method_name, primitive_method_fn}
    current_methods = Map.get(methods, task_name, [])
    updated_methods = [primitive_method | current_methods]
    updated_task_methods = Map.put(methods, task_name, updated_methods)
    %{domain | durative_actions: updated_durative_actions, task_methods: updated_task_methods}
  end

  @doc "Adds multiple actions to the domain.\n\nEach action will be properly registered with its corresponding task method.\n`new_actions` can be a map of `%{action_name => action_fn}` or `%{action_name => {action_fn, metadata}}`.\n"
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

  @doc "Gets an action function by name.\n"
  @spec get_action(t(), action_name()) :: action_fn() | nil
  def get_action(%{actions: actions}, name) do
    Map.get(actions, name)
  end

  @doc "Gets metadata for a given action.\n"
  @spec get_action_metadata(t(), action_name()) :: map() | nil
  def get_action_metadata(%{action_metadata: action_metadata}, name) do
    Map.get(action_metadata, name)
  end

  @doc "Checks if an action exists in the domain.\n"
  @spec has_action?(t(), action_name()) :: boolean()
  def has_action?(%{actions: actions}, name) do
    Map.has_key?(actions, name)
  end

  @doc "Executes an action with the given state and arguments.\n"
  @spec execute_action(t(), AriaEngine.State.t(), action_name(), list()) ::
          {:ok, AriaEngine.State.t()} | false
  def execute_action(%{} = domain, %AriaEngine.State{} = state, action_name, args) do
    case get_action(domain, action_name) do
      nil ->
        case Domain.Core.get_durative_action(domain, action_name) do
          nil ->
            false

          durative_action ->
            if validate_durative_preconditions(durative_action, state) do
              case durative_action.action_fn.(state, args) do
                false -> false
                %AriaEngine.State{} = new_state -> {:ok, new_state}
              end
            else
              false
            end
        end

      action_fn ->
        cond do
          is_function(action_fn, 2) ->
            case action_fn.(state, args) do
              false -> false
              %AriaEngine.State{} = new_state -> {:ok, new_state}
            end

          match?(%Domain.DurativeAction{}, action_fn) ->
            if validate_durative_preconditions(action_fn, state) do
              case action_fn.action_fn.(state, args) do
                false -> false
                %AriaEngine.State{} = new_state -> {:ok, new_state}
              end
            else
              false
            end

          true ->
            false
        end
    end
  end

  @spec validate_durative_preconditions(Domain.DurativeAction.t(), AriaEngine.State.t()) ::
          boolean()
  defp validate_durative_preconditions(durative_action, state) do
    at_start_valid =
      Enum.all?(durative_action.conditions.at_start, fn condition ->
        validate_temporal_condition(condition, state)
      end)

    over_all_valid =
      Enum.all?(durative_action.conditions.over_all, fn condition ->
        validate_temporal_condition(condition, state)
      end)

    at_end_valid =
      Enum.all?(durative_action.conditions.at_end, fn condition ->
        validate_temporal_condition(condition, state)
      end)

    at_start_valid and over_all_valid and at_end_valid
  end

  @spec validate_temporal_condition(tuple(), AriaEngine.State.t()) :: boolean()
  defp validate_temporal_condition(condition, state) do
    case condition do
      {:exists, _subject_filter, _predicate, _fact_value} ->
        State.evaluate_condition(state, condition)

      {:forall, _subject_filter, _predicate, _fact_value} ->
        State.evaluate_condition(state, condition)

      {entity, predicate, required_value} ->
        AriaEngine.State.get_fact(state, entity, predicate) == required_value

      _ ->
        State.evaluate_condition(state, condition)
    end
  end
end