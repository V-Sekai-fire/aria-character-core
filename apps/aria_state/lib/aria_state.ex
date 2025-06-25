# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaState do
  @moduledoc """
  State management for AriaEngine planning systems.

  This module provides two complementary state management APIs:

  - **ObjectState**: Entity-centric API for domain developers (public API)
  - **RelationalState**: Predicate-centric API for internal AriaEngine operations

  ## Public API (Domain Developers)

  Use `AriaState.ObjectState` for all domain development:

  ```elixir
  # Entity-centric, pipe-friendly API
  state = AriaState.ObjectState.new()
  |> AriaState.ObjectState.set_fact("chef_1", "status", "cooking")
  |> AriaState.ObjectState.set_fact("meal_001", "status", "in_progress")

  # Reading facts
  chef_status = AriaState.ObjectState.get_fact(state, "chef_1", "status")
  ```

  ## Internal API (AriaEngine)

  `AriaState.RelationalState` is used internally for performance-optimized queries:

  ```elixir
  # Predicate-centric queries for planning
  available_chefs = AriaState.RelationalState.get_subjects_with_fact(state, "status", "available")
  ```

  ## Architecture

  Both APIs operate on the same underlying data structure but provide different
  query patterns optimized for their respective use cases:

  - **ObjectState**: `{subject, predicate} -> value` (entity-first)
  - **RelationalState**: `{predicate, subject} -> value` (predicate-first)
  """

  # Delegate common operations to ObjectState for convenience
  defdelegate new(), to: AriaState.ObjectState
  defdelegate new(data), to: AriaState.ObjectState
  defdelegate get_fact(state, subject, predicate), to: AriaState.ObjectState
  defdelegate set_fact(state, subject, predicate, value), to: AriaState.ObjectState
  defdelegate remove_fact(state, subject, predicate), to: AriaState.ObjectState
  defdelegate has_subject?(state, subject), to: AriaState.ObjectState
  defdelegate get_subjects(state), to: AriaState.ObjectState
  defdelegate merge(state1, state2), to: AriaState.ObjectState
  defdelegate copy(state), to: AriaState.ObjectState

  @doc """
  Converts between ObjectState and RelationalState formats.

  This is primarily used internally when AriaEngine needs to switch
  between entity-centric and predicate-centric operations.
  """
  @spec convert(AriaState.ObjectState.t()) :: AriaState.RelationalState.t()
  @spec convert(AriaState.RelationalState.t()) :: AriaState.ObjectState.t()
  def convert(%AriaState.ObjectState{} = state) do
    AriaState.ObjectState.to_relational_state(state)
  end

  def convert(%AriaState.RelationalState{} = state) do
    AriaState.ObjectState.from_relational_state(state)
  end
end
