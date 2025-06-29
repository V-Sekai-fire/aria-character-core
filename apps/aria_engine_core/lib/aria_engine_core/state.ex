# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.State do
  @moduledoc """
  Represents the state of a planning problem using predicate-subject-fact triples.

  This module provides functionality to manage world state by delegating to
  `AriaState.RelationalState`, aligning with ADR R25W1398085.

  ## Usage

      # All functions delegate to AriaState.RelationalState
      state = AriaEngineCore.State.new()
      |> AriaEngineCore.State.set_fact("location", "player", "room1")
      |> AriaEngineCore.State.set_fact("has", "player", "sword")

      AriaEngineCore.State.get_fact(state, "location", "player")
      # => "room1"
  """
  @type predicate :: String.t()
  @type subject :: String.t()
  @type fact_value :: any()
  @type t :: AriaState.RelationalState.t()

  alias AriaState.RelationalState

  @doc "Creates a new empty planning state."
  @spec new() :: t()
  def new do
    RelationalState.new()
  end

  @doc "Creates a new planning state from a map of predicate-subject-fact data."
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    RelationalState.new(data)
  end

  @doc "Gets the fact_value for a given predicate and subject. Returns nil if the triple doesn't exist."
  @spec get_fact(t(), predicate(), subject()) :: fact_value() | nil
  def get_fact(state, predicate, subject) do
    RelationalState.get_fact(state, predicate, subject)
  end

  @doc "Sets the fact_value for a given predicate and subject."
  @spec set_fact(t(), predicate(), subject(), fact_value()) :: t()
  def set_fact(state, predicate, subject, fact_value) do
    RelationalState.set_fact(state, predicate, subject, fact_value)
  end

  defdelegate has_subject?(state, predicate, subject), to: RelationalState
  defdelegate get_subjects_with_fact(state, predicate, fact_value), to: RelationalState

  @doc "Removes a triple from the state."
  @spec remove_fact(t(), predicate(), subject()) :: t()
  def remove_fact(state, predicate, subject) do
    RelationalState.remove_fact(state, predicate, subject)
  end

  @doc "Checks if a subject has a given predicate with any object."
  @spec has_subject?(t(), predicate(), subject()) :: boolean()
  def has_subject?(state, predicate, subject) do
    RelationalState.has_subject?(state, predicate, subject)
  end

  @doc "Checks if a subject variable exists in any predicate."
  @spec has_subject_variable?(t(), subject()) :: boolean()
  def has_subject_variable?(state, subject) do
    RelationalState.has_subject_variable?(state, subject)
  end

  @doc "Gets a list of all subjects that have properties."
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(state) do
    RelationalState.get_subjects(state)
  end

  @doc "Gets all predicates for a given subject."
  @spec get_subject_properties(t(), subject()) :: [predicate()]
  def get_subject_properties(state, subject) do
    RelationalState.get_subject_properties(state, subject)
  end

  @doc "Gets all triples as a list of {predicate, subject, fact_value} tuples."
  @spec to_triples(t()) :: [{predicate(), subject(), fact_value()}]
  def to_triples(state) do
    RelationalState.to_triples(state)
  end

  @doc "Creates a state from a list of triples."
  @spec from_triples([{predicate(), subject(), fact_value()}]) :: t()
  def from_triples(triples) do
    RelationalState.from_triples(triples)
  end

  @doc "Merges two states, with the second state taking precedence for conflicts."
  @spec merge(t(), t()) :: t()
  def merge(state1, state2) do
    RelationalState.merge(state1, state2)
  end

  @doc "Returns a copy of the state with modified data."
  @spec copy(t()) :: t()
  def copy(state) do
    RelationalState.copy(state)
  end

  @doc "Checks if the state matches a specific predicate, subject, and fact_value pattern."
  @spec matches?(t(), predicate(), subject(), fact_value()) :: boolean()
  def matches?(state, predicate, subject, fact_value) do
    RelationalState.matches?(state, predicate, subject, fact_value)
  end

  @doc "Evaluates existential quantifier: checks if there exists at least one subject that matches the given predicate and fact_value pattern."
  @spec exists?(t(), predicate(), fact_value(), (subject() -> boolean()) | nil) :: boolean()
  def exists?(state, predicate, fact_value, subject_filter \\ nil) do
    RelationalState.exists?(state, predicate, fact_value, subject_filter)
  end

  @doc "Evaluates universal quantifier: checks if all subjects matching the pattern have the specified predicate and fact_value."
  @spec forall?(t(), predicate(), fact_value(), (subject() -> boolean())) :: boolean()
  def forall?(state, predicate, fact_value, subject_filter) when is_function(subject_filter, 1) do
    RelationalState.forall?(state, predicate, fact_value, subject_filter)
  end

  @doc "Gets all subjects that have a specific predicate with a specific fact_value."
  @spec get_subjects_with_fact(t(), predicate(), fact_value()) :: [subject()]
  def get_subjects_with_fact(state, predicate, fact_value) do
    RelationalState.get_subjects_with_fact(state, predicate, fact_value)
  end

  @doc "Gets all subjects that match a predicate pattern, regardless of fact_value."
  @spec get_subjects_with_predicate(t(), predicate()) :: [subject()]
  def get_subjects_with_predicate(state, predicate) do
    RelationalState.get_subjects_with_predicate(state, predicate)
  end

  @doc "Evaluates a quantified condition structure."
  @spec evaluate_condition(t(), tuple()) :: boolean()
  def evaluate_condition(state, condition) do
    RelationalState.evaluate_condition(state, condition)
  end
end
