# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine do
  @moduledoc """
  Aria Engine - Classical AI Planning & Goal-Task Network (GTN) Planning

  This module provides the main interface for the Aria Engine service, which implements
  IPyHOP-style hierarchical task network planning with reentrant capabilities and
  Run-Lazy-Refineahead execution. It handles character AI decision-making, goal planning,
  and task execution for generated characters.

  ## Core Components

  - `AriaEngine.State`: Manages world state using predicate-subject-object triples
  - `AriaEngine.Domain`: Contains actions, tasks, and planning methods
  - `AriaEngine.Plan`: IPyHOP-style HTN planning with solution trees
  - `AriaEngine.Multigoal`: Represents collections of goals to achieve

  ## Planning Integration

  This module serves as a top-level wrapper around the sophisticated planning capabilities,
  providing both simple interfaces for basic use cases and advanced interfaces for
  complex planning scenarios with replanning and hierarchical decomposition.

  ## Usage Example

  ```elixir
  # Initialize the engine
  AriaEngine.init()

  # Simple planning interface
  definition = AriaEngine.new("rpg_character")
  |> AriaEngine.add_action(:move, &RPGActions.move/2)
  |> AriaEngine.add_task_method("get_item", [&RPGMethods.get_item_nearby/2])
  |> AriaEngine.add_goals([{"has", "player", "sword"}])
  |> AriaEngine.set_initial_state(initial_state)

  # Plan and execute with automatic replanning
  case AriaEngine.run(definition) do
    {:ok, completed} ->
      IO.puts("Execution completed successfully")
      final_state = AriaEngine.get_final_state(completed)
    {:error, reason} ->
      IO.puts("Execution failed: \#{reason}")
  end

  # Advanced planning with solution trees
  case AriaEngine.plan_advanced(definition) do
    {:ok, planned} ->
      tree_stats = AriaEngine.get_plan_stats(planned)
      IO.puts("Plan has \#{tree_stats.primitive_actions} actions")
    {:error, reason} ->
      IO.puts("Planning failed: \#{reason}")
  end
  ```
  """

  alias AriaEngine.{Domain, State, Multigoal, Plan, Planner, DomainProvider}

  # Core types
  @type domain :: Domain.t()
  @type state :: State.t()
  @type multigoal :: Multigoal.t()
  @type solution_tree :: Plan.solution_tree()
  @type plan_step :: Plan.plan_step()

  # Goal and task types
  @type goal :: {String.t(), String.t(), any()}
  @type task :: {String.t(), list()}
  @type todo_item :: Plan.todo_item()

  # Function types
  @type action_fn :: (State.t(), list() -> State.t() | false)
  @type task_method_fn :: (State.t(), list() -> list() | false)
  @type goal_method_fn :: (State.t(), list() -> list() | false)

  # Status and execution types
  @type status :: :pending | :planning | :executing | :completed | :failed | :cancelled
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, t()} | {:error, String.t()}

  # Main AriaEngine definition type
  @type t :: %__MODULE__{
    # Identity
    id: String.t(),
    name: String.t(),
    execution_id: reference() | nil,

    # Domain Capabilities
    actions: %{atom() => action_fn()},
    task_methods: %{String.t() => [task_method_fn()]},
    unigoal_methods: %{String.t() => [goal_method_fn()]},
    multigoal_methods: [goal_method_fn()],

    # Planning Goals
    goals: [todo_item()],

    # Execution State
    current_state: State.t(),
    initial_state: State.t(),
    status: status(),
    solution_tree: solution_tree() | nil,

    # Execution Progress
    progress: %{
      total_steps: non_neg_integer(),
      completed_steps: non_neg_integer(),
      current_step: String.t() | nil
    },
    error: term() | nil,

    # Metadata
    documentation: %{atom() => String.t()},
    metadata: %{atom() => term()},
    created_at: DateTime.t(),
    started_at: DateTime.t() | nil,
    completed_at: DateTime.t() | nil
  }

  defstruct [
    # Identity
    :id,
    :name,
    execution_id: nil,

    # Domain Capabilities
    actions: %{},
    task_methods: %{},
    unigoal_methods: %{},
    multigoal_methods: [],

    # Planning Goals
    goals: [],

    # Execution State
    current_state: nil,
    initial_state: nil,
    status: :pending,
    solution_tree: nil,

    # Execution Progress
    progress: %{total_steps: 0, completed_steps: 0, current_step: nil},
    error: nil,

    # Metadata
    documentation: %{},
    metadata: %{},
    created_at: nil,
    started_at: nil,
    completed_at: nil
  ]

  ## Creation and Configuration API

  @doc """
  Creates a new AriaEngine definition with capabilities and goals.
  """
  @spec new(String.t(), map()) :: t()
  def new(id, definition \\ %{}) do
    now = DateTime.utc_now()
    initial_state = Map.get(definition, :initial_state, State.new())

    %__MODULE__{
      id: id,
      name: Map.get(definition, :name, id),
      actions: Map.get(definition, :actions, %{}),
      task_methods: Map.get(definition, :task_methods, %{}),
      unigoal_methods: Map.get(definition, :unigoal_methods, %{}),
      multigoal_methods: Map.get(definition, :multigoal_methods, []),
      goals: Map.get(definition, :goals, []),
      current_state: initial_state,
      initial_state: initial_state,
      documentation: Map.get(definition, :documentation, %{}),
      metadata: Map.get(definition, :metadata, %{}),
      created_at: now
    }
  end

  @doc """
  Creates an AriaEngine definition from an existing Domain.
  """
  @spec from_domain(Domain.t(), [todo_item()], State.t()) :: t()
  def from_domain(%Domain{} = domain, goals, initial_state \\ nil) do
    initial_state = initial_state || State.new()

    new(domain.name, %{
      name: domain.name,
      actions: domain.actions,
      task_methods: domain.task_methods,
      unigoal_methods: domain.unigoal_methods,
      multigoal_methods: domain.multigoal_methods,
      goals: goals,
      initial_state: initial_state
    })
  end

  @doc """
  Converts an AriaEngine definition to a Domain (capabilities only).
  """
  @spec to_domain(t()) :: Domain.t()
  def to_domain(%__MODULE__{} = engine) do
    %Domain{
      name: engine.name,
      actions: engine.actions,
      task_methods: engine.task_methods,
      unigoal_methods: engine.unigoal_methods,
      multigoal_methods: engine.multigoal_methods
    }
  end

  ## Domain Building API

  @doc """
  Adds an action to the AriaEngine definition.
  """
  @spec add_action(t(), atom(), action_fn()) :: t()
  def add_action(%__MODULE__{actions: actions} = engine, name, action_fn)
      when is_atom(name) and is_function(action_fn, 2) do
    %{engine | actions: Map.put(actions, name, action_fn)}
  end

  @doc """
  Adds multiple actions to the definition.
  """
  @spec add_actions(t(), %{atom() => action_fn()}) :: t()
  def add_actions(%__MODULE__{actions: current_actions} = engine, new_actions) do
    %{engine | actions: Map.merge(current_actions, new_actions)}
  end

  @doc """
  Adds a task method to the definition.
  """
  @spec add_task_method(t(), String.t(), task_method_fn()) :: t()
  def add_task_method(%__MODULE__{task_methods: methods} = engine, task_name, method_fn)
      when is_binary(task_name) and is_function(method_fn, 2) do
    current_methods = Map.get(methods, task_name, [])
    updated_methods = current_methods ++ [method_fn]
    %{engine | task_methods: Map.put(methods, task_name, updated_methods)}
  end

  @doc """
  Adds multiple task methods for a task.
  """
  @spec add_task_methods(t(), String.t(), [task_method_fn()]) :: t()
  def add_task_methods(%__MODULE__{} = engine, task_name, method_fns)
      when is_binary(task_name) and is_list(method_fns) do
    Enum.reduce(method_fns, engine, fn method_fn, acc_engine ->
      add_task_method(acc_engine, task_name, method_fn)
    end)
  end

  @doc """
  Adds a unigoal method to the definition.
  """
  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%__MODULE__{unigoal_methods: methods} = engine, goal_type, method_fn)
      when is_binary(goal_type) and is_function(method_fn, 2) do
    current_methods = Map.get(methods, goal_type, [])
    updated_methods = current_methods ++ [method_fn]
    %{engine | unigoal_methods: Map.put(methods, goal_type, updated_methods)}
  end

  @doc """
  Adds multiple unigoal methods for a goal type.
  """
  @spec add_unigoal_methods(t(), String.t(), [goal_method_fn()]) :: t()
  def add_unigoal_methods(%__MODULE__{} = engine, goal_type, method_fns)
      when is_binary(goal_type) and is_list(method_fns) do
    Enum.reduce(method_fns, engine, fn method_fn, acc_engine ->
      add_unigoal_method(acc_engine, goal_type, method_fn)
    end)
  end

  @doc """
  Adds a multigoal method to the definition.
  """
  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  def add_multigoal_method(%__MODULE__{multigoal_methods: methods} = engine, method_fn)
      when is_function(method_fn, 2) do
    %{engine | multigoal_methods: [method_fn | methods]}
  end

  @doc """
  Adds multiple multigoal methods.
  """
  @spec add_multigoal_methods(t(), [goal_method_fn()]) :: t()
  def add_multigoal_methods(%__MODULE__{} = engine, method_fns) when is_list(method_fns) do
    Enum.reduce(method_fns, engine, fn method_fn, acc_engine ->
      add_multigoal_method(acc_engine, method_fn)
    end)
  end

  ## Goal Management API

  @doc """
  Sets the initial state for planning.
  """
  @spec set_initial_state(t(), State.t()) :: t()
  def set_initial_state(%__MODULE__{} = engine, %State{} = state) do
    %{engine | initial_state: state, current_state: state}
  end

  @doc """
  Adds a goal to the definition.
  """
  @spec add_goal(t(), todo_item()) :: t()
  def add_goal(%__MODULE__{goals: goals} = engine, goal) do
    %{engine | goals: goals ++ [goal]}
  end

  @doc """
  Adds multiple goals to the definition.
  """
  @spec add_goals(t(), [todo_item()]) :: t()
  def add_goals(%__MODULE__{goals: goals} = engine, new_goals) do
    %{engine | goals: goals ++ new_goals}
  end

  @doc """
  Sets goals (replaces existing goals).
  """
  @spec set_goals(t(), [todo_item()]) :: t()
  def set_goals(%__MODULE__{} = engine, goals) do
    %{engine | goals: goals}
  end

  ## Planning and Execution API

  @doc """
  Plans the goals using IPyHOP-style HTN planning.
  """
  @spec plan_advanced(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def plan_advanced(%__MODULE__{status: :pending} = engine, opts \\ []) do
    domain_interface = to_planner_interface(engine)

    case Planner.plan(domain_interface, engine.initial_state, engine.goals, opts) do
      {:ok, solution_tree} ->
        planned_engine = %{engine |
          status: :executing,
          started_at: DateTime.utc_now(),
          solution_tree: solution_tree,
          progress: %{engine.progress |
            total_steps: Planner.plan_cost(solution_tree)
          }
        }

        {:ok, planned_engine}

      {:error, reason} ->
        _failed_engine = %{engine |
          status: :failed,
          error: reason,
          completed_at: DateTime.utc_now()
        }

        {:error, reason}
    end
  end

  @doc """
  Executes the planned solution using Run-Lazy-Refineahead.
  """
  @spec execute(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def execute(engine, opts \\ [])

  def execute(%__MODULE__{status: :executing, solution_tree: solution_tree} = engine, opts)
      when not is_nil(solution_tree) do

    domain_interface = to_planner_interface(engine)

    case Planner.execute(domain_interface, engine.current_state, solution_tree, opts) do
      {:ok, final_state} ->
        completed_engine = %{engine |
          status: :completed,
          current_state: final_state,
          completed_at: DateTime.utc_now(),
          progress: %{engine.progress |
            completed_steps: engine.progress.total_steps,
            current_step: "completed"
          }
        }

        {:ok, completed_engine}

      {:error, reason} ->
        _failed_engine = %{engine |
          status: :failed,
          error: reason,
          completed_at: DateTime.utc_now()
        }

        {:error, reason}
    end
  end

  def execute(%__MODULE__{status: status}, _opts) do
    {:error, "Cannot execute engine in status: #{status}. Must be :executing with a solution tree."}
  end

  @doc """
  Plans and executes in one step.
  """
  @spec run(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def run(%__MODULE__{} = engine, opts \\ []) do
    with {:ok, planned_engine} <- plan_advanced(engine, opts),
         {:ok, completed_engine} <- execute(planned_engine, opts) do
      {:ok, completed_engine}
    end
  end

  ## Simple API for Compatibility

  @doc """
  Simple planning interface - finds a plan to achieve the given todos.

  This is a convenience function that creates a temporary AriaEngine definition
  and extracts just the plan steps for backward compatibility.
  """
  @spec plan(domain(), state(), [todo_item()], keyword()) ::
    {:ok, [plan_step()]} | {:error, String.t()}
  def plan(%Domain{} = domain, %State{} = state, todos, opts \\ []) do
    case Plan.plan(domain, state, todos, opts) do
      {:ok, solution_tree} ->
        actions = Plan.get_primitive_actions_dfs(solution_tree)
        {:ok, actions}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Advanced planning interface - returns the full solution tree.
  """
  @spec plan_with_tree(domain(), state(), [todo_item()], keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(%Domain{} = domain, %State{} = state, todos, opts \\ []) do
    Plan.plan(domain, state, todos, opts)
  end

  @doc """
  Executes a plan step by step, returning the final state.
  """
  @spec execute_plan(domain(), state(), [plan_step()]) :: {:ok, state()} | {:error, String.t()}
  def execute_plan(%Domain{} = domain, %State{} = initial_state, plan) do
    Plan.validate_plan(domain, initial_state, plan)
  end

  ## Replanning and Advanced Features

  @doc """
  Replan from a failure point using AriaEngine.Planner.
  """
  @spec replan(t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\ [])

  def replan(%__MODULE__{solution_tree: solution_tree} = engine, fail_node_id, opts)
      when not is_nil(solution_tree) do

    domain_interface = to_planner_interface(engine)

    case Planner.replan(domain_interface, engine.current_state, solution_tree, fail_node_id, opts) do
      {:ok, new_solution_tree} ->
        updated_engine = %{engine |
          solution_tree: new_solution_tree,
          progress: %{engine.progress |
            total_steps: Planner.plan_cost(new_solution_tree)
          }
        }

        {:ok, updated_engine}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def replan(%__MODULE__{solution_tree: nil}, _fail_node_id, _opts) do
    {:error, "No solution tree available for replanning"}
  end

  @doc """
  Validate the current plan.
  """
  @spec validate_plan(t()) :: {:ok, State.t()} | {:error, String.t()}
  def validate_plan(%__MODULE__{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do

    domain_interface = to_planner_interface(engine)
    Planner.validate_plan(domain_interface, engine.initial_state, solution_tree)
  end

  def validate_plan(%__MODULE__{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end

  ## Information and Status API

  @doc """
  Gets the current status of the engine.
  """
  @spec get_status(t()) :: status()
  def get_status(%__MODULE__{status: status}) do
    status
  end

  @doc """
  Gets the current state.
  """
  @spec get_current_state(t()) :: State.t()
  def get_current_state(%__MODULE__{current_state: state}) do
    state
  end

  @doc """
  Gets the final state (if completed).
  """
  @spec get_final_state(t()) :: State.t() | nil
  def get_final_state(%__MODULE__{status: :completed, current_state: state}) do
    state
  end

  def get_final_state(%__MODULE__{}) do
    nil
  end

  @doc """
  Gets the solution tree (if available).
  """
  @spec get_solution_tree(t()) :: solution_tree() | nil
  def get_solution_tree(%__MODULE__{solution_tree: solution_tree}) do
    solution_tree
  end

  @doc """
  Gets the current goals.
  """
  @spec get_goals(t()) :: [todo_item()]
  def get_goals(%__MODULE__{goals: goals}) do
    goals
  end

  @doc """
  Checks if execution is completed.
  """
  @spec completed?(t()) :: boolean()
  def completed?(%__MODULE__{status: status}) do
    status == :completed
  end

  @doc """
  Gets execution progress as a percentage.
  """
  @spec progress(t()) :: float()
  def progress(%__MODULE__{progress: %{total_steps: 0}}) do
    0.0
  end

  def progress(%__MODULE__{progress: %{total_steps: total, completed_steps: completed}}) do
    min(100.0, (completed / total) * 100.0)
  end

  @doc """
  Gets detailed plan statistics from the solution tree.
  """
  @spec get_plan_stats(t()) :: map()
  def get_plan_stats(%__MODULE__{solution_tree: solution_tree}) when not is_nil(solution_tree) do
    Plan.tree_stats(solution_tree)
  end

  def get_plan_stats(%__MODULE__{solution_tree: nil}) do
    %{error: "No solution tree available"}
  end

  @doc """
  Gets the planned actions from the solution tree.
  """
  @spec get_planned_actions(t()) :: [plan_step()]
  def get_planned_actions(%__MODULE__{solution_tree: nil}) do
    []
  end

  def get_planned_actions(%__MODULE__{solution_tree: solution_tree}) do
    Plan.get_primitive_actions_dfs(solution_tree)
  end

  @doc """
  Gets execution summary with Plan module integration.
  """
  @spec get_summary(t()) :: map()
  def get_summary(%__MODULE__{} = engine) do
    total_duration = case {engine.started_at, engine.completed_at} do
      {%DateTime{} = start_time, %DateTime{} = end_time} ->
        DateTime.diff(end_time, start_time, :millisecond)
      _ -> nil
    end

    tree_stats = case engine.solution_tree do
      nil -> %{}
      solution_tree -> Plan.tree_stats(solution_tree)
    end

    %{
      id: engine.id,
      name: engine.name,
      status: engine.status,
      progress: progress(engine),
      total_goals: length(engine.goals),
      current_goals: length(get_goals(engine)),
      created_at: engine.created_at,
      started_at: engine.started_at,
      completed_at: engine.completed_at,
      duration_ms: total_duration,
      solution_tree: engine.solution_tree != nil,
      tree_stats: tree_stats
    }
  end

  @doc """
  Gets execution trace from the Plan module's solution tree.
  """
  @spec get_trace_log(t()) :: String.t()
  def get_trace_log(%__MODULE__{solution_tree: nil}) do
    "No solution tree available - not planned yet"
  end

  def get_trace_log(%__MODULE__{solution_tree: solution_tree}) do
    actions = Plan.get_primitive_actions_dfs(solution_tree)

    actions
    |> Enum.with_index()
    |> Enum.map(fn {{action_name, args}, index} ->
      "Step #{index + 1}: #{action_name}(#{inspect(args)})"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Updates the current state.
  """
  @spec update_state(t(), State.t()) :: t()
  def update_state(%__MODULE__{} = engine, new_state) do
    %{engine | current_state: new_state}
  end

  ## Convenience API for State and Domain operations

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
  @spec create_domain(String.t()) :: domain()
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

  ## Validation

  @doc """
  Validates the AriaEngine definition.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%__MODULE__{} = engine) do
    errors = []

    errors = if String.trim(engine.id) == "", do: ["Engine ID cannot be empty" | errors], else: errors
    errors = if Enum.empty?(engine.goals), do: ["Engine must have at least one goal" | errors], else: errors
    errors = validate_goals(engine.goals, errors)
    errors = validate_actions(engine.actions, errors)
    errors = validate_task_methods(engine.task_methods, errors)
    errors = validate_unigoal_methods(engine.unigoal_methods, errors)

    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  # Private validation helpers

  defp validate_goals(goals, errors) do
    Enum.reduce(goals, errors, fn goal, acc ->
      case goal do
        {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) ->
          acc  # Valid goal
        {task_name, args} when is_binary(task_name) and is_list(args) ->
          acc  # Valid task
        {action_name, args} when is_atom(action_name) and is_list(args) ->
          acc  # Valid action
        _ ->
          ["Invalid goal format: #{inspect(goal)}" | acc]
      end
    end)
  end

  defp validate_actions(actions, errors) do
    Enum.reduce(actions, errors, fn {name, action_fn}, acc ->
      cond do
        not is_atom(name) -> ["Action name must be atom: #{inspect(name)}" | acc]
        not is_function(action_fn, 2) -> ["Action must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_task_methods(task_methods, errors) do
    Enum.reduce(task_methods, errors, fn {name, method_fns}, acc ->
      cond do
        not is_binary(name) -> ["Task method name must be string: #{inspect(name)}" | acc]
        not is_list(method_fns) -> ["Task methods must be list: #{name}" | acc]
        not Enum.all?(method_fns, &is_function(&1, 2)) -> ["All task methods must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_unigoal_methods(unigoal_methods, errors) do
    Enum.reduce(unigoal_methods, errors, fn {name, method_fns}, acc ->
      cond do
        not is_binary(name) -> ["Unigoal method name must be string: #{inspect(name)}" | acc]
        not is_list(method_fns) -> ["Unigoal methods must be list: #{name}" | acc]
        not Enum.all?(method_fns, &is_function(&1, 2)) -> ["All unigoal methods must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  ## Domain Composition and Registry Integration

  @doc """
  Creates an AriaEngine definition by composing multiple domains from the registry.
  """
  @spec from_domain_types(String.t(), [String.t()], [todo_item()], State.t()) ::
    {:ok, t()} | {:error, String.t()}
  def from_domain_types(id, domain_types, goals, initial_state \\ nil) do
    # For now, we'll get the first domain type and ignore composition
    # TODO: Implement proper domain composition with the new provider system
    case domain_types do
      [] -> {:error, "No domain types provided"}
      [domain_type | _] ->
        case DomainProvider.get_domain(domain_type) do
          {:ok, domain} ->
            initial_state = initial_state || State.new()
            definition = from_domain(domain, goals, initial_state)
            {:ok, %{definition | id: id}}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Adds a domain type to an existing AriaEngine definition.
  """
  @spec add_domain_type(t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def add_domain_type(%__MODULE__{} = engine, domain_type) do
    case DomainProvider.get_domain(domain_type) do
      {:ok, domain} ->
        updated_engine = %{engine |
          actions: Map.merge(engine.actions, domain.actions),
          task_methods: merge_method_maps(engine.task_methods, domain.task_methods),
          unigoal_methods: merge_method_maps(engine.unigoal_methods, domain.unigoal_methods),
          multigoal_methods: engine.multigoal_methods ++ domain.multigoal_methods
        }
        {:ok, updated_engine}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists available domain types in the registry.
  """
  @spec list_domain_types() :: [String.t()]
  def list_domain_types do
    DomainProvider.list_domain_types()
  end

  @doc """
  Validates a domain type exists in the registry.
  """
  @spec validate_domain_type(String.t()) :: :ok | {:error, String.t()}
  def validate_domain_type(domain_type) do
    case DomainProvider.get_domain(domain_type) do
      {:ok, _domain} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  ## Private Helper Functions

  # Converts AriaEngine definition to planner interface format
  @spec to_planner_interface(t()) :: Planner.domain_interface()
  defp to_planner_interface(%__MODULE__{} = engine) do
    %{
      actions: engine.actions,
      task_methods: engine.task_methods,
      unigoal_methods: engine.unigoal_methods,
      multigoal_methods: engine.multigoal_methods
    }
  end

  # Merges method maps, concatenating lists for the same key
  defp merge_method_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, methods1, methods2 ->
      methods1 ++ methods2
    end)
  end

  @doc """
  Initialize the AriaEngine system.

  This validates that domain providers are properly configured.
  """
  @spec init() :: :ok
  def init do
    # Validate that at least one domain provider is configured
    case DomainProvider.get_configured_providers() do
      [] ->
        require Logger
        Logger.warning("No domain providers configured for AriaEngine")
      providers ->
        require Logger
        Logger.info("AriaEngine initialized with #{length(providers)} domain providers")
    end
    :ok
  end
end
