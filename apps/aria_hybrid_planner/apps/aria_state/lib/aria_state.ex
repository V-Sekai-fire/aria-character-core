# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState do
  @moduledoc """
  State management for AriaEngine planning systems.

  This is a convenience module that delegates to ObjectState for the public API
  while also providing access to the internal RelationalState for AriaEngine.

  ## Public API (Domain Developers)

  Use this module (or AriaState.ObjectState directly) for all domain development:

  ```elixir
  # Entity-centric, pipe-friendly API
  state = AriaState.new()
  |> AriaState.set_fact("chef_1", "status", "cooking")
  |> AriaState.set_fact("meal_001", "status", "in_progress")
  |> AriaState.set_fact("oven_1", "temperature", 375)

  # Reading facts
  chef_status = AriaState.get_fact(state, "chef_1", "status")
  # => "cooking"
  ```

  ## Internal API (AriaEngine)

  AriaState.RelationalState is used internally for performance-optimized queries.

  ## Conversion Between Formats

  ```elixir
  # Convert ObjectState to RelationalState
  relational_state = AriaState.convert(object_state)

  # Convert RelationalState to ObjectState
  object_state = AriaState.convert(relational_state)
  ```
  """

  alias AriaState.ObjectState

  # Delegate to ObjectState for the public convenience API
  defdelegate new(), to: ObjectState
  defdelegate new(data), to: ObjectState
  defdelegate get_fact(state, subject, predicate), to: ObjectState
  defdelegate set_fact(state, subject, predicate, value), to: ObjectState
  defdelegate remove_fact(state, subject, predicate), to: ObjectState
  defdelegate get_subjects(state), to: ObjectState
  defdelegate get_subject_properties(state, subject), to: ObjectState
  defdelegate get_subjects_with_fact(state, predicate, fact_value), to: ObjectState
  defdelegate get_subjects_with_predicate(state, predicate), to: ObjectState
  defdelegate evaluate_condition(state, condition), to: ObjectState
  defdelegate to_triples(state), to: ObjectState
  defdelegate from_triples(triples), to: ObjectState
  defdelegate merge(state1, state2), to: ObjectState
  defdelegate copy(state), to: ObjectState

  # Functions needed by AriaCore - delegate to ObjectState with parameter reordering
  @doc "Checks if a specific predicate exists for a given subject (AriaCore compatibility)."
  def has_subject?(%ObjectState{} = state, predicate, subject) do
    ObjectState.has_predicate?(state, subject, predicate)
  end

  @doc "Checks if the state matches a specific predicate, subject, and fact_value pattern (AriaCore compatibility)."
  def matches?(%ObjectState{} = state, predicate, subject, fact_value) do
    ObjectState.matches?(state, subject, predicate, fact_value)
  end

  @doc "Evaluates existential quantifier (AriaCore compatibility)."
  def exists?(%ObjectState{} = state, predicate, fact_value, subject_filter \\ nil) do
    ObjectState.exists?(state, predicate, fact_value, subject_filter)
  end

  @doc "Evaluates universal quantifier (AriaCore compatibility)."
  def forall?(%ObjectState{} = state, predicate, fact_value, subject_filter) do
    ObjectState.forall?(state, predicate, fact_value, subject_filter)
  end

  @doc """
  Converts between AriaState.ObjectState and AriaState.RelationalState.

  ## Examples

  ```elixir
  # ObjectState to RelationalState
  object_state = AriaState.ObjectState.new()
  |> AriaState.ObjectState.set_fact("chef_1", "status", "cooking")

  relational_state = AriaState.convert(object_state)
  # => %AriaState.RelationalState{...}

  # RelationalState to ObjectState
  converted_back = AriaState.convert(relational_state)
  # => %AriaState.ObjectState{...}
  ```
  """
  @spec convert(ObjectState.t() | AriaState.RelationalState.t()) :: AriaState.RelationalState.t() | ObjectState.t()
  def convert(%ObjectState{} = object_state) do
    # Convert {subject, predicate} => value to {predicate, subject} => value
    relational_data =
      object_state.data
      |> Enum.map(fn {{subject, predicate}, value} -> {{predicate, subject}, value} end)
      |> Map.new()

    %AriaState.RelationalState{data: relational_data}
  end

  def convert(%AriaState.RelationalState{} = relational_state) do
    # Convert {predicate, subject} => value to {subject, predicate} => value
    object_data =
      relational_state.data
      |> Enum.map(fn {{predicate, subject}, value} -> {{subject, predicate}, value} end)
      |> Map.new()

    %ObjectState{data: object_data}
  end
end
