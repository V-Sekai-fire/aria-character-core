# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionExecution do
  @moduledoc """
  Action execution implementation migrated from AriaEngineCore.Domain.Actions.

  This module provides action management and execution functionality for domains,
  now properly located in AriaCore following umbrella app architectural boundaries.
  """

  require Logger

  @doc """
  Add an action to a domain.
  """
  @spec add_action(map(), String.t(), function(), map()) :: map()
  def add_action(domain, name, action_fn, metadata \\ %{}) do
    actions = Map.get(domain, :actions, %{})
    action_data = %{function: action_fn, metadata: metadata}
    updated_actions = Map.put(actions, name, action_data)
    Map.put(domain, :actions, updated_actions)
  end

  @doc """
  Add multiple actions to a domain.
  """
  @spec add_actions(map(), map()) :: map()
  def add_actions(domain, new_actions) do
    Enum.reduce(new_actions, domain, fn {name, action_data}, acc_domain ->
      case action_data do
        %{function: action_fn, metadata: metadata} ->
          add_action(acc_domain, name, action_fn, metadata)
        action_fn when is_function(action_fn) ->
          add_action(acc_domain, name, action_fn, %{})
        _ ->
          add_action(acc_domain, name, fn _state, _args -> {:ok, %{}} end, %{})
      end
    end)
  end

  @doc """
  Get an action from a domain.
  """
  @spec get_action(map(), String.t()) :: function() | nil
  def get_action(domain, name) do
    domain
    |> Map.get(:actions, %{})
    |> Map.get(name)
    |> case do
      %{function: action_fn} -> action_fn
      action_fn when is_function(action_fn) -> action_fn
      _ -> nil
    end
  end

  @doc """
  Get action metadata from a domain.
  """
  @spec get_action_metadata(map(), atom()) :: map()
  def get_action_metadata(domain, name) when is_atom(name) do
    domain
    |> Map.get(:actions, %{})
    |> Map.get(name)
    |> case do
      %{metadata: metadata} -> metadata
      _ -> %{}
    end
  end

  @doc """
  Check if domain has an action.
  """
  @spec has_action?(map(), String.t()) :: boolean()
  def has_action?(domain, name) do
    domain
    |> Map.get(:actions, %{})
    |> Map.has_key?(name)
  end

  @doc """
  Execute an action in a domain.
  """
  @spec execute_action(map(), term(), String.t() | atom(), list()) :: {:ok, term()} | {:error, String.t()}
  def execute_action(domain, state, action_name, args) when is_atom(action_name) do
    execute_action(domain, state, Atom.to_string(action_name), args)
  end

  def execute_action(domain, state, action_name, args) when is_binary(action_name) do
    case get_action(domain, action_name) do
      nil ->
        {:error, "Action #{action_name} not found"}
      action_fn when is_function(action_fn) ->
        try do
          case Function.info(action_fn, :arity) do
            {:arity, 2} ->
              result = action_fn.(state, args)
              case result do
                false -> {:error, "Action #{action_name} failed"}
                {:ok, new_state} -> {:ok, new_state}
                {:error, reason} -> {:error, "Action #{action_name} failed: #{reason}"}
                new_state -> {:ok, new_state}
              end
            {:arity, 1} ->
              result = action_fn.(state)
              case result do
                false -> {:error, "Action #{action_name} failed"}
                {:ok, new_state} -> {:ok, new_state}
                {:error, reason} -> {:error, "Action #{action_name} failed: #{reason}"}
                new_state -> {:ok, new_state}
              end
            _ ->
              {:ok, state}
          end
        rescue
          e -> {:error, "Action execution failed: #{inspect(e)}"}
        end
    end
  end

  @doc """
  List all action names in a domain.
  """
  @spec list_actions(map()) :: list()
  def list_actions(domain) do
    domain
    |> Map.get(:actions, %{})
    |> Map.keys()
  end

  @doc """
  Remove an action from a domain.
  """
  @spec remove_action(map(), String.t()) :: map()
  def remove_action(domain, name) do
    actions = Map.get(domain, :actions, %{})
    updated_actions = Map.delete(actions, name)
    Map.put(domain, :actions, updated_actions)
  end

  @doc """
  Update action metadata for an existing action.
  """
  @spec update_action_metadata(map(), String.t(), map()) :: map()
  def update_action_metadata(domain, name, new_metadata) do
    actions = Map.get(domain, :actions, %{})
    case Map.get(actions, name) do
      nil ->
        domain  # Action doesn't exist, return unchanged
      %{function: action_fn, metadata: _old_metadata} ->
        updated_action = %{function: action_fn, metadata: new_metadata}
        updated_actions = Map.put(actions, name, updated_action)
        Map.put(domain, :actions, updated_actions)
      action_fn when is_function(action_fn) ->
        updated_action = %{function: action_fn, metadata: new_metadata}
        updated_actions = Map.put(actions, name, updated_action)
        Map.put(domain, :actions, updated_actions)
    end
  end

  @doc """
  Get all actions with their metadata.
  """
  @spec get_all_actions_with_metadata(map()) :: map()
  def get_all_actions_with_metadata(domain) do
    Map.get(domain, :actions, %{})
  end

  @doc """
  Validate that all actions in a domain have valid function signatures.
  """
  @spec validate_actions(map()) :: :ok | {:error, String.t()}
  def validate_actions(domain) do
    actions = Map.get(domain, :actions, %{})

    Enum.reduce_while(actions, :ok, fn {name, action_data}, _acc ->
      case validate_single_action(name, action_data) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Private helper functions

  defp validate_single_action(name, %{function: action_fn}) when is_function(action_fn) do
    case Function.info(action_fn, :arity) do
      {:arity, arity} when arity in [1, 2] -> :ok
      {:arity, arity} -> {:error, "Action #{name} has invalid arity #{arity}, expected 1 or 2"}
      _ -> {:error, "Action #{name} has invalid function"}
    end
  end

  defp validate_single_action(name, action_fn) when is_function(action_fn) do
    validate_single_action(name, %{function: action_fn})
  end

  defp validate_single_action(name, _invalid) do
    {:error, "Action #{name} is not a valid function"}
  end
end
