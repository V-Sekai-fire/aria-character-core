# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain.Core do
  @moduledoc """
  Local Domain.Core module for aria_hybrid_planner to replace AriaEngine.Domain.Core dependency.

  This module provides domain management functionality including actions, methods,
  and domain queries needed for HTN planning.
  """

  defstruct [
    :name,
    :actions,
    :task_methods,
    :unigoal_methods,
    :multigoal_methods,
    :durative_actions
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          actions: map(),
          task_methods: map(),
          unigoal_methods: map(),
          multigoal_methods: map(),
          durative_actions: map()
        }

  @doc """
  Create a new domain with the given name.
  """
  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{
      name: name,
      actions: %{},
      task_methods: %{},
      unigoal_methods: %{},
      multigoal_methods: %{},
      durative_actions: %{}
    }
  end

  @doc """
  Check if the domain has a specific action.
  """
  @spec has_action?(t(), atom()) :: boolean()
  def has_action?(domain, action_name) when is_atom(action_name) do
    Map.has_key?(domain.actions, action_name)
  end

  @doc """
  Get a durative action from the domain.
  """
  @spec get_durative_action(t(), atom()) :: map() | nil
  def get_durative_action(domain, action_name) when is_atom(action_name) do
    Map.get(domain.durative_actions, action_name)
  end

  @doc """
  Execute an action in the given state.
  """
  @spec execute_action(t(), State.t(), atom(), list()) ::
    {:ok, State.t()} | {:error, String.t()}
  def execute_action(domain, state, action_name, args) do
    case Map.get(domain.actions, action_name) do
      nil ->
        {:error, "Action #{action_name} not found in domain"}

      action_def ->
        try do
          # Simple action execution - apply effects to state
          case apply_action_effects(state, action_def, args) do
            {:ok, new_state} -> {:ok, new_state}
            {:error, reason} -> {:error, reason}
          end
        rescue
          e -> {:error, "Action execution failed: #{Exception.message(e)}"}
        end
    end
  end

  @doc """
  Get all available methods for a task.
  """
  @spec get_methods(t(), String.t()) :: [String.t()]
  def get_methods(domain, task_name) do
    Map.get(domain.task_methods, task_name, [])
  end

  @doc """
  Get all available task methods for a task (alias for get_methods).
  """
  @spec get_task_methods(t(), String.t()) :: [String.t()]
  def get_task_methods(domain, task_name) do
    get_methods(domain, task_name)
  end

  @doc """
  Get all available unigoal methods for a goal.
  """
  @spec get_unigoal_methods(t(), String.t()) :: [String.t()]
  def get_unigoal_methods(domain, predicate) do
    Map.get(domain.unigoal_methods, predicate, [])
  end

  @doc """
  Get all available multigoal methods.
  """
  @spec get_multigoal_methods(t()) :: [String.t()]
  def get_multigoal_methods(domain) do
    Map.keys(domain.multigoal_methods)
  end

  @doc """
  Add an action to the domain.
  """
  @spec add_action(t(), atom(), map()) :: t()
  def add_action(domain, action_name, action_def) do
    %{domain | actions: Map.put(domain.actions, action_name, action_def)}
  end

  @doc """
  Add a durative action to the domain.
  """
  @spec add_durative_action(t(), atom(), map()) :: t()
  def add_durative_action(domain, action_name, action_def) do
    %{domain | durative_actions: Map.put(domain.durative_actions, action_name, action_def)}
  end

  @doc """
  Add a task method to the domain.
  """
  @spec add_task_method(t(), String.t(), String.t(), function()) :: t()
  def add_task_method(domain, task_name, method_name, _method_func) do
    current_methods = Map.get(domain.task_methods, task_name, [])
    updated_methods = [method_name | current_methods]

    %{domain | task_methods: Map.put(domain.task_methods, task_name, updated_methods)}
  end

  @doc """
  Add a unigoal method to the domain.
  """
  @spec add_unigoal_method(t(), String.t(), String.t(), function()) :: t()
  def add_unigoal_method(domain, predicate, method_name, _method_func) do
    current_methods = Map.get(domain.unigoal_methods, predicate, [])
    updated_methods = [method_name | current_methods]

    %{domain | unigoal_methods: Map.put(domain.unigoal_methods, predicate, updated_methods)}
  end

  @doc """
  Add a multigoal method to the domain.
  """
  @spec add_multigoal_method(t(), String.t(), function()) :: t()
  def add_multigoal_method(domain, method_name, method_func) do
    %{domain | multigoal_methods: Map.put(domain.multigoal_methods, method_name, method_func)}
  end

  @doc """
  Get all actions in the domain.
  """
  @spec get_actions(t()) :: map()
  def get_actions(domain) do
    domain.actions
  end

  @doc """
  Get all durative actions in the domain.
  """
  @spec get_durative_actions(t()) :: map()
  def get_durative_actions(domain) do
    domain.durative_actions
  end

  @doc """
  Check if a task has methods available.
  """
  @spec has_methods?(t(), String.t()) :: boolean()
  def has_methods?(domain, task_name) do
    case Map.get(domain.task_methods, task_name) do
      nil -> false
      [] -> false
      _methods -> true
    end
  end

  @doc """
  Check if a predicate has unigoal methods available.
  """
  @spec has_unigoal_methods?(t(), String.t()) :: boolean()
  def has_unigoal_methods?(domain, predicate) do
    case Map.get(domain.unigoal_methods, predicate) do
      nil -> false
      [] -> false
      _methods -> true
    end
  end

  @doc """
  Validate domain structure and consistency.
  """
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(domain) do
    try do
      # Basic validation checks
      cond do
        is_nil(domain.name) or domain.name == "" ->
          {:error, "Domain must have a non-empty name"}

        not is_map(domain.actions) ->
          {:error, "Domain actions must be a map"}

        not is_map(domain.task_methods) ->
          {:error, "Domain task_methods must be a map"}

        not is_map(domain.unigoal_methods) ->
          {:error, "Domain unigoal_methods must be a map"}

        not is_map(domain.multigoal_methods) ->
          {:error, "Domain multigoal_methods must be a map"}

        true ->
          {:ok, domain}
      end
    rescue
      e -> {:error, "Domain validation failed: #{Exception.message(e)}"}
    end
  end

  # Private helper functions

  defp apply_action_effects(state, action_def, args) do
    # Simple effect application - this is a stub implementation
    # In a real domain, this would apply the action's effects to the state
    case action_def do
      %{effects: effects} when is_function(effects) ->
        try do
          new_state = effects.(state, args)
          {:ok, new_state}
        rescue
          e -> {:error, "Effect application failed: #{Exception.message(e)}"}
        end

      %{effects: effects} when is_list(effects) ->
        # Apply list of effects
        apply_effect_list(state, effects, args)

      _ ->
        # No effects defined, return state unchanged
        {:ok, state}
    end
  end

  defp apply_effect_list(state, effects, args) do
    try do
      final_state = Enum.reduce_while(effects, state, fn effect, current_state ->
        case apply_single_effect(current_state, effect, args) do
          {:ok, new_state} -> {:cont, new_state}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

      case final_state do
        {:error, reason} -> {:error, reason}
        state -> {:ok, state}
      end
    rescue
      e -> {:error, "Effect list application failed: #{Exception.message(e)}"}
    end
  end

  defp apply_single_effect(state, effect, args) do
    case effect do
      {predicate, subject, value} when is_binary(predicate) and is_binary(subject) ->
        # Apply fact change to state
        AriaHybridPlanner.State.set_fact(state, predicate, subject, value)

      effect_func when is_function(effect_func) ->
        try do
          new_state = effect_func.(state, args)
          {:ok, new_state}
        rescue
          e -> {:error, "Effect function failed: #{Exception.message(e)}"}
        end

      _ ->
        {:error, "Unknown effect format: #{inspect(effect)}"}
    end
  end
end
