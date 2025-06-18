# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StateV2 do
  @moduledoc """
  Modernized state management using subject-predicate-fact triples for entity-centric architecture.
  
  This module provides functionality to manage world state using entity-first RDF-like triples,
  where each fact is represented as {subject, predicate} -> fact_value.
  
  This design supports the Entity Timeline Graph Architecture (ADR-087) by making entities
  the primary organizational unit, with natural API patterns like:
  
  ```elixir
  state = AriaEngine.StateV2.new()
  |> AriaEngine.StateV2.set_fact("player", "location", "room1")
  |> AriaEngine.StateV2.set_fact("player", "has", "sword")
  
  AriaEngine.StateV2.get_fact(state, "player", "location")
  # => "room1"
  ```
  
  This entity-first approach aligns with game networking ECS patterns and supports
  the timeline-per-entity architecture defined in ADR-087.
  """

  @type subject :: String.t()
  @type predicate :: String.t()
  @type fact_value :: any()
  @type triple_key :: {subject(), predicate()}
  @type t :: %__MODULE__{
    data: %{triple_key() => fact_value()}
  }

  defstruct data: %{}

  @doc """
  Creates a new empty planning state.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a new planning state from a map of subject-predicate-object data.
  """
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    %__MODULE__{data: data}
  end

  @doc """
  Gets the fact_value for a given subject and predicate.
  Returns nil if the triple doesn't exist.
  
  Entity-first API: get_fact(state, subject, predicate)
  """
  @spec get_fact(t(), subject(), predicate()) :: fact_value() | nil
  def get_fact(%__MODULE__{data: data}, subject, predicate) do
    Map.get(data, {subject, predicate})
  end

  @doc """
  Sets the fact_value for a given subject and predicate.
  
  Entity-first API: set_fact(state, subject, predicate, fact_value)
  """
  @spec set_fact(t(), subject(), predicate(), fact_value()) :: t()
  def set_fact(%__MODULE__{data: data} = state, subject, predicate, fact_value) do
    %{state | data: Map.put(data, {subject, predicate}, fact_value)}
  end

  @doc """
  Alias for set_fact/4 for backward compatibility.
  
  Entity-first API: update_fact(state, subject, predicate, fact_value)
  """
  @spec update_fact(t(), subject(), predicate(), fact_value()) :: t()
  def update_fact(%__MODULE__{} = state, subject, predicate, fact_value) do
    set_fact(state, subject, predicate, fact_value)
  end

  @doc """
  Alias for set_fact/4 for backward compatibility.
  
  Entity-first API: add_fact(state, predicate, subject, fact_value)
  Note: Parameters are in different order for legacy compatibility.
  """
  @spec add_fact(t(), predicate(), subject(), fact_value()) :: t()
  def add_fact(%__MODULE__{} = state, predicate, subject, fact_value) do
    set_fact(state, subject, predicate, fact_value)
  end

  @doc """
  Removes a triple from the state.
  
  Entity-first API: remove_fact(state, subject, predicate)
  """
  @spec remove_fact(t(), subject(), predicate()) :: t()
  def remove_fact(%__MODULE__{data: data} = state, subject, predicate) do
    %{state | data: Map.delete(data, {subject, predicate})}
  end

  @doc """
  Checks if a subject has a given predicate with any fact_value.
  
  Entity-first API: has_predicate?(state, subject, predicate)
  """
  @spec has_predicate?(t(), subject(), predicate()) :: boolean()
  def has_predicate?(%__MODULE__{data: data}, subject, predicate) do
    Map.has_key?(data, {subject, predicate})
  end

  @doc """
  Checks if a subject exists in the state (has any predicates).
  """
  @spec has_subject?(t(), subject()) :: boolean()
  def has_subject?(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.any?(fn {subj, _predicate} -> subj == subject end)
  end

  @doc """
  Gets a list of all subjects that have properties.
  """
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(%__MODULE__{data: data}) do
    data
    |> Map.keys()
    |> Enum.map(fn {subject, _predicate} -> subject end)
    |> Enum.uniq()
  end

  @doc """
  Gets all predicates for a given subject.
  
  Entity-first API: get_predicates(state, subject)
  """
  @spec get_predicates(t(), subject()) :: [predicate()]
  def get_predicates(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.filter(fn {subj, _predicate} -> subj == subject end)
    |> Enum.map(fn {_subj, predicate} -> predicate end)
  end

  @doc """
  Gets all properties for a given subject as a map.
  
  Entity-first API: get_properties(state, subject)
  """
  @spec get_properties(t(), subject()) :: %{predicate() => fact_value()}
  def get_properties(%__MODULE__{data: data}, subject) do
    data
    |> Enum.filter(fn {{subj, _predicate}, _value} -> subj == subject end)
    |> Enum.map(fn {{_subj, predicate}, value} -> {predicate, value} end)
    |> Map.new()
  end

  @doc """
  Gets all triples as a list of {subject, predicate, fact_value} tuples.
  """
  @spec to_triples(t()) :: [{subject(), predicate(), fact_value()}]
  def to_triples(%__MODULE__{data: data}) do
    Enum.map(data, fn {{subject, predicate}, fact_value} ->
      {subject, predicate, fact_value}
    end)
  end

  @doc """
  Creates a state from a list of triples.
  """
  @spec from_triples([{subject(), predicate(), fact_value()}]) :: t()
  def from_triples(triples) do
    data = 
      triples
      |> Enum.map(fn {subject, predicate, fact_value} -> 
        {{subject, predicate}, fact_value} 
      end)
      |> Map.new()
    
    %__MODULE__{data: data}
  end

  @doc """
  Merges two states, with the second state taking precedence for conflicts.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: Map.merge(data1, data2)}
  end

  @doc """
  Returns a copy of the state with modified data.
  """
  @spec copy(t()) :: t()
  def copy(%__MODULE__{data: data}) do
    %__MODULE__{data: Map.new(data)}
  end

  @doc """
  Checks if the state matches a specific subject, predicate, and fact_value pattern.
  
  Entity-first API: matches?(state, subject, predicate, fact_value)
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
  that matches the given subject_filter, predicate, and fact_value pattern.
  
  Entity-first API: exists?(state, subject_filter, predicate, fact_value)
  
  Example:
  ```elixir
  # Check if there exists any chair that is available
  StateV2.exists?(state, &String.contains?(&1, "chair"), "status", "available")
  ```
  """
  @spec exists?(t(), (subject() -> boolean()) | nil, predicate(), fact_value()) :: boolean()
  def exists?(%__MODULE__{data: data}, subject_filter, predicate, fact_value) do
    data
    |> Enum.any?(fn
      {{subject, ^predicate}, ^fact_value} ->
        case subject_filter do
          nil -> true
          filter_fn when is_function(filter_fn, 1) -> filter_fn.(subject)
          _ -> false
        end
      _ -> false
    end)
  end

  @doc """
  Evaluates universal quantifier: checks if all subjects matching the pattern
  have the specified predicate and fact_value.
  
  Entity-first API: forall?(state, subject_filter, predicate, fact_value)
  
  Example:
  ```elixir
  # Check if all doors are locked
  StateV2.forall?(state, &String.contains?(&1, "door"), "status", "locked")
  ```
  """
  @spec forall?(t(), (subject() -> boolean()), predicate(), fact_value()) :: boolean()
  def forall?(%__MODULE__{data: data}, subject_filter, predicate, fact_value) 
      when is_function(subject_filter, 1) do
    # Find all subjects that match the filter
    matching_subjects = 
      data
      |> Map.keys()
      |> Enum.map(fn {subj, _pred} -> subj end)
      |> Enum.uniq()
      |> Enum.filter(subject_filter)
    
    # If no subjects match the filter, vacuous truth applies (return true)
    if Enum.empty?(matching_subjects) do
      true
    else
      # Check that ALL matching subjects have the required predicate-value
      Enum.all?(matching_subjects, fn subject ->
        matches?(%__MODULE__{data: data}, subject, predicate, fact_value)
      end)
    end
  end

  @doc """
  Gets all subjects that have a specific predicate with a specific fact_value.
  
  Example:
  ```elixir
  # Get all subjects with status "available"
  StateV2.get_subjects_with_fact(state, "status", "available")
  # => ["chair1", "chair3", "table2"]
  ```
  """
  @spec get_subjects_with_fact(t(), predicate(), fact_value()) :: [subject()]
  def get_subjects_with_fact(%__MODULE__{data: data}, predicate, fact_value) do
    data
    |> Enum.filter(fn {{_subj, pred}, val} -> 
      pred == predicate and val == fact_value 
    end)
    |> Enum.map(fn {{subj, _pred}, _val} -> subj end)
  end

  @doc """
  Gets all subjects that match a predicate pattern, regardless of fact_value.
  
  Example:
  ```elixir
  # Get all subjects that have a "location" predicate
  StateV2.get_subjects_with_predicate(state, "location")
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
  Evaluates a quantified condition structure using entity-first patterns.
  
  Supports both existential and universal quantifiers with flexible condition patterns.
  
  ## Condition Format
  ```elixir
  # Existential quantifier (entity-first)
  {:exists, subject_filter, predicate, fact_value}
  
  # Universal quantifier (entity-first)
  {:forall, subject_filter, predicate, fact_value}
  
  # Regular condition (entity-first)
  {subject, predicate, fact_value}
  ```
  
  ## Examples
  ```elixir
  # Check if any chair is available
  condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
  StateV2.evaluate_condition(state, condition)
  
  # Check if all doors are locked
  condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
  StateV2.evaluate_condition(state, condition)
  
  # Regular condition check (entity-first)
  condition = {"player", "location", "room1"}
  StateV2.evaluate_condition(state, condition)
  ```
  """
  @spec evaluate_condition(t(), tuple()) :: boolean()
  def evaluate_condition(state, condition)

  def evaluate_condition(state, {:exists, subject_filter, predicate, fact_value}) do
    exists?(state, subject_filter, predicate, fact_value)
  end

  def evaluate_condition(state, {:forall, subject_filter, predicate, fact_value}) do
    forall?(state, subject_filter, predicate, fact_value)
  end

  def evaluate_condition(state, {subject, predicate, fact_value}) do
    matches?(state, subject, predicate, fact_value)
  end

  def evaluate_condition(_state, condition) do
    require Logger
    Logger.warning("Unknown condition format: #{inspect(condition)}")
    false
  end

  @doc """
  Converts from legacy State format to StateV2 format.
  
  This function helps with migration from the old {predicate, subject} format
  to the new entity-first {subject, predicate} format.
  """
  @spec from_legacy_state(AriaEngine.State.t()) :: t()
  def from_legacy_state(%AriaEngine.State{data: legacy_data}) do
    converted_data = 
      legacy_data
      |> Enum.map(fn {{predicate, subject}, fact_value} ->
        {{subject, predicate}, fact_value}
      end)
      |> Map.new()
    
    %__MODULE__{data: converted_data}
  end

  @doc """
  Converts to legacy State format for backward compatibility.
  
  This function helps with migration by allowing StateV2 to be used
  with existing code that expects the old format.
  """
  @spec to_legacy_state(t()) :: AriaEngine.State.t()
  def to_legacy_state(%__MODULE__{data: data}) do
    converted_data = 
      data
      |> Enum.map(fn {{subject, predicate}, fact_value} ->
        {{predicate, subject}, fact_value}
      end)
      |> Map.new()
    
    %AriaEngine.State{data: converted_data}
  end
end
