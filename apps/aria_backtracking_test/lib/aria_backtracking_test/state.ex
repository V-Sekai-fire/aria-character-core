# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBacktrackingTest.State do
  @moduledoc """
  State management for backtracking tests.

  Provides a simple wrapper around AriaState.RelationalState with
  convenience functions for flag manipulation used in backtracking tests.
  """

  @doc """
  Creates a new state with default flag value of -1.
  """
  @spec new() :: AriaState.RelationalState.t()
  def new() do
    AriaState.RelationalState.new()
    |> AriaState.RelationalState.set_fact("system", "flag", -1)
  end

  @doc """
  Creates a new state with specified flag value.
  """
  @spec new(integer()) :: AriaState.RelationalState.t()
  def new(flag_value) when is_integer(flag_value) do
    AriaState.RelationalState.new()
    |> AriaState.RelationalState.set_fact("system", "flag", flag_value)
  end

  @doc """
  Gets the current flag value from state.
  """
  @spec get_flag(AriaState.RelationalState.t()) :: integer()
  def get_flag(state) do
    AriaState.RelationalState.get_fact(state, "system", "flag") || -1
  end

  @doc """
  Sets the flag value in state.
  """
  @spec set_flag(AriaState.RelationalState.t(), integer()) :: AriaState.RelationalState.t()
  def set_flag(state, flag_value) when is_integer(flag_value) do
    AriaState.RelationalState.set_fact(state, "system", "flag", flag_value)
  end

  @doc """
  Converts state to a simple map for inspection.
  """
  @spec to_map(AriaState.RelationalState.t()) :: map()
  def to_map(state) do
    %{
      flag: get_flag(state),
      all_facts: AriaState.RelationalState.all_facts(state)
    }
  end
end
