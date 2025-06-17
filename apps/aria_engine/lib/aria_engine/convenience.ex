defmodule AriaEngine.Convenience do
  @moduledoc """
  Provides convenience API for State and Domain operations for the Aria Engine.
  """
  alias AriaEngine.Core
  alias AriaEngine.State
  alias AriaEngine.Domain
  alias AriaEngine.Multigoal
  alias AriaEngine.Plan

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
    State.new()
  end

  @doc """
  Creates a new planning domain with the given name.
  """
  @spec create_domain(String.t()) :: AriaEngine.Domain.Core.t()
  def create_domain(name \\ "default") do
    Domain.new(name)
  end

  @doc """
  Creates a new multigoal.
  """
  @spec create_multigoal() :: multigoal()
  def create_multigoal do
    Multigoal.new()
  end

  @doc """
  Sets a fact (predicate-subject-fact triple) in the state.
  """
  @spec set_fact(state(), String.t(), String.t(), State.fact_value()) :: state()
  def set_fact(%State{} = state, predicate, subject, fact_value) do
    State.set_fact(state, predicate, subject, fact_value)
  end

  @doc """
  Gets a fact from the state.
  """
  @spec get_fact(state(), String.t(), String.t()) :: State.fact_value() | nil
  def get_fact(%State{} = state, predicate, subject) do
    State.get_fact(state, predicate, subject)
  end

  @doc """
  Gets the cost (number of steps) of a plan.
  """
  @spec plan_cost([plan_step()]) :: non_neg_integer()
  def plan_cost(plan) do
    Plan.plan_cost(plan)
  end

  @doc """
  Gets a summary of domain capabilities.
  """
  @spec domain_summary(AriaEngine.Domain.Core.t()) :: map()
  def domain_summary(%AriaEngine.Domain.Core{} = domain) do
    Domain.summary(domain)
  end

  @doc """
  Merges two states, with the second taking precedence for conflicts.
  """
  @spec merge_states(state(), state()) :: state()
  def merge_states(%State{} = state1, %State{} = state2) do
    State.merge(state1, state2)
  end

  @doc """
  Converts a state to a list of triples for inspection.
  """
  @spec state_to_triples(state()) :: [{String.t(), String.t(), State.fact_value()}]
  def state_to_triples(%State{} = state) do
    State.to_triples(state)
  end

  @doc """
  Creates a state from a list of triples.
  """
  @spec state_from_triples([{String.t(), String.t(), State.fact_value()}]) :: state()
  def state_from_triples(triples) do
    State.from_triples(triples)
  end
end
