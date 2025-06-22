# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Convenience do
  @moduledoc """
  Provides convenience API for State and Domain operations for the Aria Engine.
  """
  alias Core
  alias AriaEngine.Domain
  alias Multigoal
  alias PlannerAdapter

  @type state :: Core.state()
  @type domain :: Core.domain()
  @type multigoal :: Core.multigoal()
  @type goal :: Core.goal()
  @type plan_step :: Core.plan_step()

  @doc """
  Creates a new empty planning state.
  """
  @spec create_state() :: state()
  def create_state do
    AriaEngine.StateV2.new()
  end

  @doc """
  Creates a new planning domain with the given name.
  """
  @spec create_domain(String.t()) :: Domain.Core.t()
  def create_domain(name \\ "default") do
    Domain.new(name)
  end

  @doc """
  Creates a new multigoal.
  """
  @spec create_multigoal() :: multigoal()
  def create_multigoal do
    AriaEngine.Multigoal.new()
  end

  @doc """
  Sets a fact (predicate-subject-fact triple) in the state.
  """
  @spec set_fact(state(), String.t(), String.t(), AriaEngine.StateV2.fact_value()) :: state()
  def set_fact(%AriaEngine.StateV2{} = state, predicate, subject, fact_value) do
    AriaEngine.StateV2.set_fact(state, predicate, subject, fact_value)
  end

  @doc """
  Gets a fact from the state.
  """
  @spec get_fact(state(), String.t(), String.t()) :: AriaEngine.StateV2.fact_value() | nil
  def get_fact(%AriaEngine.StateV2{} = state, predicate, subject) do
    AriaEngine.StateV2.get_fact(state, predicate, subject)
  end

  @doc """
  Gets a summary of domain capabilities.
  """
  @spec domain_summary(Domain.Core.t()) :: map()
  def domain_summary(%AriaEngine.Domain.Core{} = domain) do
    Domain.summary(domain)
  end

  @doc """
  Merges two states, with the second taking precedence for conflicts.
  """
  @spec merge_states(state(), state()) :: state()
  def merge_states(%AriaEngine.StateV2{} = state1, %AriaEngine.StateV2{} = state2) do
    AriaEngine.StateV2.merge(state1, state2)
  end

  @doc """
  Converts a state to a list of triples for inspection.
  """
  @spec state_to_triples(state()) :: [{String.t(), String.t(), AriaEngine.StateV2.fact_value()}]
  def state_to_triples(%AriaEngine.StateV2{} = state) do
    AriaEngine.StateV2.to_triples(state)
  end

  @doc """
  Creates a state from a list of triples.
  """
  @spec state_from_triples([{String.t(), String.t(), AriaEngine.StateV2.fact_value()}]) :: state()
  def state_from_triples(triples) do
    AriaEngine.StateV2.from_triples(triples)
  end
end
