# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCore.State.Relational do
  @moduledoc """
  Relational state management system for AriaCore.

  This module provides the state management system that supports the
  {predicate, subject, value} format mentioned in ADR-181. It implements
  the sociable testing approach by providing a complete state system
  that can be leveraged by the attribute processing.

  ## State Format

  Uses the standardized {predicate, subject, value} triple format:
  - **Predicate**: What property or relationship (e.g., "status", "location", "temperature")
  - **Subject**: What entity or object (e.g., "chef_1", "oven_2", "meal_3")
  - **Value**: The current value (e.g., "busy", "kitchen", 350)

  ## Features

  - Fact storage and retrieval
  - Goal matching and validation
  - State transitions and updates
  - Query capabilities with pattern matching
  - Temporal state tracking (optional)

  ## Usage

      # Create new state
      state = AriaCore.State.Relational.new()

      # Set facts
      state = AriaCore.State.Relational.set_fact(state, "status", "chef_1", "available")
      state = AriaCore.State.Relational.set_fact(state, "temperature", "oven_1", 350)

      # Query facts
      {:ok, "available"} = AriaCore.State.Relational.get_fact(state, "status", "chef_1")

      # Check goals
      goal = {"status", "chef_1", "available"}
      true = AriaCore.State.Relational.satisfies_goal?(state, goal)
  """

  defstruct [
    :facts,
    :temporal_facts,
    :constraints,
    :metadata
  ]

  @type t :: %__MODULE__{
    facts: map(),
    temporal_facts: map(),
    constraints: map(),
    metadata: map()
  }

  @type fact :: {String.t(), String.t(), any()}
  @type goal :: {String.t(), String.t(), any()} | {String.t(), String.t(), {:>=, any()}} | {String.t(), String.t(), {:<, any()}}
  @type constraint :: {String.t(), String.t(), any(), map()}

  @doc """
  Creates a new empty relational state.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> map_size(state.facts)
      0
  """
  def new() do
    %__MODULE__{
      facts: %{},
      temporal_facts: %{},
      constraints: %{},
      metadata: %{
        created_at: DateTime.utc_now(),
        version: 1
      }
    }
  end

  @doc """
  Sets a fact in the state.

  ## Parameters

  - `state`: The current state
  - `predicate`: The property or relationship name
  - `subject`: The entity or object identifier
  - `value`: The value to set

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "status", "chef_1", "busy")
      iex> AriaCore.State.Relational.get_fact(state, "status", "chef_1")
      {:ok, "busy"}
  """
  def set_fact(%__MODULE__{} = state, predicate, subject, value) do
    fact_key = {predicate, subject}
    updated_facts = Map.put(state.facts, fact_key, value)

    %{state |
      facts: updated_facts,
      metadata: update_metadata(state.metadata, :fact_updated)
    }
  end

  @doc """
  Gets a fact from the state.

  ## Parameters

  - `state`: The current state
  - `predicate`: The property or relationship name
  - `subject`: The entity or object identifier

  ## Returns

  `{:ok, value}` if the fact exists, `{:error, :not_found}` otherwise.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "location", "agent_1", "kitchen")
      iex> AriaCore.State.Relational.get_fact(state, "location", "agent_1")
      {:ok, "kitchen"}

      iex> state = AriaCore.State.Relational.new()
      iex> AriaCore.State.Relational.get_fact(state, "location", "agent_2")
      {:error, :not_found}
  """
  def get_fact(%__MODULE__{} = state, predicate, subject) do
    fact_key = {predicate, subject}
    case Map.get(state.facts, fact_key) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @doc """
  Checks if a goal is satisfied by the current state.

  ## Goal Formats

  - `{predicate, subject, value}` - Exact match
  - `{predicate, subject, {:>=, value}}` - Greater than or equal
  - `{predicate, subject, {:<, value}}` - Less than
  - `{predicate, subject, {:!=, value}}` - Not equal

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "temperature", "oven_1", 350)
      iex> AriaCore.State.Relational.satisfies_goal?(state, {"temperature", "oven_1", 350})
      true

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "temperature", "oven_1", 350)
      iex> AriaCore.State.Relational.satisfies_goal?(state, {"temperature", "oven_1", {:>=, 300}})
      true

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "temperature", "oven_1", 350)
      iex> AriaCore.State.Relational.satisfies_goal?(state, {"temperature", "oven_1", {:>=, 400}})
      false
  """
  def satisfies_goal?(%__MODULE__{} = state, goal) do
    case goal do
      {predicate, subject, {operator, value}} when operator in [:>=, :<, :<=, :>, :!=] ->
        check_comparison_goal(state, predicate, subject, operator, value)

      {predicate, subject, value} ->
        check_exact_goal(state, predicate, subject, value)

      _ ->
        false
    end
  end

  @doc """
  Checks if multiple goals are all satisfied.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "status", "chef_1", "available")
      iex> state = AriaCore.State.Relational.set_fact(state, "temperature", "oven_1", 350)
      iex> goals = [
      ...>   {"status", "chef_1", "available"},
      ...>   {"temperature", "oven_1", {:>=, 300}}
      ...> ]
      iex> AriaCore.State.Relational.satisfies_goals?(state, goals)
      true
  """
  def satisfies_goals?(%__MODULE__{} = state, goals) when is_list(goals) do
    Enum.all?(goals, &satisfies_goal?(state, &1))
  end

  @doc """
  Applies multiple state changes atomically.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> changes = [
      ...>   {"status", "chef_1", "busy"},
      ...>   {"task", "chef_1", "cooking"},
      ...>   {"start_time", "cooking_session", DateTime.utc_now()}
      ...> ]
      iex> state = AriaCore.State.Relational.apply_changes(state, changes)
      iex> {:ok, "busy"} = AriaCore.State.Relational.get_fact(state, "status", "chef_1")
  """
  def apply_changes(%__MODULE__{} = state, changes) when is_list(changes) do
    Enum.reduce(changes, state, fn {predicate, subject, value}, acc ->
      set_fact(acc, predicate, subject, value)
    end)
  end

  @doc """
  Queries facts using pattern matching.

  ## Pattern Formats

  - `{predicate, :_, :_}` - All facts with this predicate
  - `{:_, subject, :_}` - All facts about this subject
  - `{predicate, subject, :_}` - The value for this predicate/subject pair

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "status", "chef_1", "busy")
      iex> state = AriaCore.State.Relational.set_fact(state, "location", "chef_1", "kitchen")
      iex> results = AriaCore.State.Relational.query(state, {:_, "chef_1", :_})
      iex> length(results)
      2
  """
  def query(%__MODULE__{} = state, pattern) do
    case pattern do
      {predicate, :_, :_} ->
        query_by_predicate(state, predicate)

      {:_, subject, :_} ->
        query_by_subject(state, subject)

      {predicate, subject, :_} ->
        query_by_predicate_subject(state, predicate, subject)

      {predicate, subject, value} ->
        case satisfies_goal?(state, {predicate, subject, value}) do
          true -> [{predicate, subject, value}]
          false -> []
        end

      _ ->
        []
    end
  end

  @doc """
  Gets all facts in the state.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "status", "chef_1", "available")
      iex> facts = AriaCore.State.Relational.all_facts(state)
      iex> length(facts)
      1
  """
  def all_facts(%__MODULE__{} = state) do
    Enum.map(state.facts, fn {{predicate, subject}, value} ->
      {predicate, subject, value}
    end)
  end

  @doc """
  Removes a fact from the state.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "status", "chef_1", "busy")
      iex> state = AriaCore.State.Relational.remove_fact(state, "status", "chef_1")
      iex> AriaCore.State.Relational.get_fact(state, "status", "chef_1")
      {:error, :not_found}
  """
  def remove_fact(%__MODULE__{} = state, predicate, subject) do
    fact_key = {predicate, subject}
    updated_facts = Map.delete(state.facts, fact_key)

    %{state |
      facts: updated_facts,
      metadata: update_metadata(state.metadata, :fact_removed)
    }
  end

  @doc """
  Adds a temporal fact with timestamp.

  Temporal facts track when state changes occurred.
  """
  def set_temporal_fact(%__MODULE__{} = state, predicate, subject, value, timestamp \\ nil) do
    timestamp = timestamp || DateTime.utc_now()
    fact_key = {predicate, subject}

    # Add to regular facts
    updated_facts = Map.put(state.facts, fact_key, value)

    # Add to temporal tracking
    temporal_entry = %{value: value, timestamp: timestamp}
    temporal_history = Map.get(state.temporal_facts, fact_key, [])
    updated_temporal = Map.put(state.temporal_facts, fact_key, [temporal_entry | temporal_history])

    %{state |
      facts: updated_facts,
      temporal_facts: updated_temporal,
      metadata: update_metadata(state.metadata, :temporal_fact_added)
    }
  end

  @doc """
  Gets the history of changes for a fact.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_temporal_fact(state, "status", "chef_1", "available")
      iex> state = AriaCore.State.Relational.set_temporal_fact(state, "status", "chef_1", "busy")
      iex> history = AriaCore.State.Relational.get_fact_history(state, "status", "chef_1")
      iex> length(history)
      2
  """
  def get_fact_history(%__MODULE__{} = state, predicate, subject) do
    fact_key = {predicate, subject}
    Map.get(state.temporal_facts, fact_key, [])
  end

  @doc """
  Validates the state for consistency and constraint compliance.
  """
  def validate(%__MODULE__{} = state) do
    with :ok <- validate_fact_format(state.facts),
         :ok <- validate_constraints(state.facts, state.constraints) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a copy of the state.

  ## Examples

      iex> state = AriaCore.State.Relational.new()
      iex> state = AriaCore.State.Relational.set_fact(state, "test", "subject", "value")
      iex> copy = AriaCore.State.Relational.copy(state)
      iex> AriaCore.State.Relational.get_fact(copy, "test", "subject")
      {:ok, "value"}
  """
  def copy(%__MODULE__{} = state) do
    %__MODULE__{
      facts: Map.new(state.facts),
      temporal_facts: Map.new(state.temporal_facts),
      constraints: Map.new(state.constraints),
      metadata: Map.put(state.metadata, :copied_at, DateTime.utc_now())
    }
  end

  defp check_exact_goal(state, predicate, subject, value) do
    case get_fact(state, predicate, subject) do
      {:ok, actual_value} -> actual_value == value
      _ -> false
    end
  end

  defp check_comparison_goal(state, predicate, subject, operator, expected_value) do
    case get_fact(state, predicate, subject) do
      {:ok, actual_value} -> apply_comparison(actual_value, operator, expected_value)
      _ -> false
    end
  end

  defp apply_comparison(actual, :>=, expected) when is_number(actual) and is_number(expected) do
    actual >= expected
  end

  defp apply_comparison(actual, :<, expected) when is_number(actual) and is_number(expected) do
    actual < expected
  end

  defp apply_comparison(actual, :<=, expected) when is_number(actual) and is_number(expected) do
    actual <= expected
  end

  defp apply_comparison(actual, :>, expected) when is_number(actual) and is_number(expected) do
    actual > expected
  end

  defp apply_comparison(actual, :!=, expected) do
    actual != expected
  end

  defp apply_comparison(actual, :>=, expected) do
    # String comparison fallback
    to_string(actual) >= to_string(expected)
  end

  defp apply_comparison(actual, :<, expected) do
    # String comparison fallback
    to_string(actual) < to_string(expected)
  end

  defp apply_comparison(_, _, _), do: false

  defp query_by_predicate(state, predicate) do
    state.facts
    |> Enum.filter(fn {{pred, _subject}, _value} -> pred == predicate end)
    |> Enum.map(fn {{pred, subj}, val} -> {pred, subj, val} end)
  end

  defp query_by_subject(state, subject) do
    state.facts
    |> Enum.filter(fn {{_predicate, subj}, _value} -> subj == subject end)
    |> Enum.map(fn {{pred, subj}, val} -> {pred, subj, val} end)
  end

  defp query_by_predicate_subject(state, predicate, subject) do
    case get_fact(state, predicate, subject) do
      {:ok, value} -> [{predicate, subject, value}]
      _ -> []
    end
  end

  defp update_metadata(metadata, operation) do
    metadata
    |> Map.put(:last_updated, DateTime.utc_now())
    |> Map.put(:last_operation, operation)
    |> Map.update(:version, 1, &(&1 + 1))
  end

  defp validate_fact_format(facts) do
    invalid_facts = Enum.filter(facts, fn
      {{pred, subj}, _val} when is_binary(pred) and is_binary(subj) -> false
      _ -> true
    end)

    case invalid_facts do
      [] -> :ok
      _ -> {:error, "Invalid fact format: #{inspect(invalid_facts)}"}
    end
  end

  defp validate_constraints(facts, constraints) do
    # Check constraint violations
    violations = Enum.filter(constraints, fn {constraint_key, constraint_spec} ->
      not satisfies_constraint?(facts, constraint_key, constraint_spec)
    end)

    case violations do
      [] -> :ok
      _ -> {:error, "Constraint violations: #{inspect(violations)}"}
    end
  end

  defp satisfies_constraint?(_facts, _constraint_key, _constraint_spec) do
    # Placeholder for constraint checking logic
    # Could implement various constraint types:
    # - Uniqueness constraints
    # - Range constraints
    # - Dependency constraints
    true
  end
end
