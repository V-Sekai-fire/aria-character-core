# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Domain.Actions do
  @moduledoc """
  Mock implementation of AriaEngineCore.Domain.Actions for compilation.

  This module provides action management functionality for domains.
  Currently mocked with basic functionality to enable compilation.
  """

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
  @spec get_action_metadata(map(), String.t()) :: map()
  def get_action_metadata(domain, name) do
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
  @spec execute_action(map(), term(), String.t(), list()) :: {:ok, term()} | {:error, String.t()}
  def execute_action(domain, state, action_name, args) do
    case get_action(domain, action_name) do
      nil ->
        {:error, "Action #{action_name} not found"}
      action_fn when is_function(action_fn) ->
        try do
          case Function.info(action_fn, :arity) do
            {:arity, 2} -> action_fn.(state, args)
            {:arity, 1} -> action_fn.(state)
            _ -> {:ok, state}
          end
        rescue
          e -> {:error, "Action execution failed: #{inspect(e)}"}
        end
    end
  end
end
