# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine do
  @moduledoc """
  Aria Engine - Classical AI Planning & GTPyhop (Hierarchical Task Planner)
  
  This module provides the main interface for the Aria Engine service, which implements
  a port of the GTPyhop hierarchical task planner to Elixir. It handles character AI
  decision-making, goal planning, and task execution for generated characters.
  
  ## Core Components
  
  - `AriaEngine.State`: Manages world state using predicate-subject-object triples
  - `AriaEngine.Domain`: Contains actions, tasks, and planning methods
  - `AriaEngine.Multigoal`: Represents collections of goals to achieve
  - `AriaEngine.Plan`: Core planning algorithm implementation
  
  ## Usage Example
  
  ```elixir
  # Create a planning domain
  domain = AriaEngine.create_domain("rpg_character")
  |> AriaEngine.add_action(:move, &RPGActions.move/2)
  |> AriaEngine.add_action(:pickup, &RPGActions.pickup/2)
  |> AriaEngine.add_task_method("get_item", [&RPGMethods.get_item_nearby/2, &RPGMethods.get_item_far/2])
  
  # Set up initial state
  initial_state = AriaEngine.create_state()
  |> AriaEngine.set_fact("location", "player", "room1")
  |> AriaEngine.set_fact("location", "sword", "room2")
  
  # Define goals
  goals = [{"has", "player", "sword"}]
  
  # Plan and execute
  case AriaEngine.plan(domain, initial_state, goals) do
    {:ok, result_plan} -> 
      IO.puts("Plan found: \#{inspect(result_plan)}")
      AriaEngine.execute_plan(domain, initial_state, result_plan)
    {:error, reason} -> 
      IO.puts("Planning failed: \#{reason}")
  end
  ```
  """

  alias AriaEngine.{Domain, State, Multigoal, Plan}

  # Re-export key types for convenience
  @type domain :: Domain.t()
  @type state :: State.t()
  @type multigoal :: Multigoal.t()
  @type goal :: {String.t(), String.t(), any()}
  @type task :: {String.t(), list()}
  @type plan_step :: {atom(), list()}

  ## Public API

  @doc """
  Creates a new planning domain with the given name.
  """
  @spec create_domain(String.t()) :: domain()
  def create_domain(name \\ "default") do
    Domain.new(name)
  end

  @doc """
  Creates a new empty planning state.
  """
  @spec create_state() :: state()
  def create_state do
    State.new()
  end

  @doc """
  Creates a new multigoal.
  """
  @spec create_multigoal() :: multigoal()
  def create_multigoal do
    Multigoal.new()
  end

  @doc """
  Sets a fact (predicate-subject-object triple) in the state.
  """
  @spec set_fact(state(), String.t(), String.t(), any()) :: state()
  def set_fact(%State{} = state, predicate, subject, object) do
    State.set_object(state, predicate, subject, object)
  end

  @doc """
  Gets a fact from the state.
  """
  @spec get_fact(state(), String.t(), String.t()) :: any() | nil
  def get_fact(%State{} = state, predicate, subject) do
    State.get_object(state, predicate, subject)
  end

  @doc """
  Adds an action to a domain.
  """
  @spec add_action(domain(), atom(), Domain.action_fn()) :: domain()
  def add_action(%Domain{} = domain, name, action_fn) do
    Domain.add_action(domain, name, action_fn)
  end

  @doc """
  Adds a task method to a domain.
  """
  @spec add_task_method(domain(), String.t(), Domain.task_method_fn()) :: domain()
  def add_task_method(%Domain{} = domain, task_name, method_fn) do
    Domain.add_task_method(domain, task_name, method_fn)
  end

  @doc """
  Adds a unigoal method to a domain.
  """
  @spec add_unigoal_method(domain(), String.t(), Domain.goal_method_fn()) :: domain()
  def add_unigoal_method(%Domain{} = domain, goal_type, method_fn) do
    Domain.add_unigoal_method(domain, goal_type, method_fn)
  end

  @doc """
  Adds a multigoal method to a domain.
  """
  @spec add_multigoal_method(domain(), Domain.goal_method_fn()) :: domain()
  def add_multigoal_method(%Domain{} = domain, method_fn) do
    Domain.add_multigoal_method(domain, method_fn)
  end

  @doc """
  Creates a goal from predicate, subject, and object.
  """
  @spec create_goal(String.t(), String.t(), any()) :: goal()
  def create_goal(predicate, subject, object) do
    {predicate, subject, object}
  end

  @doc """
  Creates a task from name and arguments.
  """
  @spec create_task(String.t(), list()) :: task()
  def create_task(name, args \\ []) do
    {name, args}
  end

  @doc """
  Main planning interface - finds a plan to achieve the given todos.
  
  ## Options
  - `:max_depth` - Maximum planning depth (default: 100)
  - `:verbose` - Verbosity level (default: 0)
  """
  @spec plan(domain(), state(), [goal() | task() | multigoal()], keyword()) :: 
    {:ok, [plan_step()]} | {:error, String.t()}
  def plan(%Domain{} = domain, %State{} = state, todos, opts \\ []) do
    Plan.plan(domain, state, todos, opts)
  end

  @doc """
  Executes a plan step by step, returning the final state.
  """
  @spec execute_plan(domain(), state(), [plan_step()]) :: {:ok, state()} | {:error, String.t()}
  def execute_plan(%Domain{} = domain, %State{} = initial_state, plan) do
    Plan.validate_plan(domain, initial_state, plan)
  end

  @doc """
  Validates whether goals are satisfied in the given state.
  """
  @spec goals_satisfied?(state(), [goal()]) :: boolean()
  def goals_satisfied?(%State{} = state, goals) do
    Enum.all?(goals, fn {predicate, subject, object} ->
      State.get_object(state, predicate, subject) == object
    end)
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
  @spec domain_summary(domain()) :: map()
  def domain_summary(%Domain{} = domain) do
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
  @spec state_to_triples(state()) :: [{String.t(), String.t(), any()}]
  def state_to_triples(%State{} = state) do
    State.to_triples(state)
  end

  @doc """
  Creates a state from a list of triples.
  """
  @spec state_from_triples([{String.t(), String.t(), any()}]) :: state()
  def state_from_triples(triples) do
    State.from_triples(triples)
  end



end
