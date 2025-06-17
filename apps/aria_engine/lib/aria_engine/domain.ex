# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain do
  @moduledoc """
  Represents a planning domain in the GTPhop planner (Elixir port of GTPyhop).

  A domain contains:
  - Actions: Named functions that modify the world state
  - Task methods: Named functions that decompose tasks into subtasks
  - Unigoal methods: Named functions that achieve single goals
  - Multigoal methods: Named functions that achieve multiple goals simultaneously

  This implementation aligns with GTPyhop's approach where:
  - Actions are stored as name -> function mappings
  - Methods are stored as task_name -> list of {name, function} tuples
  - Method names are preserved for logging, blacklisting, and error reporting

  Example:
  ```elixir
  domain = AriaEngine.Domain.new("logistics")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)
  |> AriaEngine.Domain.add_task_methods("transport", [
       {"transport_by_truck", &transport_by_truck/2},
       {"transport_by_plane", &transport_by_plane/2}
     ])
  ```
  """

  require Logger
  alias AriaEngine.State
  alias AriaEngine.Actions

  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type action_fn :: (State.t(), list() -> State.t() | false)
  @type task_method_fn :: (State.t(), list() -> list() | false)
  @type goal_method_fn :: (State.t(), list() -> list() | false)
  @type named_method :: {method_name(), task_method_fn() | goal_method_fn()}

  @type t :: %__MODULE__{
    name: String.t(),
    actions: %{action_name() => action_fn()},
    task_methods: %{task_name() => [named_method()]},
    unigoal_methods: %{String.t() => [named_method()]},
    multigoal_methods: [named_method()]
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

  When an action is added, it also creates a corresponding task method
  so the action can be used directly in task decompositions.
  """
  @spec add_action(t(), action_name(), action_fn()) :: t()
  def add_action(%__MODULE__{actions: actions, task_methods: methods} = domain, name, action_fn)
      when is_atom(name) and is_function(action_fn, 2) do
    
    # Add the action to the actions map
    updated_actions = Map.put(actions, name, action_fn)
    
    # Create a task method that just returns the action as a primitive task
    # This allows the action to be used directly in HTN task decompositions
    task_name = Atom.to_string(name)
    primitive_method_fn = fn _state, args -> [{name, args}] end
    method_name = "primitive_#{task_name}"
    
    # Create a {name, function} tuple for the primitive method
    primitive_method = {method_name, primitive_method_fn}
    
    # Add the primitive method to task methods
    current_methods = Map.get(methods, task_name, [])
    updated_methods = [primitive_method | current_methods]  # Put primitive method first
    updated_task_methods = Map.put(methods, task_name, updated_methods)
    
    %{domain | 
      actions: updated_actions, 
      task_methods: updated_task_methods
    }
  end

  @doc """
  Adds multiple actions to the domain.
  
  Each action will be properly registered with its corresponding task method.
  """
  @spec add_actions(t(), %{action_name() => action_fn()}) :: t()
  def add_actions(%__MODULE__{} = domain, new_actions) do
    Enum.reduce(new_actions, domain, fn {name, action_fn}, acc_domain ->
      add_action(acc_domain, name, action_fn)
    end)
  end

  @doc """
  Adds a task method to the domain.

  Task methods decompose tasks into subtasks/actions/goals.
  Method name is required for blacklisting, logging, and error reporting.
  """
  @spec add_task_method(t(), task_name(), String.t(), task_method_fn()) :: t()
  def add_task_method(%__MODULE__{task_methods: methods} = domain, task_name, method_name, method_fn)
      when is_binary(task_name) and is_binary(method_name) and is_function(method_fn, 2) do
    named_method = {method_name, method_fn}
    current_methods = Map.get(methods, task_name, [])
    updated_methods = current_methods ++ [named_method]
    %{domain | task_methods: Map.put(methods, task_name, updated_methods)}
  end

  @doc """
  Adds a task method to the domain with automatic method name inference.
  """
  @spec add_task_method(t(), task_name(), task_method_fn()) :: t()
  def add_task_method(%__MODULE__{} = domain, task_name, method_fn) 
      when is_binary(task_name) and is_function(method_fn, 2) do
    method_name = infer_method_name(method_fn)
    add_task_method(domain, task_name, method_name, method_fn)
  end

  @doc """
  Adds multiple task methods for a task.
  
  Accepts a list of {method_name, method_function} tuples or plain functions.
  For plain functions, method names are automatically inferred.
  """
  @spec add_task_methods(t(), task_name(), [{String.t(), task_method_fn()}] | [task_method_fn()]) :: t()
  def add_task_methods(%__MODULE__{} = domain, task_name, method_tuples_or_functions)
      when is_binary(task_name) and is_list(method_tuples_or_functions) do
    Enum.reduce(method_tuples_or_functions, domain, fn
      {method_name, method_fn}, acc_domain when is_binary(method_name) ->
        add_task_method(acc_domain, task_name, method_name, method_fn)
      method_fn, acc_domain when is_function(method_fn, 2) ->
        add_task_method(acc_domain, task_name, method_fn)
    end)
  end

  @doc """
  Adds a unigoal method to the domain.

  Unigoal methods achieve single predicate-based goals.
  Method name is required for blacklisting, logging, and error reporting.
  """
  @spec add_unigoal_method(t(), String.t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%__MODULE__{unigoal_methods: methods} = domain, goal_type, method_name, method_fn)
      when is_binary(goal_type) and is_binary(method_name) and is_function(method_fn, 2) do
    named_method = {method_name, method_fn}
    current_methods = Map.get(methods, goal_type, [])
    updated_methods = current_methods ++ [named_method]
    %{domain | unigoal_methods: Map.put(methods, goal_type, updated_methods)}
  end

  @doc """
  Adds multiple unigoal methods for a goal type.
  
  Accepts a list of {method_name, method_function} tuples.
  """
  @spec add_unigoal_methods(t(), String.t(), [{String.t(), goal_method_fn()}]) :: t()
  def add_unigoal_methods(%__MODULE__{} = domain, goal_type, method_tuples)
      when is_binary(goal_type) and is_list(method_tuples) do
    Enum.reduce(method_tuples, domain, fn {method_name, method_fn}, acc_domain ->
      add_unigoal_method(acc_domain, goal_type, method_name, method_fn)
    end)
  end

  @doc """
  Adds a multigoal method to the domain.

  Multigoal methods work on achieving multiple goals simultaneously.
  Method name is required for blacklisting, logging, and error reporting.
  """
  @spec add_multigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_multigoal_method(%__MODULE__{multigoal_methods: methods} = domain, method_name, method_fn)
      when is_binary(method_name) and is_function(method_fn, 2) do
    %{domain | multigoal_methods: [{method_name, method_fn} | methods]}
  end

  @doc """
  Adds a multigoal method to the domain with automatic name inference.
  """
  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  def add_multigoal_method(%__MODULE__{} = domain, method_fn) when is_function(method_fn, 2) do
    method_name = infer_method_name(method_fn)
    add_multigoal_method(domain, method_name, method_fn)
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
  
  Returns a list of {method_name, method_function} tuples.
  """
  @spec get_task_methods(t(), task_name()) :: [named_method()]
  def get_task_methods(%__MODULE__{task_methods: methods}, task_name) do
    Map.get(methods, task_name, [])
  end

  @doc """
  Gets unigoal methods for a goal type.
  
  Returns a list of {method_name, method_function} tuples.
  """
  @spec get_unigoal_methods(t(), String.t()) :: [named_method()]
  def get_unigoal_methods(%__MODULE__{unigoal_methods: methods}, goal_type) do
    Map.get(methods, goal_type, [])
  end

  @doc """
  Gets all multigoal methods.
  """
  @spec get_multigoal_methods(t()) :: [named_method()]
  def get_multigoal_methods(%__MODULE__{multigoal_methods: methods}) do
    methods
  end

  @doc """
  Gets goal methods for a predicate. 
  
  This is an alias for get_unigoal_methods to maintain compatibility.
  Returns a list of {method_name, method_function} tuples.
  """
  @spec get_goal_methods(t(), String.t()) :: [named_method()]
  def get_goal_methods(%__MODULE__{} = domain, predicate) do
    get_unigoal_methods(domain, predicate)
  end

  @doc """
  Gets a specific method by name.
  
  This function returns the first method function for the given predicate.
  With the tuple-based implementation, it extracts the function part.
  """
  @spec get_method(t(), String.t()) :: goal_method_fn() | nil
  def get_method(%__MODULE__{unigoal_methods: methods}, method_name) do
    # Treat method_name as a predicate name and return the first method function
    case Map.get(methods, method_name, []) do
      [] -> nil
      [{_name, method_fn} | _] -> method_fn
    end
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

  @doc  """
  Adds Porcelain-based actions to the domain.

  This convenience method adds all the external process actions from AriaEngine.Actions.
  """
  @spec add_porcelain_actions(t()) :: t()
  def add_porcelain_actions(%__MODULE__{} = domain) do
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

  @doc """
  Creates a complete domain with all Porcelain-based actions and methods.

  This is a convenience method for creating a fully-featured domain with basic actions.
  Domain-specific methods should be added by the respective domain modules.
  """
  @spec create_complete_domain(String.t()) :: t()
  def create_complete_domain(name \\ "complete") do
    new(name)
    |> add_porcelain_actions()
  end

  @doc """
  Validates a domain structure.

  ## Parameters
  - `domain`: Domain to validate

  ## Returns
  - `{:ok, domain}`: Valid domain
  - `{:error, reason}`: Invalid domain with reason
  """
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{} = domain) do
    cond do
      domain.name == "" or domain.name == nil ->
        {:error, "Domain name cannot be empty"}
      not is_map(domain.actions) ->
        {:error, "Actions must be a map"}
      not is_map(domain.task_methods) ->
        {:error, "Task methods must be a map"}
      not is_map(domain.unigoal_methods) ->
        {:error, "Unigoal methods must be a map"}
      not is_list(domain.multigoal_methods) ->
        {:error, "Multigoal methods must be a list"}
      true ->
        {:ok, domain}
    end
  end

  def validate(_), do: {:error, "Not a valid domain struct"}

  @doc """
  Adds a unigoal method to the domain with automatic method name inference.

  The method name is automatically derived from the function reference string representation.
  For example, `&ensure_workflow_completed/2` becomes "ensure_workflow_completed".
  """
  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%__MODULE__{} = domain, goal_type, method_fn) 
      when is_binary(goal_type) and is_function(method_fn, 2) do
    method_name = infer_method_name(method_fn)
    add_unigoal_method(domain, goal_type, method_name, method_fn)
  end

  # Private helper to infer method name from function reference
  @doc """
  Infers a method name from a function reference for tuple-based method storage.
  """
  @spec infer_method_name(function()) :: String.t()
  def infer_method_name(fun) when is_function(fun, 2) do
    # Convert function to string and extract name
    fun_string = inspect(fun)
    case Regex.run(~r/&([^\/]+)\/\d+/, fun_string) do
      [_, name] -> 
        # Remove module prefix if present (e.g., "Module.function" -> "function")
        case String.split(name, ".") do
          [single_name] -> single_name
          parts -> List.last(parts)
        end
      _ -> 
        # Fallback for anonymous functions or complex cases
        "method_#{:erlang.phash2(fun)}"
    end
  end
  
  def infer_method_name(fun) when is_function(fun) do
    # Convert function to string and extract name
    fun_string = inspect(fun)
    case Regex.run(~r/&([^\/]+)\/\d+/, fun_string) do
      [_, name] -> 
        # Remove module prefix if present (e.g., "Module.function" -> "function")
        case String.split(name, ".") do
          [single_name] -> single_name
          parts -> List.last(parts)
        end
      _ -> 
        # Fallback for anonymous functions or complex cases
        "method_#{:erlang.phash2(fun)}"
    end
  end
end
