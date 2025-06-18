# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule State do
  @moduledoc """
  Represents the state of a planning problem using predicate-subject-fact triples.
  
  This module provides functionality to manage world state using RDF-like triples,
  where each fact is represented as {predicate, subject} -> fact_value.
  
  Example:
  ```elixir
  state = State.new()
  |> State.set_fact("location", "player", "room1")
  |> State.set_fact("has", "player", "sword")
  
  State.get_fact(state, "location", "player")
  # => "room1"
  ```
  """

  @type predicate :: String.t()
  @type subject :: String.t()
  @type fact_value :: any()
  @type triple_key :: {predicate(), subject()}
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
  Creates a new planning state from a map of predicate-subject-object data.
  """
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    %__MODULE__{data: data}
  end

  @doc """
  Gets the fact_value for a given predicate and subject.
  Returns nil if the triple doesn't exist.
  """
  @spec get_fact(t(), predicate(), subject()) :: fact_value() | nil
  def get_fact(%__MODULE__{data: data}, predicate, subject) do
    Map.get(data, {predicate, subject})
  end

  @doc """
  Sets the fact_value for a given predicate and subject.
  """
  @spec set_fact(t(), predicate(), subject(), fact_value()) :: t()
  def set_fact(%__MODULE__{data: data} = state, predicate, subject, fact_value) do
    %{state | data: Map.put(data, {predicate, subject}, fact_value)}
  end

  @doc """
  Removes a triple from the state.
  """
  @spec remove_fact(t(), predicate(), subject()) :: t()
  def remove_fact(%__MODULE__{data: data} = state, predicate, subject) do
    %{state | data: Map.delete(data, {predicate, subject})}
  end

  @doc """
  Checks if a subject has a given predicate with any object.
  """
  @spec has_subject?(t(), predicate(), subject()) :: boolean()
  def has_subject?(%__MODULE__{data: data}, predicate, subject) do
    Map.has_key?(data, {predicate, subject})
  end

  @doc """
  Checks if a subject variable exists in any predicate.
  """
  @spec has_subject_variable?(t(), subject()) :: boolean()
  def has_subject_variable?(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.any?(fn {_predicate, subj} -> subj == subject end)
  end

  @doc """
  Gets a list of all subjects that have properties.
  """
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(%__MODULE__{data: data}) do
    data
    |> Map.keys()
    |> Enum.map(fn {_predicate, subject} -> subject end)
    |> Enum.uniq()
  end

  @doc """
  Gets all predicates for a given subject.
  """
  @spec get_subject_properties(t(), subject()) :: [predicate()]
  def get_subject_properties(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.filter(fn {_predicate, subj} -> subj == subject end)
    |> Enum.map(fn {predicate, _subj} -> predicate end)
  end

  @doc """
  Gets all triples as a list of {predicate, subject, fact_value} tuples.
  """
  @spec to_triples(t()) :: [{predicate(), subject(), fact_value()}]
  def to_triples(%__MODULE__{data: data}) do
    Enum.map(data, fn {{predicate, subject}, fact_value} ->
      {predicate, subject, fact_value}
    end)
  end

  @doc """
  Creates a state from a list of triples.
  """
  @spec from_triples([{predicate(), subject(), fact_value()}]) :: t()
  def from_triples(triples) do
    data = 
      triples
      |> Enum.map(fn {predicate, subject, fact_value} -> 
        {{predicate, subject}, fact_value} 
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
  Checks if the state matches a specific predicate, subject, and fact_value pattern.
  
  This function is used by the planner to check if a goal condition is satisfied
  in the current state. It returns true if the state contains the specified triple.
  """
  @spec matches?(t(), predicate(), subject(), fact_value()) :: boolean()
  def matches?(%__MODULE__{data: data}, predicate, subject, fact_value) do
    case Map.get(data, {predicate, subject}) do
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
  State.exists?(state, "status", "available", &String.contains?(&1, "chair"))
  ```
  """
  @spec exists?(t(), predicate(), fact_value(), (subject() -> boolean()) | nil) :: boolean()
  def exists?(%__MODULE__{data: data}, predicate, fact_value, subject_filter \\ nil) do
    data
    |> Enum.any?(fn
      {{^predicate, subject}, ^fact_value} ->
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
  
  Example:
  ```elixir
  # Check if all doors are locked
  State.forall?(state, "status", "locked", &String.contains?(&1, "door"))
  ```
  """
  @spec forall?(t(), predicate(), fact_value(), (subject() -> boolean())) :: boolean()
  def forall?(%__MODULE__{data: data}, predicate, fact_value, subject_filter) 
      when is_function(subject_filter, 1) do
    # Find all subjects that match the filter
    matching_subjects = 
      data
      |> Map.keys()
      |> Enum.map(fn {_pred, subj} -> subj end)
      |> Enum.uniq()
      |> Enum.filter(subject_filter)
    
    # If no subjects match the filter, vacuous truth applies (return true)
    if Enum.empty?(matching_subjects) do
      true
    else
      # Check that ALL matching subjects have the required predicate-value
      Enum.all?(matching_subjects, fn subject ->
        matches?(%__MODULE__{data: data}, predicate, subject, fact_value)
      end)
    end
  end

  @doc """
  Gets all subjects that have a specific predicate with a specific fact_value.
  
  Example:
  ```elixir
  # Get all subjects with status "available"
  State.get_subjects_with_fact(state, "status", "available")
  # => ["chair1", "chair3", "table2"]
  ```
  """
  @spec get_subjects_with_fact(t(), predicate(), fact_value()) :: [subject()]
  def get_subjects_with_fact(%__MODULE__{data: data}, predicate, fact_value) do
    data
    |> Enum.filter(fn {{pred, _subj}, val} -> 
      pred == predicate and val == fact_value 
    end)
    |> Enum.map(fn {{_pred, subj}, _val} -> subj end)
  end

  @doc """
  Gets all subjects that match a predicate pattern, regardless of fact_value.
  
  Example:
  ```elixir
  # Get all subjects that have a "location" predicate
  State.get_subjects_with_predicate(state, "location")
  # => ["player", "npc1", "chest"]
  ```
  """
  @spec get_subjects_with_predicate(t(), predicate()) :: [subject()]
  def get_subjects_with_predicate(%__MODULE__{data: data}, predicate) do
    data
    |> Map.keys()
    |> Enum.filter(fn {pred, _subj} -> pred == predicate end)
    |> Enum.map(fn {_pred, subj} -> subj end)
    |> Enum.uniq()
  end

  @doc """
  Evaluates a quantified condition structure.
  
  Supports both existential and universal quantifiers with flexible condition patterns.
  
  ## Condition Format
  ```elixir
  # Existential quantifier
  {:exists, predicate, fact_value, subject_filter}
  
  # Universal quantifier  
  {:forall, predicate, fact_value, subject_filter}
  
  # Regular condition (backward compatibility)
  {predicate, subject, fact_value}
  ```
  
  ## Examples
  ```elixir
  # Check if any chair is available
  condition = {:exists, "status", "available", &String.contains?(&1, "chair")}
  State.evaluate_condition(state, condition)
  
  # Check if all doors are locked
  condition = {:forall, "status", "locked", &String.contains?(&1, "door")}
  State.evaluate_condition(state, condition)
  
  # Regular condition check
  condition = {"location", "player", "room1"}
  State.evaluate_condition(state, condition)
  ```
  """
  @spec evaluate_condition(t(), tuple()) :: boolean()
  def evaluate_condition(state, condition)

  def evaluate_condition(state, {:exists, predicate, fact_value, subject_filter}) do
    exists?(state, predicate, fact_value, subject_filter)
  end

  def evaluate_condition(state, {:forall, predicate, fact_value, subject_filter}) do
    forall?(state, predicate, fact_value, subject_filter)
  end

  def evaluate_condition(state, {predicate, subject, fact_value}) do
    matches?(state, predicate, subject, fact_value)
  end

  def evaluate_condition(_state, condition) do
    # Only log in development or when ExUnit trace mode is enabled
    if Mix.env() == :dev or (Mix.env() == :test and ExUnit.configuration()[:trace]) do
      require Logger
      Logger.warning("Unknown condition format: #{inspect(condition)}")
    end
    false
  end
end
