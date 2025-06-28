defmodule AriaEngine.State do
  @moduledoc """
  Mock implementation of AriaEngine.State for compilation.

  This module provides the state management API as specified in ADR R25W1398085.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: map()

  @doc """
  Create a new empty state.
  """
  @spec new() :: t()
  def new do
    %{facts: %{}}
  end

  @doc """
  Set a fact in the state.
  Format: set_fact(state, predicate, subject, value)
  """
  @spec set_fact(t(), String.t(), String.t(), term()) :: t()
  def set_fact(state, predicate, subject, value) do
    fact_key = {predicate, subject}
    put_in(state, [:facts, fact_key], value)
  end

  @doc """
  Get a fact from the state.
  Format: get_fact(state, predicate, subject)
  """
  @spec get_fact(t(), String.t(), String.t()) :: term() | nil
  def get_fact(state, predicate, subject) do
    fact_key = {predicate, subject}
    get_in(state, [:facts, fact_key])
  end
end
