# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StateV2 do
  @moduledoc "Modernized state management using subject-predicate-fact triples for entity-centric architecture.\n\nThis module provides functionality to manage world state using entity-first RDF-like triples,\nwhere each fact is represented as {subject, predicate} -> fact_value.\n\nSupports any reasonable Elixir type for subjects and predicates:\n\n```elixir\nstate = StateV2.new()\n# String-based entities (traditional approach)\n|> StateV2.set_fact(\"player\", \"location\", \"room1\")\n|> StateV2.set_fact(\"player\", \"has\", \"sword\")\n\n# Integer node IDs (for computational graphs)\n|> StateV2.set_fact(42, :value, 3.14159)\n|> StateV2.set_fact(43, :operation, :add)\n\n# Atom predicates for performance\n|> StateV2.set_fact(\"npc1\", :status, :active)\n|> StateV2.set_fact(\"npc1\", :ai_state, {:planning, \"attack_player\"})\n\n# Mixed types work naturally\nStateV2.get_fact(state, 42, :value)  # => 3.14159\nStateV2.get_fact(state, \"player\", \"location\")  # => \"room1\"\n```\n\nThis entity-first approach aligns with game networking ECS patterns and supports\nthe timeline-per-entity architecture defined in ADR-087.\n"
  @type subject :: term()
  @type predicate :: term()
  @type fact_value :: term()
  @type triple_key :: {subject(), predicate()}
  @type t :: %__MODULE__{data: %{triple_key() => fact_value()}}
  defstruct data: %{}
  @doc "Creates a new empty planning state.\n"
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc "Creates a new planning state from a map of subject-predicate-object data.\n"
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    %__MODULE__{data: data}
  end

  @doc "Gets the fact_value for a given subject and predicate.\nReturns nil if the triple doesn't exist.\n\nEntity-first API: get_fact(state, subject, predicate)\n"
  @spec get_fact(t(), subject(), predicate()) :: fact_value() | nil
  def get_fact(%__MODULE__{data: data}, subject, predicate) do
    Map.get(data, {subject, predicate})
  end

  @doc "Sets the fact_value for a given subject and predicate.\n\nEntity-first API: set_fact(state, subject, predicate, fact_value)\n"
  @spec set_fact(t(), subject(), predicate(), fact_value()) :: t()
  def set_fact(%__MODULE__{data: data} = state, subject, predicate, fact_value) do
    %{state | data: Map.put(data, {subject, predicate}, fact_value)}
  end

  @doc "Alias for set_fact/4 for backward compatibility.\n\nEntity-first API: update_fact(state, subject, predicate, fact_value)\n"
  @spec update_fact(t(), subject(), predicate(), fact_value()) :: t()
  def update_fact(%__MODULE__{} = state, subject, predicate, fact_value) do
    set_fact(state, subject, predicate, fact_value)
  end

  @doc "Alias for set_fact/4 for backward compatibility.\n\nEntity-first API: add_fact(state, predicate, subject, fact_value)\nNote: Parameters are in different order for legacy compatibility.\n"
  @spec add_fact(t(), predicate(), subject(), fact_value()) :: t()
  def add_fact(%__MODULE__{} = state, predicate, subject, fact_value) do
    set_fact(state, subject, predicate, fact_value)
  end

  @doc "Removes a triple from the state.\n\nEntity-first API: remove_fact(state, subject, predicate)\n"
  @spec remove_fact(t(), subject(), predicate()) :: t()
  def remove_fact(%__MODULE__{data: data} = state, subject, predicate) do
    %{state | data: Map.delete(data, {subject, predicate})}
  end

  @doc "Checks if a subject has a given predicate with any fact_value.\n\nEntity-first API: has_predicate?(state, subject, predicate)\n"
  @spec has_predicate?(t(), subject(), predicate()) :: boolean()
  def has_predicate?(%__MODULE__{data: data}, subject, predicate) do
    Map.has_key?(data, {subject, predicate})
  end

  @doc "Checks if a subject exists in the state (has any predicates).\n"
  @spec has_subject?(t(), subject()) :: boolean()
  def has_subject?(%__MODULE__{data: data}, subject) do
    data |> Map.keys() |> Enum.any?(fn {subj, _predicate} -> subj == subject end)
  end

  @doc "Gets a list of all subjects that have properties.\n"
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(%__MODULE__{data: data}) do
    data |> Map.keys() |> Enum.map(fn {subject, _predicate} -> subject end) |> Enum.uniq()
  end

  @doc "Gets all predicates for a given subject.\n\nEntity-first API: get_predicates(state, subject)\n"
  @spec get_predicates(t(), subject()) :: [predicate()]
  def get_predicates(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.filter(fn {subj, _predicate} -> subj == subject end)
    |> Enum.map(fn {_subj, predicate} -> predicate end)
  end

  @doc "Gets all properties for a given subject as a map.\n\nEntity-first API: get_properties(state, subject)\n"
  @spec get_properties(t(), subject()) :: %{predicate() => fact_value()}
  def get_properties(%__MODULE__{data: data}, subject) do
    data
    |> Enum.filter(fn {{subj, _predicate}, _value} -> subj == subject end)
    |> Enum.map(fn {{_subj, predicate}, value} -> {predicate, value} end)
    |> Map.new()
  end

  @doc "Gets all triples as a list of {subject, predicate, fact_value} tuples.\n"
  @spec to_triples(t()) :: [{subject(), predicate(), fact_value()}]
  def to_triples(%__MODULE__{data: data}) do
    Enum.map(data, fn {{subject, predicate}, fact_value} -> {subject, predicate, fact_value} end)
  end

  @doc "Creates a state from a list of triples.\n"
  @spec from_triples([{subject(), predicate(), fact_value()}]) :: t()
  def from_triples(triples) do
    data =
      triples
      |> Enum.map(fn {subject, predicate, fact_value} -> {{subject, predicate}, fact_value} end)
      |> Map.new()

    %__MODULE__{data: data}
  end

  @doc "Merges two states, with the second state taking precedence for conflicts.\n"
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: Map.merge(data1, data2)}
  end

  @doc "Returns a copy of the state with modified data.\n"
  @spec copy(t()) :: t()
  def copy(%__MODULE__{data: data}) do
    %__MODULE__{data: Map.new(data)}
  end

  @doc "Checks if the state matches a specific subject, predicate, and fact_value pattern.\n\nEntity-first API: matches_exactly?(state, subject, predicate, fact_value)\n"
  @spec matches_exactly?(t(), subject(), predicate(), fact_value()) :: boolean()
  def matches_exactly?(%__MODULE__{data: data}, subject, predicate, fact_value) do
    case Map.get(data, {subject, predicate}) do
      ^fact_value -> true
      _ -> false
    end
  end

  @doc "Evaluates existential quantifier: checks if there exists at least one subject \nthat matches the given subject_filter, predicate, and fact_value pattern.\n\nEntity-first API: exists?(state, subject_filter, predicate, fact_value)\n\nExample:\n```elixir\n# Check if there exists any chair that is available\nStateV2.exists?(state, &String.contains?(&1, \"chair\"), \"status\", \"available\")\n```\n"
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

      _ ->
        false
    end)
  end

  @doc "Evaluates universal quantifier: checks if all subjects matching the pattern\nhave the specified predicate and fact_value.\n\nEntity-first API: forall?(state, subject_filter, predicate, fact_value)\n\nExample:\n```elixir\n# Check if all doors are locked\nStateV2.forall?(state, &String.contains?(&1, \"door\"), \"status\", \"locked\")\n```\n"
  @spec forall?(t(), (subject() -> boolean()), predicate(), fact_value()) :: boolean()
  def forall?(%__MODULE__{data: data}, subject_filter, predicate, fact_value)
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
        matches_exactly?(%__MODULE__{data: data}, subject, predicate, fact_value)
      end)
    end
  end

  @doc "Gets all subjects that have a specific predicate with a specific fact_value.\n\nExample:\n```elixir\n# Get all subjects with status \"available\"\nStateV2.get_subjects_with_fact(state, \"status\", \"available\")\n# => [\"chair1\", \"chair3\", \"table2\"]\n```\n"
  @spec get_subjects_with_fact(t(), predicate(), fact_value()) :: [subject()]
  def get_subjects_with_fact(%__MODULE__{data: data}, predicate, fact_value) do
    data
    |> Enum.filter(fn {{_subj, pred}, val} -> pred == predicate and val == fact_value end)
    |> Enum.map(fn {{subj, _pred}, _val} -> subj end)
  end

  @doc "Gets all subjects that match a predicate pattern, regardless of fact_value.\n\nExample:\n```elixir\n# Get all subjects that have a \"location\" predicate\nStateV2.get_subjects_with_predicate(state, \"location\")\n# => [\"player\", \"npc1\", \"chest\"]\n```\n"
  @spec get_subjects_with_predicate(t(), predicate()) :: [subject()]
  def get_subjects_with_predicate(%__MODULE__{data: data}, predicate) do
    data
    |> Map.keys()
    |> Enum.filter(fn {_subj, pred} -> pred == predicate end)
    |> Enum.map(fn {subj, _pred} -> subj end)
    |> Enum.uniq()
  end

  @doc "Evaluates a quantified condition structure using entity-first patterns.\n\nSupports both existential and universal quantifiers with flexible condition patterns.\n\n## Condition Format\n```elixir\n# Existential quantifier (entity-first)\n{:exists, subject_filter, predicate, fact_value}\n\n# Universal quantifier (entity-first)\n{:forall, subject_filter, predicate, fact_value}\n\n# Regular condition (entity-first)\n{subject, predicate, fact_value}\n```\n\n## Examples\n```elixir\n# Check if any chair is available\ncondition = {:exists, &String.contains?(&1, \"chair\"), \"status\", \"available\"}\nStateV2.evaluate_condition(state, condition)\n\n# Check if all doors are locked\ncondition = {:forall, &String.contains?(&1, \"door\"), \"status\", \"locked\"}\nStateV2.evaluate_condition(state, condition)\n\n# Regular condition check (entity-first)\ncondition = {\"player\", \"location\", \"room1\"}\nStateV2.evaluate_condition(state, condition)\n```\n"
  @spec evaluate_condition(t(), tuple()) :: boolean()
  def evaluate_condition(state, condition)

  def evaluate_condition(state, {:exists, subject_filter, predicate, fact_value}) do
    exists?(state, subject_filter, predicate, fact_value)
  end

  def evaluate_condition(state, {:forall, subject_filter, predicate, fact_value}) do
    forall?(state, subject_filter, predicate, fact_value)
  end

  def evaluate_condition(state, {subject, predicate, fact_value}) do
    matches_exactly?(state, subject, predicate, fact_value)
  end

  def evaluate_condition(_state, condition) do
    if Mix.env() == :dev or (Mix.env() == :test and ExUnit.configuration()[:trace]) do
      require Logger
      Logger.warning("Unknown condition format: #{inspect(condition)}")
    end

    false
  end

  @doc "Converts from legacy State format to StateV2 format.\n\nThis function helps with migration from the old {predicate, subject} format\nto the new entity-first {subject, predicate} format.\n"
  @spec from_legacy_state(AriaEngine.State.t()) :: t()
  def from_legacy_state(%AriaEngine.State{data: legacy_data}) do
    converted_data =
      legacy_data
      |> Enum.map(fn {{predicate, subject}, fact_value} -> {{subject, predicate}, fact_value} end)
      |> Map.new()

    %__MODULE__{data: converted_data}
  end

  @doc "Converts to legacy State format for backward compatibility.\n\nThis function helps with migration by allowing StateV2 to be used\nwith existing code that expects the old format.\n"
  @spec to_legacy_state(t()) :: AriaEngine.State.t()
  def to_legacy_state(%__MODULE__{data: data}) do
    converted_data =
      data
      |> Enum.map(fn {{subject, predicate}, fact_value} -> {{predicate, subject}, fact_value} end)
      |> Map.new()

    %AriaEngine.State{data: converted_data}
  end
end