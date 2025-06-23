defmodule Convenience do
  @moduledoc "Provides convenience API for State and Domain operations for the Aria Engine.\n"
  alias Core
  alias Domain
  alias Multigoal
  alias PlannerAdapter
  @type state :: Core.state()
  @type domain :: Core.domain()
  @type multigoal :: Core.multigoal()
  @type goal :: Core.goal()
  @type plan_step :: Core.plan_step()
  @doc "Creates a new empty planning state.\n"
  @spec create_state() :: state()
  def create_state do
    AriaEngine.State.new()
  end

  @doc "Creates a new planning domain with the given name.\n"
  @spec create_domain(String.t()) :: Domain.Core.t()
  def create_domain(name \\ "default") do
    Domain.new(name)
  end

  @doc "Creates a new multigoal.\n"
  @spec create_multigoal() :: multigoal()
  def create_multigoal do
    Multigoal.new()
  end

  @doc "Sets a fact (predicate-subject-fact triple) in the state.\n"
  @spec set_fact(state(), String.t(), String.t(), AriaEngine.State.fact_value()) :: state()
  def set_fact(%AriaEngine.State{} = state, predicate, subject, fact_value) do
    AriaEngine.State.set_fact(state, predicate, subject, fact_value)
  end

  @doc "Gets a fact from the state.\n"
  @spec get_fact(state(), String.t(), String.t()) :: AriaEngine.State.fact_value() | nil
  def get_fact(%AriaEngine.State{} = state, predicate, subject) do
    AriaEngine.State.get_fact(state, predicate, subject)
  end

  @doc "Gets the cost (number of steps) of a plan.\n"
  @spec plan_cost([plan_step()]) :: non_neg_integer()
  def plan_cost(plan) do
    AriaEngine.PlannerAdapter.plan_cost(plan)
  end

  @doc "Gets a summary of domain capabilities.\n"
  @spec domain_summary(Domain.Core.t()) :: map()
  def domain_summary(%Domain.Core{} = domain) do
    Domain.summary(domain)
  end

  @doc "Merges two states, with the second taking precedence for conflicts.\n"
  @spec merge_states(state(), state()) :: state()
  def merge_states(%AriaEngine.State{} = state1, %AriaEngine.State{} = state2) do
    AriaEngine.State.merge(state1, state2)
  end

  @doc "Converts a state to a list of triples for inspection.\n"
  @spec state_to_triples(state()) :: [{String.t(), String.t(), AriaEngine.State.fact_value()}]
  def state_to_triples(%AriaEngine.State{} = state) do
    AriaEngine.State.to_triples(state)
  end

  @doc "Creates a state from a list of triples.\n"
  @spec state_from_triples([{String.t(), String.t(), AriaEngine.State.fact_value()}]) :: state()
  def state_from_triples(triples) do
    AriaEngine.State.from_triples(triples)
  end
end