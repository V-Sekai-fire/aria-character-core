# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.State do
  @moduledoc """
  Simple state representation for timeline operations.

  This is a minimal state module to avoid dependency cycles.
  For full state functionality, use AriaEngine.State from aria_engine_core.
  """

  @type predicate :: String.t()
  @type subject :: String.t()
  @type fact_value :: any()
  @type triple_key :: {predicate(), subject()}
  @type t :: %__MODULE__{data: %{triple_key() => fact_value()}}

  defstruct data: %{}

  @doc "Creates a new empty state."
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc "Creates a new state from a map."
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    %__MODULE__{data: data}
  end

  @doc "Gets the fact_value for a given predicate and subject."
  @spec get_fact(t(), predicate(), subject()) :: fact_value() | nil
  def get_fact(%__MODULE__{data: data}, predicate, subject) do
    Map.get(data, {predicate, subject})
  end

  @doc "Sets the fact_value for a given predicate and subject."
  @spec set_fact(t(), predicate(), subject(), fact_value()) :: t()
  def set_fact(%__MODULE__{data: data} = state, predicate, subject, fact_value) do
    %{state | data: Map.put(data, {predicate, subject}, fact_value)}
  end

  @doc "Checks if a subject has a given predicate."
  @spec has_subject?(t(), predicate(), subject()) :: boolean()
  def has_subject?(%__MODULE__{data: data}, predicate, subject) do
    Map.has_key?(data, {predicate, subject})
  end

  @doc "Gets all properties for a given subject."
  @spec get_properties(t(), subject()) :: %{predicate() => fact_value()}
  def get_properties(%__MODULE__{data: data}, subject) do
    data
    |> Enum.filter(fn {{_predicate, subj}, _value} -> subj == subject end)
    |> Enum.map(fn {{predicate, _subj}, value} -> {predicate, value} end)
    |> Map.new()
  end
end
