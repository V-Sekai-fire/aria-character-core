# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.WorkflowDefinition do
  @moduledoc """
  [DEPRECATED] Use AriaEngine.DomainDefinition instead.

  This module is being replaced by AriaEngine.DomainDefinition which provides
  a unified approach to domain capabilities, todo planning, and execution state
  with built-in span-based tracing.

  Key advantages of AriaEngine.DomainDefinition:
  - Unified structure combining capabilities and execution state
  - Built-in span tracing where todo execution IS the trace
  - No redundant infrastructure between planning and execution
  - Cleaner architecture with less conceptual overhead

  Migration path:
  ```elixir
  # Old WorkflowDefinition
  workflow = AriaWorkflow.WorkflowDefinition.new(id, definition)

  # New DomainDefinition
  domain_def = AriaEngine.DomainDefinition.new(id, definition)
  ```

  Represents a workflow definition.
  Use AriaEngine.DomainDefinition for new code.
  """

  alias AriaEngine.Multigoal

  @type t :: %__MODULE__{
    id: String.t(),
    todos: [todo_item()],
    actions: [action_spec()],
    task_methods: [task_method_spec()],
    unigoal_methods: [unigoal_method_spec()],
    multigoal_methods: [multigoal_method_spec()],
    documentation: %{atom() => String.t()},
    metadata: %{atom() => term()}
  }

  # AriaEngine todo items can be goals, tasks, or actions in any order
  @type todo_item :: goal_spec() | task_spec() | action_spec()
  @type goal_spec :: {String.t(), String.t(), String.t()}
  @type task_spec :: {String.t(), list()}
  @type action_spec :: {atom(), list()}
  @type task_method_spec :: {String.t(), function()}
  @type unigoal_method_spec :: {String.t(), function()}
  @type multigoal_method_spec :: function()

  defstruct [
    :id,
    todos: [],
    actions: [],
    task_methods: [],
    unigoal_methods: [],
    multigoal_methods: [],
    documentation: %{},
    metadata: %{}
  ]

  @doc """
  Creates a new workflow definition.
  """
  @spec new(String.t(), map()) :: t()
  def new(id, definition) do
    # Support legacy :goals field for backward compatibility
    todos = case {Map.get(definition, :todos), Map.get(definition, :goals)} do
      {nil, nil} -> []
      {nil, goals} when is_list(goals) -> goals  # Legacy support
      {[], nil} -> []
      {[], goals} when is_list(goals) -> goals  # Legacy support
      {todos, _} when is_list(todos) -> todos   # New format
      {_, _} -> []
    end

    %__MODULE__{
      id: id,
      todos: todos,
      actions: Map.get(definition, :actions, []),
      task_methods: Map.get(definition, :task_methods, []),
      unigoal_methods: Map.get(definition, :unigoal_methods, []),
      multigoal_methods: Map.get(definition, :multigoal_methods, []),
      documentation: Map.get(definition, :documentation, %{}),
      metadata: Map.get(definition, :metadata, %{})
    }
  end

  @doc """
  Converts workflow todos to AriaEngine planning format.
  """
  @spec to_planning_todos(t()) :: {:ok, [todo_item()]} | {:error, term()}
  def to_planning_todos(%__MODULE__{todos: todos}) do
    try do
      # AriaEngine accepts mixed todos - goals, tasks, and actions
      {:ok, todos}
    rescue
      error -> {:error, error}
    end
  end

  @doc """
  Converts workflow definition to a multigoal for planning.
  """
  @spec to_multigoal(t()) :: {:ok, Multigoal.t()} | {:error, term()}
  def to_multigoal(%__MODULE__{todos: todos}) do
    try do
      # Extract goal specs from todos (filter out tasks and actions)
      goals = Enum.filter(todos, fn
        {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) -> true
        _ -> false
      end)

      # Check specifically for malformed goal tuples (not tasks or actions)
      malformed_goals = Enum.filter(todos, fn
        {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) -> false  # Valid goal
        {task_name, args} when is_binary(task_name) and is_list(args) -> false  # Valid task
        {action_name, args} when is_atom(action_name) and is_list(args) -> false  # Valid action
        {_, _} -> true  # 2-tuple that's not a valid task or action - this is malformed
        tuple when is_tuple(tuple) and tuple_size(tuple) > 3 -> true  # More than 3 elements - malformed
        _ -> false  # Other formats are acceptable (might be extensions)
      end)

      if length(malformed_goals) > 0 do
        {:error, "Malformed goal tuples found: #{inspect(malformed_goals)}"}
      else
        multigoal = Multigoal.new(goals)
        {:ok, multigoal}
      end
    rescue
      error -> {:error, error}
    end
  end

  @doc """
  Gets a task function by name.
  """
  @spec get_task(t(), String.t()) :: {:ok, function()} | {:error, :not_found}
  def get_task(%__MODULE__{task_methods: task_methods}, task_name) do
    case Enum.find(task_methods, fn {name, _func} -> name == task_name end) do
      nil -> {:error, :not_found}
      {_name, task_fn} -> {:ok, task_fn}
    end
  end

  @doc """
  Gets a method function by name.
  """
  @spec get_method(t(), String.t()) :: {:ok, function()} | {:error, :not_found}
  def get_method(%__MODULE__{unigoal_methods: unigoal_methods}, method_name) do
    case Enum.find(unigoal_methods, fn {name, _func} -> name == method_name end) do
      nil -> {:error, :not_found}
      {_name, method_fn} -> {:ok, method_fn}
    end
  end

  @doc """
  Gets documentation by key.
  """
  @spec get_documentation(t(), atom()) :: {:ok, String.t()} | {:error, :not_found}
  def get_documentation(%__MODULE__{documentation: docs}, key) do
    case Map.get(docs, key) do
      nil -> {:error, :not_found}
      doc -> {:ok, doc}
    end
  end

  @doc """
  Gets goals for backward compatibility (maps to todos that are goal specs).
  """
  @spec goals(t()) :: [goal_spec()]
  def goals(%__MODULE__{todos: todos}) do
    Enum.filter(todos, fn
      {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) -> true
      _ -> false
    end)
  end

  @doc """
  Validates the workflow definition for completeness and correctness.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%__MODULE__{} = workflow) do
    errors = []

    errors = if String.trim(workflow.id) == "", do: ["Workflow ID cannot be empty" | errors], else: errors
    errors = if Enum.empty?(workflow.todos), do: ["Workflow must have at least one todo item" | errors], else: errors
    errors = validate_todos(workflow.todos, errors)
    errors = validate_task_methods(workflow.task_methods, errors)
    errors = validate_unigoal_methods(workflow.unigoal_methods, errors)

    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Adds a goal to the workflow definition.
  """
  @spec add_goal(t(), String.t(), String.t(), String.t()) :: t()
  def add_goal(%__MODULE__{todos: todos} = workflow, predicate, subject, object) do
    new_goal = {predicate, subject, object}
    %{workflow | todos: [new_goal | todos]}
  end

  @doc """
  Adds a task to the workflow definition.
  """
  @spec add_task(t(), String.t(), function()) :: t()
  def add_task(%__MODULE__{task_methods: task_methods} = workflow, name, task_fn) do
    new_task = {name, task_fn}
    %{workflow | task_methods: [new_task | task_methods]}
  end

  @doc """
  Adds a method to the workflow definition.
  """
  @spec add_method(t(), String.t(), function()) :: t()
  def add_method(%__MODULE__{unigoal_methods: unigoal_methods} = workflow, name, method_fn) do
    new_method = {name, method_fn}
    %{workflow | unigoal_methods: [new_method | unigoal_methods]}
  end

  @doc """
  Adds documentation to the workflow definition.
  """
  @spec add_documentation(t(), atom(), String.t()) :: t()
  def add_documentation(%__MODULE__{documentation: docs} = workflow, key, content) do
    %{workflow | documentation: Map.put(docs, key, content)}
  end

  @doc """
  Updates metadata for the workflow definition.
  """
  @spec put_metadata(t(), atom(), term()) :: t()
  def put_metadata(%__MODULE__{metadata: meta} = workflow, key, value) do
    %{workflow | metadata: Map.put(meta, key, value)}
  end

  # Private helpers

  defp validate_todos(todos, errors) do
    Enum.reduce(todos, errors, fn todo, acc ->
      case todo do
        {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) ->
          acc  # Valid goal
        {task_name, args} when is_binary(task_name) and is_list(args) ->
          acc  # Valid task
        {action_name, args} when is_atom(action_name) and is_list(args) ->
          acc  # Valid action
        _ ->
          ["Invalid todo format: #{inspect(todo)}" | acc]
      end
    end)
  end

  defp validate_task_methods(task_methods, errors) do
    Enum.reduce(task_methods, errors, fn {name, task_fn}, acc ->
      cond do
        not is_binary(name) -> ["Task method name must be string: #{inspect(name)}" | acc]
        not is_function(task_fn, 2) -> ["Task method must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_unigoal_methods(unigoal_methods, errors) do
    Enum.reduce(unigoal_methods, errors, fn {name, method_fn}, acc ->
      cond do
        not is_binary(name) -> ["Unigoal method name must be string: #{inspect(name)}" | acc]
        not is_function(method_fn, 2) -> ["Unigoal method must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end
end
