# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaActions.StateProvider do
  @moduledoc """
  Behavior for state manipulation providers in AriaActions.

  This provides a decoupled way for AriaActions to manipulate state
  without directly depending on AriaEngine.State, preventing circular dependencies.
  """

  @type state :: any()
  @type key :: String.t()
  @type object :: String.t()
  @type value :: any()

  @doc """
  Get an object value from state.
  """
  @callback get_object(state, key, object) :: value

  @doc """
  Set an object value in state.
  """
  @callback set_object(state, key, object, value) :: state

  @doc """
  Create a new empty state.
  """
  @callback new() :: state

  @doc """
  Get the configured state provider module.
  """
  @spec get_provider() :: module()
  def get_provider do
    Application.get_env(:aria_actions, :state_provider, AriaActions.DefaultStateProvider)
  end

  @doc """
  Get an object value from state using the configured provider.
  """
  @spec get_object(state, key, object) :: value
  def get_object(state, key, object) do
    provider = get_provider()
    provider.get_object(state, key, object)
  end

  @doc """
  Set an object value in state using the configured provider.
  """
  @spec set_object(state, key, object, value) :: state
  def set_object(state, key, object, value) do
    provider = get_provider()
    provider.set_object(state, key, object, value)
  end

  @doc """
  Create a new empty state using the configured provider.
  """
  @spec new() :: state
  def new do
    provider = get_provider()
    provider.new()
  end
end
