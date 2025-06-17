defmodule AriaEngine.DomainAPI do
  @moduledoc """
  Provides functions for building and managing the domain capabilities of the Aria Engine.
  """
  alias AriaEngine.Core
  alias AriaEngine.Domain
  alias AriaEngine.State

  @type t :: Core.t()
  @type action_fn :: Core.action_fn()
  @type task_method_fn :: Core.task_method_fn()
  @type goal_method_fn :: Core.goal_method_fn()
  @type todo_item :: Core.todo_item()

  @doc """
  Creates an AriaEngine definition from an existing Domain.
  """
  @spec from_domain(Domain.t(), [todo_item()], State.t() | nil) :: t()
  def from_domain(%Domain{} = domain, goals, initial_state \\ nil) do
    initial_state = initial_state || State.new()

    # Preserve the method formats exactly as they are in the domain
    # This ensures that method tuples remain as tuples in the engine
    Core.new(domain.name, %{
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
  def to_domain(%Core{} = engine) do
    # Create domain with the same name
    domain = Domain.new(engine.name)
    
    # Add actions directly (they don't need conversion)
    domain_with_actions = %{domain | actions: engine.actions}
    
    # Add task methods - preserve original format exactly
    domain_with_task_methods = 
      Enum.reduce(engine.task_methods, domain_with_actions, fn {task_name, methods}, acc ->
        # Preserve the methods exactly as they are in the engine
        %{acc | task_methods: Map.put(acc.task_methods, task_name, methods)}
      end)
    
    # Add unigoal methods - preserve original format exactly
    domain_with_unigoal_methods = 
      Enum.reduce(engine.unigoal_methods, domain_with_task_methods, fn {goal_type, methods}, acc ->
        # Preserve the methods exactly as they are in the engine
        %{acc | unigoal_methods: Map.put(acc.unigoal_methods, goal_type, methods)}
      end)
    
    # Add multigoal methods - preserve original format exactly
    %{domain_with_unigoal_methods | multigoal_methods: engine.multigoal_methods}
  end

  @doc """
  Adds an action to the AriaEngine definition.
  """
  @spec add_action(t(), atom(), action_fn()) :: t()
  def add_action(%Core{actions: actions} = engine, name, action_fn)
      when is_atom(name) and is_function(action_fn, 2) do
    %{engine | actions: Map.put(actions, name, action_fn)}
  end

  @doc """
  Adds multiple actions to the definition.
  """
  @spec add_actions(t(), %{atom() => action_fn()}) :: t()
  def add_actions(%Core{actions: current_actions} = engine, new_actions) do
    %{engine | actions: Map.merge(current_actions, new_actions)}
  end

  @doc """
  Adds a task method to the definition.
  """
  @spec add_task_method(t(), String.t(), task_method_fn()) :: t()
  def add_task_method(%Core{task_methods: methods} = engine, task_name, method_fn)
      when is_binary(task_name) and is_function(method_fn, 2) do
    current_methods = Map.get(methods, task_name, [])
    updated_methods = current_methods ++ [method_fn]
    %{engine | task_methods: Map.put(methods, task_name, updated_methods)}
  end

  @doc """
  Adds multiple task methods for a task.
  """
  @spec add_task_methods(t(), String.t(), [task_method_fn()]) :: t()
  def add_task_methods(%Core{} = engine, task_name, method_fns)
      when is_binary(task_name) and is_list(method_fns) do
    Enum.reduce(method_fns, engine, fn method_fn, acc_engine ->
      add_task_method(acc_engine, task_name, method_fn)
    end)
  end

  @doc """
  Adds a unigoal method to the definition.
  """
  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%Core{unigoal_methods: methods} = engine, goal_type, method_fn)
      when is_binary(goal_type) and is_function(method_fn, 2) do
    current_methods = Map.get(methods, goal_type, [])
    updated_methods = current_methods ++ [method_fn]
    %{engine | unigoal_methods: Map.put(methods, goal_type, updated_methods)}
  end

  @doc """
  Adds multiple unigoal methods for a goal type.
  """
  @spec add_unigoal_methods(t(), String.t(), [goal_method_fn()]) :: t()
  def add_unigoal_methods(%Core{} = engine, goal_type, method_fns)
      when is_binary(goal_type) and is_list(method_fns) do
    Enum.reduce(method_fns, engine, fn method_fn, acc_engine ->
      add_unigoal_method(acc_engine, goal_type, method_fn)
    end)
  end

  @doc """
  Adds a multigoal method to the definition.
  """
  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  def add_multigoal_method(%Core{multigoal_methods: methods} = engine, method_fn)
      when is_function(method_fn, 2) do
    %{engine | multigoal_methods: [method_fn | methods]}
  end

  @doc """
  Adds multiple multigoal methods.
  """
  @spec add_multigoal_methods(t(), [goal_method_fn()]) :: t()
  def add_multigoal_methods(%Core{} = engine, method_fns) when is_list(method_fns) do
    Enum.reduce(method_fns, engine, fn method_fn, acc_engine ->
      add_multigoal_method(acc_engine, method_fn)
    end)
  end

  ## Domain Composition and Registry Integration

  @doc """
  Creates an AriaEngine definition by composing multiple domains from the registry.
  """
  @spec from_domain_types(String.t(), [String.t()], [Core.todo_item()], State.t() | nil) ::
    {:ok, t()} | {:error, String.t()}
  def from_domain_types(id, domain_types, goals, initial_state \\ nil) do
    # For now, we'll get the first domain type and ignore composition
    # TODO: Implement proper domain composition with the new provider system
    case domain_types do
      [] -> {:error, "No domain types provided"}
      [domain_type | _] ->
        case AriaEngine.DomainProvider.get_domain(domain_type) do
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
  def add_domain_type(%Core{} = engine, domain_type) do
    case AriaEngine.DomainProvider.get_domain(domain_type) do
      {:ok, domain} ->
        updated_engine = %{engine |
          actions: Map.merge(engine.actions, domain.actions),
          task_methods: AriaEngine.merge_method_maps(engine.task_methods, domain.task_methods),
          unigoal_methods: AriaEngine.merge_method_maps(engine.unigoal_methods, domain.unigoal_methods),
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
    AriaEngine.DomainProvider.list_domain_types()
  end

  @doc """
  Validates a domain type exists in the registry.
  """
  @spec validate_domain_type(String.t()) :: :ok | {:error, String.t()}
  def validate_domain_type(domain_type) do
    case AriaEngine.DomainProvider.get_domain(domain_type) do
      {:ok, _domain} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
