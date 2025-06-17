# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.State do
  @moduledoc """
  Represents the state of a planning problem using predicate-subject-fact triples.
  
  This module provides functionality to manage world state using RDF-like triples,
  where each fact is represented as {predicate, subject} -> fact_value.
  
  Example:
  ```elixir
  state = AriaEngine.State.new()
  |> AriaEngine.State.set_fact("location", "player", "room1")
  |> AriaEngine.State.set_fact("has", "player", "sword")
  
  AriaEngine.State.get_fact(state, "location", "player")
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
end
