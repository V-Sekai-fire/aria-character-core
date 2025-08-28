# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.ObjectState do
  @moduledoc """
  Entity-centric state management using subject-predicate-fact triples.

  This module provides a public API for domain developers to manage world state
  using entity-first operations, where each fact is represented as
  {subject, predicate} -> fact_value.

  Example:
  ```elixir
  state = AriaState.ObjectState.new()
  |> AriaState.ObjectState.set_fact("player", "location", "room1")
  |> AriaState.ObjectState.set_fact("player", "has", "sword")

  AriaState.ObjectState.get_fact(state, "player", "location")
  # => "room1"
  ```
  """

  @type subject :: String.t()
  @type predicate :: String.t()
  @type fact_value :: any()
  @type entity_key :: {subject(), predicate()}
  @type t :: %__MODULE__{data: %{entity_key() => fact_value()}}

  defstruct data: %{}

  @doc "Creates a new empty object state."
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc "Creates a new object state from a map of subject-predicate-object data."
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    # Check if data is already in entity format {subject, predicate} => value
    if is_entity_format?(data) do
      %__MODULE__{data: data}
    else
      # Convert nested subject maps to entity format
      converted_data = convert_nested_maps_to_entities(data)
      %__MODULE__{data: converted_data}
    end
  end

  # Check if the data is already in entity format
  defp is_entity_format?(data) do
    data
    |> Map.keys()
    |> Enum.all?(fn
      {subject, predicate} when is_binary(subject) and is_binary(predicate) -> true
      _ -> false
    end)
  end

  # Convert nested subject maps to entity format
  defp convert_nested_maps_to_entities(data) do
    data
    |> Enum.flat_map(fn
      {subject, predicate_map} when is_map(predicate_map) ->
        subject_str = to_string(subject)
        Enum.map(predicate_map, fn {predicate, value} ->
          {{subject_str, to_string(predicate)}, value}
        end)

      {key, value} ->
        # Handle direct key-value pairs (already in some entity-like format)
        [{key, value}]
    end)
    |> Map.new()
  end

  @doc """
  Gets a specific fact from the state.

  ## Parameters

  - `state`: The object state
  - `subject`: The subject (entity) to look up
  - `predicate`: The predicate to look up

  ## Returns

  The fact value or `nil` if not found.

  ## Examples

      iex> state = AriaState.ObjectState.new()
      iex> state = AriaState.ObjectState.set_fact(state, "player", "location", "room1")
      iex> AriaState.ObjectState.get_fact(state, "player", "location")
      "room1"
  """
  @spec get_fact(t(), subject(), predicate()) :: fact_value() | nil
  def get_fact(%__MODULE__{data: data}, subject, predicate) do
    Map.get(data, {subject, predicate})
  end

  @doc """
  Sets a fact in the state.

  ## Parameters

  - `state`: The object state
  - `subject`: The subject (entity) to set
  - `predicate`: The predicate to set
  - `value`: The value to set

  ## Returns

  Updated state with the fact set.

  ## Examples

      iex> state = AriaState.ObjectState.new()
      iex> state = AriaState.ObjectState.set_fact(state, "player", "location", "room1")
      iex> AriaState.ObjectState.get_fact(state, "player", "location")
      "room1"
  """
  @spec set_fact(t(), subject(), predicate(), fact_value()) :: t()
  def set_fact(%__MODULE__{data: data}, subject, predicate, value) do
    %__MODULE__{data: Map.put(data, {subject, predicate}, value)}
  end

  @doc "Removes a fact from the state."
  @spec remove_fact(t(), subject(), predicate()) :: t()
  def remove_fact(%__MODULE__{data: data}, subject, predicate) do
    %__MODULE__{data: Map.delete(data, {subject, predicate})}
  end

  @doc "Checks if a predicate variable exists in any subject."
  @spec has_predicate_variable?(t(), predicate()) :: boolean()
  def has_predicate_variable?(%__MODULE__{data: data}, predicate) do
    data |> Map.keys() |> Enum.any?(fn {_subject, pred} -> pred == predicate end)
  end

  @doc "Checks if a specific predicate exists for a given subject."
  @spec has_predicate?(t(), subject(), predicate()) :: boolean()
  def has_predicate?(%__MODULE__{data: data}, subject, predicate) do
    Map.has_key?(data, {subject, predicate})
  end

  @doc "Gets a list of all subjects that have properties."
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(%__MODULE__{data: data}) do
    data |> Map.keys() |> Enum.map(fn {subject, _predicate} -> subject end) |> Enum.uniq()
  end

  @doc "Gets all predicates for a given subject."
  @spec get_subject_properties(t(), subject()) :: [predicate()]
  def get_subject_properties(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.filter(fn {subj, _predicate} -> subj == subject end)
    |> Enum.map(fn {_subj, predicate} -> predicate end)
  end

  @doc "Gets all triples as a list of {subject, predicate, fact_value} tuples."
  @spec to_triples(t()) :: [{subject(), predicate(), fact_value()}]
  def to_triples(%__MODULE__{data: data}) do
    Enum.map(data, fn {{subject, predicate}, fact_value} -> {subject, predicate, fact_value} end)
  end

  @doc "Gets all facts in the state as a map."
  @spec get_all_facts(t()) :: %{entity_key() => fact_value()}
  def get_all_facts(%__MODULE__{data: data}) do
    data
  end

  @doc """
  Gets all subjects that have a specific predicate with a specific fact_value.

  Example:
  ```elixir
  # Get all subjects with status "available"
  AriaState.ObjectState.get_subjects_with_fact(state, "status", "available")
  # => ["chef1", "chef3", "table2"]
  ```
  """
  @spec get_subjects_with_fact(t(), predicate(), fact_value()) :: [subject()]
  def get_subjects_with_fact(%__MODULE__{data: data}, predicate, fact_value) do
    data
    |> Enum.filter(fn {{_subj, pred}, val} -> pred == predicate and val == fact_value end)
    |> Enum.map(fn {{subj, _pred}, _val} -> subj end)
  end

  @doc """
  Gets all subjects that match a predicate pattern, regardless of fact_value.

  Example:
  ```elixir
  # Get all subjects that have a "location" predicate
  AriaState.ObjectState.get_subjects_with_predicate(state, "location")
  # => ["player", "npc1", "chest"]
  ```
  """
  @spec get_subjects_with_predicate(t(), predicate()) :: [subject()]
  def get_subjects_with_predicate(%__MODULE__{data: data}, predicate) do
    data
    |> Map.keys()
    |> Enum.filter(fn {_subj, pred} -> pred == predicate end)
    |> Enum.map(fn {subj, _pred} -> subj end)
    |> Enum.uniq()
  end

  @doc """
  Checks if the state matches a specific subject, predicate, and fact_value pattern.

  This function is used by the planner to check if a goal condition is satisfied
  in the current state. It returns true if the state contains the specified triple.
  """
  @spec matches?(t(), subject(), predicate(), fact_value()) :: boolean()
  def matches?(%__MODULE__{data: data}, subject, predicate, fact_value) do
    case Map.get(data, {subject, predicate}) do
      ^fact_value -> true
      _ -> false
    end
  end

  @doc """
  Evaluates existential quantifier: checks if there exists at least one subject
  that matches the given predicate and fact_value pattern.

  Example:
  ```elixir
  # Check if there exists any chair that is available
  AriaState.ObjectState.exists?(state, "status", "available", &String.contains?(&1, "chair"))
  ```
  """
  @spec exists?(t(), predicate(), fact_value(), (subject() -> boolean()) | nil) :: boolean()
  def exists?(%__MODULE__{data: data}, predicate, fact_value, subject_filter \\ nil) do
    data
    |> Enum.any?(fn
      {{subject, ^predicate}, ^fact_value} ->
        case subject_filter do
          nil -> true
          filter_fn when is_function(filter_fn, 1) -> filter_fn.(subject)
          _ -> false
        end

      _ ->
        false
    end)
  end

  @doc """
  Evaluates universal quantifier: checks if all subjects matching the pattern
  have the specified predicate and fact_value.

  Example:
  ```elixir
  # Check if all doors are locked
  AriaState.ObjectState.forall?(state, "status", "locked", &String.contains?(&1, "door"))
  ```
  """
  @spec forall?(t(), predicate(), fact_value(), (subject() -> boolean())) :: boolean()
  def forall?(%__MODULE__{data: data}, predicate, fact_value, subject_filter)
      when is_function(subject_filter, 1) do
    matching_subjects =
      data
      |> Map.keys()
      |> Enum.map(fn {subj, _pred} -> subj end)
      |> Enum.uniq()
      |> Enum.filter(subject_filter)

    if Enum.empty?(matching_subjects) do
      true
    else
      Enum.all?(matching_subjects, fn subject ->
        matches?(%__MODULE__{data: data}, subject, predicate, fact_value)
      end)
    end
  end

  @doc """
  Evaluates a quantified condition structure.

  Supports both existential and universal quantifiers with flexible condition patterns.

  ## Condition Format
  ```elixir
  # Existential quantifier
  {:exists, subject_filter, predicate, fact_value}

  # Universal quantifier
  {:forall, subject_filter, predicate, fact_value}

  # Regular condition (backward compatibility)
  {subject, predicate, fact_value}
  ```

  ## Examples
  ```elixir
  # Check if any chair is available
  condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
  AriaState.ObjectState.evaluate_condition(state, condition)

  # Check if all doors are locked
  condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
  AriaState.ObjectState.evaluate_condition(state, condition)

  # Regular condition check
  condition = {"player", "location", "room1"}
  AriaState.ObjectState.evaluate_condition(state, condition)
  ```
  """
  @spec evaluate_condition(t(), tuple()) :: boolean()
  def evaluate_condition(state, condition)

  def evaluate_condition(state, {:exists, subject_filter, predicate, fact_value}) do
    exists?(state, predicate, fact_value, subject_filter)
  end

  def evaluate_condition(state, {:forall, subject_filter, predicate, fact_value}) do
    forall?(state, predicate, fact_value, subject_filter)
  end

  def evaluate_condition(state, {subject, predicate, fact_value}) do
    matches?(state, subject, predicate, fact_value)
  end

  def evaluate_condition(_state, condition) do
    if Mix.env() == :dev or (Mix.env() == :test and ExUnit.configuration()[:trace]) do
      require Logger
      Logger.warning("Unknown condition format: #{inspect(condition)}")
    end

    false
  end

  @doc "Creates a state from a list of triples."
  @spec from_triples([{subject(), predicate(), fact_value()}]) :: t()
  def from_triples(triples) do
    data =
      triples
      |> Enum.map(fn {subject, predicate, fact_value} -> {{subject, predicate}, fact_value} end)
      |> Map.new()

    %__MODULE__{data: data}
  end

  @doc "Merges two states, with the second state taking precedence for conflicts."
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: Map.merge(data1, data2)}
  end

  @doc "Returns a copy of the state with modified data."
  @spec copy(t()) :: t()
  def copy(%__MODULE__{data: data}) do
    %__MODULE__{data: Map.new(data)}
  end
end
