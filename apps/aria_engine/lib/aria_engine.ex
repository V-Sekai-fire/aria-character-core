defmodule AriaEngine do
  @moduledoc """
  Aria Engine - Classical AI Planning & Goal-Task Network (GTN) Planning

  This module provides the main interface for the Aria Engine service, which implements
  IPyHOP-style hierarchical task network planning with reentrant capabilities and
  Run-Lazy-Refineahead execution. It handles character AI decision-making, goal planning,
  and task execution for generated characters.

  ## Core Components

  - `AriaEngine.State`: Manages world state using predicate-subject-fact triples
  - `AriaEngine.Domain`: Contains actions, tasks, and planning methods
  - `AriaEngine.Plan`: IPyHOP-style HTN planning with solution trees
  - `AriaEngine.Multigoal`: Represents collections of goals to achieve

  ## Planning Integration

  This module serves as a top-level wrapper around the sophisticated planning capabilities,
  providing both simple interfaces for basic use cases and advanced interfaces for
  complex planning scenarios with replanning and hierarchical decomposition.
  """

  alias AriaEngine.{Core, DomainAPI, GoalAPI, Planning, Info, Convenience, Validation}

  # Core types
  @type t :: Core.t()
  @type domain :: Core.domain()
  @type state :: Core.state()
  @type multigoal :: Core.multigoal()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type goal :: Core.goal()
  @type task :: Core.task()
  @type todo_item :: Core.todo_item()
  @type action_fn :: Core.action_fn()
  @type task_method_fn :: Core.task_method_fn()
  @type goal_method_fn :: Core.goal_method_fn()
  @type status :: Core.status()
  @type plan_result :: Core.plan_result()
  @type execution_result :: Core.execution_result()

  # Core API
  @doc """
  Creates a new AriaEngine definition with capabilities and goals.
  """
  @spec new(String.t(), map()) :: t()
  def new(id, definition \\ %{}), do: Core.new(id, definition)

  # Domain Building API
  @doc """
  Creates an AriaEngine definition from an existing Domain.
  """
  @spec from_domain(Domain.t(), [todo_item()], State.t() | nil) :: t()
  def from_domain(domain, goals, initial_state \\ nil), do: DomainAPI.from_domain(domain, goals, initial_state)

  @doc """
  Converts an AriaEngine definition to a Domain (capabilities only).
  """
  @spec to_domain(t()) :: Domain.t()
  def to_domain(engine), do: DomainAPI.to_domain(engine)

  @doc """
  Adds an action to the AriaEngine definition.
  """
  @spec add_action(t(), atom(), action_fn()) :: t()
  def add_action(engine, name, action_fn), do: DomainAPI.add_action(engine, name, action_fn)

  @doc """
  Adds multiple actions to the definition.
  """
  @spec add_actions(t(), %{atom() => action_fn()}) :: t()
  def add_actions(engine, new_actions), do: DomainAPI.add_actions(engine, new_actions)

  @doc """
  Adds a task method to the definition.
  """
  @spec add_task_method(t(), String.t(), task_method_fn()) :: t()
  def add_task_method(engine, task_name, method_fn), do: DomainAPI.add_task_method(engine, task_name, method_fn)

  @doc """
  Adds multiple task methods for a task.
  """
  @spec add_task_methods(t(), String.t(), [task_method_fn()]) :: t()
  def add_task_methods(engine, task_name, method_fns), do: DomainAPI.add_task_methods(engine, task_name, method_fns)

  @doc """
  Adds a unigoal method to the definition.
  """
  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(engine, goal_type, method_fn), do: DomainAPI.add_unigoal_method(engine, goal_type, method_fn)

  @doc """
  Adds multiple unigoal methods for a goal type.
  """
  @spec add_unigoal_methods(t(), String.t(), [goal_method_fn()]) :: t()
  def add_unigoal_methods(engine, goal_type, method_fns), do: DomainAPI.add_unigoal_methods(engine, goal_type, method_fns)

  @doc """
  Adds a multigoal method to the definition.
  """
  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  def add_multigoal_method(engine, method_fn), do: DomainAPI.add_multigoal_method(engine, method_fn)

  @doc """
  Adds multiple multigoal methods.
  """
  @spec add_multigoal_methods(t(), [goal_method_fn()]) :: t()
  def add_multigoal_methods(engine, method_fns), do: DomainAPI.add_multigoal_methods(engine, method_fns)

  # Goal Management API
  @doc """
  Sets the initial state for planning.
  """
  @spec set_initial_state(t(), State.t()) :: t()
  def set_initial_state(engine, state), do: GoalAPI.set_initial_state(engine, state)

  @doc """
  Adds a goal to the definition.
  """
  @spec add_goal(t(), todo_item()) :: t()
  def add_goal(engine, goal), do: GoalAPI.add_goal(engine, goal)

  @doc """
  Adds multiple goals to the definition.
  """
  @spec add_goals(t(), [todo_item()]) :: t()
  def add_goals(engine, new_goals), do: GoalAPI.add_goals(engine, new_goals)

  @doc """
  Sets goals (replaces existing goals).
  """
  @spec set_goals(t(), [todo_item()]) :: t()
  def set_goals(engine, goals), do: GoalAPI.set_goals(engine, goals)

  # Planning and Execution API
  @doc """
  Plans the goals using IPyHOP-style HTN planning.
  """
  @spec plan_advanced(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def plan_advanced(engine, opts \\ []), do: Planning.plan_advanced(engine, opts)

  @doc """
  Executes the planned solution using Run-Lazy-Refineahead.
  """
  @spec execute(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def execute(engine, opts \\ []), do: Planning.execute(engine, opts)

  @doc """
  Plans and executes in one step.
  """
  @spec run(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def run(engine, opts \\ []), do: Planning.run(engine, opts)

  @doc """
  Simple planning interface - finds a plan to achieve the given todos.
  """
  @spec plan(domain(), state(), [todo_item()], keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def plan(domain, state, todos, opts \\ []), do: Planning.plan(domain, state, todos, opts)

  @doc """
  Advanced planning interface - returns the full solution tree.
  """
  @spec plan_with_tree(domain(), state(), [todo_item()], keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(domain, state, todos, opts \\ []), do: Planning.plan_with_tree(domain, state, todos, opts)

  @doc """
  Executes a plan step by step, returning the final state.
  """
  @spec execute_plan(domain(), state(), [plan_step()]) :: {:ok, state()} | {:error, String.t()}
  def execute_plan(domain, initial_state, plan), do: Planning.execute_plan(domain, initial_state, plan)

  # Replanning and Advanced Features
  @doc """
  Replan from a failure point using AriaEngine.Planner.
  """
  @spec replan(t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\ []), do: Planning.replan(engine, fail_node_id, opts)

  @doc """
  Validate the current plan.
  """
  @spec validate_plan(t()) :: {:ok, State.t()} | {:error, String.t()}
  def validate_plan(engine), do: Planning.validate_plan(engine)

  # Information and Status API
  @doc """
  Gets the current status of the engine.
  """
  @spec get_status(t()) :: status()
  def get_status(engine), do: Info.get_status(engine)

  @doc """
  Gets the current state.
  """
  @spec get_current_state(t()) :: State.t()
  def get_current_state(engine), do: Info.get_current_state(engine)

  @doc """
  Gets the final state (if completed).
  """
  @spec get_final_state(t()) :: State.t() | nil
  def get_final_state(engine), do: Info.get_final_state(engine)

  @doc """
  Gets the solution tree (if available).
  """
  @spec get_solution_tree(t()) :: solution_tree() | nil
  def get_solution_tree(engine), do: Info.get_solution_tree(engine)

  @doc """
  Gets the current goals.
  """
  @spec get_goals(t()) :: [todo_item()]
  def get_goals(engine), do: Info.get_goals(engine)

  @doc """
  Checks if execution is completed.
  """
  @spec completed?(t()) :: boolean()
  def completed?(engine), do: Info.completed?(engine)

  @doc """
  Gets execution progress as a percentage.
  """
  @spec progress(t()) :: float()
  def progress(engine), do: Info.progress(engine)

  @doc """
  Gets detailed plan statistics from the solution tree.
  """
  @spec get_plan_stats(t()) :: map()
  def get_plan_stats(engine), do: Info.get_plan_stats(engine)

  @doc """
  Gets the planned actions from the solution tree.
  """
  @spec get_planned_actions(t()) :: [plan_step()]
  def get_planned_actions(engine), do: Info.get_planned_actions(engine)

  @doc """
  Gets execution summary with Plan module integration.
  """
  @spec get_summary(t()) :: map()
  def get_summary(engine), do: Info.get_summary(engine)

  @doc """
  Gets execution trace from the Plan module's solution tree.
  """
  @spec get_trace_log(t()) :: String.t()
  def get_trace_log(engine), do: Info.get_trace_log(engine)

  @doc """
  Updates the current state.
  """
  @spec update_state(t(), State.t()) :: t()
  def update_state(engine, new_state), do: Info.update_state(engine, new_state)

  # Convenience API for State and Domain operations
  @doc """
  Creates a new empty planning state.
  """
  @spec create_state() :: state()
  def create_state(), do: Convenience.create_state()

  @doc """
  Creates a new planning domain with the given name.
  """
  @spec create_domain(String.t()) :: domain()
  def create_domain(name \\ "default"), do: Convenience.create_domain(name)

  @doc """
  Creates a new multigoal.
  """
  @spec create_multigoal() :: multigoal()
  def create_multigoal(), do: Convenience.create_multigoal()

  @doc """
  Sets a fact (predicate-subject-fact triple) in the state.
  """
  @spec set_fact(state(), String.t(), String.t(), State.fact_value()) :: state()
  def set_fact(state, predicate, subject, fact_value), do: Convenience.set_fact(state, predicate, subject, fact_value)

  @doc """
  Gets a fact from the state.
  """
  @spec get_fact(state(), String.t(), String.t()) :: State.fact_value() | nil
  def get_fact(state, predicate, subject), do: Convenience.get_fact(state, predicate, subject)

  @doc """
  Gets the cost (number of steps) of a plan.
  """
  @spec plan_cost([plan_step()]) :: non_neg_integer()
  def plan_cost(plan), do: Convenience.plan_cost(plan)

  @doc """
  Gets a summary of domain capabilities.
  """
  @spec domain_summary(domain()) :: map()
  def domain_summary(domain), do: Convenience.domain_summary(domain)

  @doc """
  Merges two states, with the second taking precedence for conflicts.
  """
  @spec merge_states(state(), state()) :: state()
  def merge_states(state1, state2), do: Convenience.merge_states(state1, state2)

  @doc """
  Converts a state to a list of triples for inspection.
  """
  @spec state_to_triples(state()) :: [{String.t(), String.t(), State.fact_value()}]
  def state_to_triples(state), do: Convenience.state_to_triples(state)

  @doc """
  Creates a state from a list of triples.
  """
  @spec state_from_triples([{String.t(), String.t(), State.fact_value()}]) :: state()
  def state_from_triples(triples), do: Convenience.state_from_triples(triples)

  # Validation
  @doc """
  Validates the AriaEngine definition.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(engine), do: Validation.validate(engine)

  # Domain Composition and Registry Integration
  @doc """
  Creates an AriaEngine definition by composing multiple domains from the registry.
  """
  @spec from_domain_types(String.t(), [String.t()], [todo_item()], State.t() | nil) ::
    {:ok, t()} | {:error, String.t()}
  def from_domain_types(id, domain_types, goals, initial_state \\ nil), do: DomainAPI.from_domain_types(id, domain_types, goals, initial_state)

  @doc """
  Adds a domain type to an existing AriaEngine definition.
  """
  @spec add_domain_type(t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def add_domain_type(engine, domain_type), do: DomainAPI.add_domain_type(engine, domain_type)

  @doc """
  Lists available domain types in the registry.
  """
  @spec list_domain_types() :: [String.t()]
  def list_domain_types(), do: DomainAPI.list_domain_types()

  @doc """
  Validates a domain type exists in the registry.
  """
  @spec validate_domain_type(String.t()) :: :ok | {:error, String.t()}
  def validate_domain_type(domain_type), do: DomainAPI.validate_domain_type(domain_type)

  # Merges method maps, concatenating lists for the same key
  def merge_method_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, methods1, methods2 ->
      methods1 ++ methods2
    end)
  end
end
