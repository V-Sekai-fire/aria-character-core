# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain do
  @moduledoc """
  Represents a planning domain in the GTPyhop planner.

  A domain contains:
  - Actions: Functions that modify the world state
  - Task methods: Functions that decompose tasks into subtasks
  - Unigoal methods: Functions that achieve single goals
  - Multigoal methods: Functions that achieve multiple goals simultaneously

  Example:
  ```elixir
  domain = AriaEngine.Domain.new("logistics")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)
  |> AriaEngine.Domain.add_task_method("transport", [&transport_by_truck/2, &transport_by_plane/2])
  """

  alias AriaEngine.State

  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type action_fn :: (State.t(), list() -> State.t() | false)
  @type task_method_fn :: (State.t(), list() -> list() | false)
  @type goal_method_fn :: (State.t(), list() -> list() | false)

  @type t :: %__MODULE__{
    name: String.t(),
    actions: %{action_name() => action_fn()},
    task_methods: %{task_name() => [task_method_fn()]},
    unigoal_methods: %{String.t() => [goal_method_fn()]},
    multigoal_methods: [goal_method_fn()]
  }

  defstruct name: "",
            actions: %{},
            task_methods: %{},
            unigoal_methods: %{},
            multigoal_methods: []

  @doc """
  Creates a new planning domain.
  """
  @spec new(String.t()) :: t()
  def new(name \\ "default") do
    %__MODULE__{name: name}
  end

  @doc """
  Adds an action to the domain.

  Actions are functions that take a state and arguments, returning either:
  - A new state (success)
  - false (failure)
  """
  @spec add_action(t(), action_name(), action_fn()) :: t()
  def add_action(%__MODULE__{actions: actions} = domain, name, action_fn)
      when is_atom(name) and is_function(action_fn, 2) do
    %{domain | actions: Map.put(actions, name, action_fn)}
  end

  @doc """
  Adds multiple actions to the domain.
  """
  @spec add_actions(t(), %{action_name() => action_fn()}) :: t()
  def add_actions(%__MODULE__{actions: current_actions} = domain, new_actions) do
    %{domain | actions: Map.merge(current_actions, new_actions)}
  end

  @doc """
  Adds a task method to the domain.

  Task methods decompose tasks into subtasks/actions/goals.
  """
  @spec add_task_method(t(), task_name(), task_method_fn()) :: t()
  def add_task_method(%__MODULE__{task_methods: methods} = domain, task_name, method_fn)
      when is_binary(task_name) and is_function(method_fn, 2) do
    current_methods = Map.get(methods, task_name, [])
    updated_methods = current_methods ++ [method_fn]
    %{domain | task_methods: Map.put(methods, task_name, updated_methods)}
  end

  @doc """
  Adds multiple task methods for a task.
  """
  @spec add_task_methods(t(), task_name(), [task_method_fn()]) :: t()
  def add_task_methods(%__MODULE__{} = domain, task_name, method_fns)
      when is_binary(task_name) and is_list(method_fns) do
    Enum.reduce(method_fns, domain, fn method_fn, acc_domain ->
      add_task_method(acc_domain, task_name, method_fn)
    end)
  end

  @doc """
  Adds a unigoal method to the domain.

  Unigoal methods achieve single predicate-based goals.
  """
  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%__MODULE__{unigoal_methods: methods} = domain, goal_type, method_fn)
      when is_binary(goal_type) and is_function(method_fn, 2) do
    current_methods = Map.get(methods, goal_type, [])
    updated_methods = current_methods ++ [method_fn]
    %{domain | unigoal_methods: Map.put(methods, goal_type, updated_methods)}
  end

  @doc """
  Adds multiple unigoal methods for a goal type.
  """
  @spec add_unigoal_methods(t(), String.t(), [goal_method_fn()]) :: t()
  def add_unigoal_methods(%__MODULE__{} = domain, goal_type, method_fns)
      when is_binary(goal_type) and is_list(method_fns) do
    Enum.reduce(method_fns, domain, fn method_fn, acc_domain ->
      add_unigoal_method(acc_domain, goal_type, method_fn)
    end)
  end

  @doc """
  Adds a multigoal method to the domain.

  Multigoal methods work on achieving multiple goals simultaneously.
  """
  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  def add_multigoal_method(%__MODULE__{multigoal_methods: methods} = domain, method_fn)
      when is_function(method_fn, 2) do
    %{domain | multigoal_methods: [method_fn | methods]}
  end

  @doc """
  Adds multiple multigoal methods.
  """
  @spec add_multigoal_methods(t(), [goal_method_fn()]) :: t()
  def add_multigoal_methods(%__MODULE__{} = domain, method_fns) when is_list(method_fns) do
    Enum.reduce(method_fns, domain, fn method_fn, acc_domain ->
      add_multigoal_method(acc_domain, method_fn)
    end)
  end

  @doc """
  Gets an action function by name.
  """
  @spec get_action(t(), action_name()) :: action_fn() | nil
  def get_action(%__MODULE__{actions: actions}, name) do
    Map.get(actions, name)
  end

  @doc """
  Gets task methods for a task name.
  """
  @spec get_task_methods(t(), task_name()) :: [task_method_fn()]
  def get_task_methods(%__MODULE__{task_methods: methods}, task_name) do
    Map.get(methods, task_name, [])
  end

  @doc """
  Gets unigoal methods for a goal type.
  """
  @spec get_unigoal_methods(t(), String.t()) :: [goal_method_fn()]
  def get_unigoal_methods(%__MODULE__{unigoal_methods: methods}, goal_type) do
    Map.get(methods, goal_type, [])
  end

  @doc """
  Gets all multigoal methods.
  """
  @spec get_multigoal_methods(t()) :: [goal_method_fn()]
  def get_multigoal_methods(%__MODULE__{multigoal_methods: methods}) do
    methods
  end

  @doc """
  Checks if an action exists in the domain.
  """
  @spec has_action?(t(), action_name()) :: boolean()
  def has_action?(%__MODULE__{actions: actions}, name) do
    Map.has_key?(actions, name)
  end

  @doc """
  Checks if task methods exist for a task.
  """
  @spec has_task_methods?(t(), task_name()) :: boolean()
  def has_task_methods?(%__MODULE__{task_methods: methods}, task_name) do
    case Map.get(methods, task_name) do
      nil -> false
      [] -> false
      _ -> true
    end
  end

  @doc """
  Checks if unigoal methods exist for a goal type.
  """
  @spec has_unigoal_methods?(t(), String.t()) :: boolean()
  def has_unigoal_methods?(%__MODULE__{unigoal_methods: methods}, goal_type) do
    case Map.get(methods, goal_type) do
      nil -> false
      [] -> false
      _ -> true
    end
  end

  @doc """
  Executes an action with the given state and arguments.
  """
  @spec execute_action(t(), State.t(), action_name(), list()) :: {:ok, State.t()} | false
  def execute_action(%__MODULE__{} = domain, %State{} = state, action_name, args) do
    case get_action(domain, action_name) do
      nil ->
        false

      action_fn ->
        case action_fn.(state, args) do
          false ->
            false
          %State{} = new_state ->
            {:ok, new_state}
        end
    end
  end

  @doc """
  Validates that a goal is satisfied in the given state.

  This is used for goal verification during planning.
  """
  @spec verify_goal(State.t(), String.t(), String.t(), list(), any(), integer(), integer()) :: any()
  def verify_goal(%State{} = state, _method_name, state_var, args, desired_values, _depth, _verbose) do
    # This is a placeholder for goal verification logic
    # In the original C++ code, this would check if a goal is satisfied
    case State.get_object(state, state_var, List.first(args) || "") do
      ^desired_values -> desired_values
      _ -> false
    end
  end

  @doc """
  Gets a summary of the domain contents.
  """
  @spec summary(t()) :: %{
    name: String.t(),
    actions: [action_name()],
    task_methods: [task_name()],
    unigoal_methods: [String.t()],
    multigoal_method_count: non_neg_integer()
  }
  def summary(%__MODULE__{} = domain) do
    %{
      name: domain.name,
      actions: Map.keys(domain.actions),
      task_methods: Map.keys(domain.task_methods),
      unigoal_methods: Map.keys(domain.unigoal_methods),
      multigoal_method_count: length(domain.multigoal_methods)
    }
  end

  @doc """
  Adds Porcelain-based actions to the domain.

  This convenience method adds all the external process actions from AriaEngine.Actions.
  """
  @spec add_porcelain_actions(t()) :: t()
  def add_porcelain_actions(%__MODULE__{} = domain) do
    alias AriaEngine.Actions

    porcelain_actions = %{
      execute_command: &Actions.execute_command/2,
      copy_file: &Actions.copy_file/2,
      move_file: &Actions.move_file/2,
      create_directory: &Actions.create_directory/2,
      remove_path: &Actions.remove_path/2,
      download_file: &Actions.download_file/2,
      change_permissions: &Actions.change_permissions/2
    }

    add_actions(domain, porcelain_actions)
  end

  # These convenience methods are commented out to avoid hard dependencies on domain modules
  # Domain-specific modules should define their own methods in their create_domain/0 functions

  # @doc """
  # Adds file management methods to the domain.
  # This convenience method adds all the file management task methods.
  # """
  # @spec add_file_management_methods(t()) :: t()
  # def add_file_management_methods(%__MODULE__{} = domain) do
  #   # Implementation moved to AriaFileManagement.create_domain/0
  # end

  # @doc """
  # Adds workflow system methods to the domain.
  # This convenience method adds all the workflow system task methods.
  # """
  # @spec add_workflow_system_methods(t()) :: t()
  # def add_workflow_system_methods(%__MODULE__{} = domain) do
  #   # Implementation moved to AriaWorkflowSystem.create_domain/0
  # end

  @doc """
  Creates a complete domain with all Porcelain-based actions and methods.

  This is a convenience method for creating a fully-featured domain with basic actions.
  Domain-specific methods should be added by the respective domain modules.
  """
  @spec create_complete_domain(String.t()) :: t()
  def create_complete_domain(name \\ "complete") do
    new(name)
    |> add_porcelain_actions()
    # Domain-specific methods are added by each domain module in their create_domain/0 functions
  end
end
