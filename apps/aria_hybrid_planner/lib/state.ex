# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule State do
  @moduledoc """
  Generic state interface for aria_hybrid_planner.

  This module provides a generic interface that can work with any state
  implementation that provides the basic state operations needed for planning.
  """

  @type t :: any()
  @type predicate :: String.t()
  @type subject :: String.t()
  @type fact_value :: any()

  @doc """
  Get a fact from the state.
  """
  @spec get_fact(t(), predicate(), subject()) :: fact_value() | nil
  def get_fact(state, predicate, subject) do
    # Delegate to the actual state implementation
    state.__struct__.get_fact(state, predicate, subject)
  end

  @doc """
  Set a fact in the state.
  """
  @spec set_fact(t(), predicate(), subject(), fact_value()) :: t()
  def set_fact(state, predicate, subject, fact_value) do
    # Delegate to the actual state implementation
    state.__struct__.set_fact(state, predicate, subject, fact_value)
  end

  @doc """
  Check if the state matches a condition.
  """
  @spec matches?(t(), predicate(), subject(), fact_value()) :: boolean()
  def matches?(state, predicate, subject, fact_value) do
    # Delegate to the actual state implementation
    state.__struct__.matches?(state, predicate, subject, fact_value)
  end

  @doc """
  Copy the state.
  """
  @spec copy(t()) :: t()
  def copy(state) do
    # Delegate to the actual state implementation
    state.__struct__.copy(state)
  end
end
