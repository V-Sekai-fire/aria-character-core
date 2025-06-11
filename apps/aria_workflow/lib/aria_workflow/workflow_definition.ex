defmodule AriaWorkflow.WorkflowDefinition do
  @moduledoc """
  Represents a workflow definition.

  A workflow definition contains all the information needed to plan and execute
  a workflow, including goals, tasks, methods, documentation, and metadata.
  """

  alias AriaEngine.{Multigoal, State}

  @type t :: %__MODULE__{
    id: String.t(),
    goals: [goal_spec()],
    tasks: [task_spec()],
    methods: [method_spec()],
    documentation: %{atom() => String.t()},
    metadata: %{atom() => term()}
  }

  @type goal_spec :: {String.t(), String.t(), String.t()}
  @type task_spec :: {String.t(), function()}
  @type method_spec :: {String.t(), function()}

  defstruct [
    :id,
    goals: [],
    tasks: [],
    methods: [],
    documentation: %{},
    metadata: %{}
  ]

  @doc """
  Creates a new workflow definition.
  """
  @spec new(String.t(), map()) :: t()
  def new(id, definition) do
    %__MODULE__{
      id: id,
      goals: Map.get(definition, :goals, []),
      tasks: Map.get(definition, :tasks, []),
      methods: Map.get(definition, :methods, []),
      documentation: Map.get(definition, :documentation, %{}),
      metadata: Map.get(definition, :metadata, %{})
    }
  end

  @doc """
  Converts workflow goals to an AriaEngine.Multigoal.
  """
  @spec to_multigoal(t()) :: {:ok, Multigoal.t()} | {:error, term()}
  def to_multigoal(%__MODULE__{goals: goals}) do
    try do
      multigoal = 
        goals
        |> Enum.reduce(Multigoal.new(), fn {pred, subj, obj}, acc ->
          Multigoal.add_goal(acc, pred, subj, obj)
        end)
      
      {:ok, multigoal}
    rescue
      error -> {:error, error}
    end
  end

  @doc """
  Gets a task function by name.
  """
  @spec get_task(t(), String.t()) :: {:ok, function()} | {:error, :not_found}
  def get_task(%__MODULE__{tasks: tasks}, task_name) do
    case Enum.find(tasks, fn {name, _func} -> name == task_name end) do
      nil -> {:error, :not_found}
      {_name, task_fn} -> {:ok, task_fn}
    end
  end

  @doc """
  Gets a method function by name.
  """
  @spec get_method(t(), String.t()) :: {:ok, function()} | {:error, :not_found}
  def get_method(%__MODULE__{methods: methods}, method_name) do
    case Enum.find(methods, fn {name, _func} -> name == method_name end) do
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
  Validates the workflow definition for completeness and correctness.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%__MODULE__{} = workflow) do
    errors = []
    
    errors = if String.trim(workflow.id) == "", do: ["Workflow ID cannot be empty" | errors], else: errors
    errors = if Enum.empty?(workflow.goals), do: ["Workflow must have at least one goal" | errors], else: errors
    errors = validate_goals(workflow.goals, errors)
    errors = validate_tasks(workflow.tasks, errors)
    errors = validate_methods(workflow.methods, errors)
    
    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Adds a goal to the workflow definition.
  """
  @spec add_goal(t(), String.t(), String.t(), String.t()) :: t()
  def add_goal(%__MODULE__{goals: goals} = workflow, predicate, subject, object) do
    new_goal = {predicate, subject, object}
    %{workflow | goals: [new_goal | goals]}
  end

  @doc """
  Adds a task to the workflow definition.
  """
  @spec add_task(t(), String.t(), function()) :: t()
  def add_task(%__MODULE__{tasks: tasks} = workflow, name, task_fn) do
    new_task = {name, task_fn}
    %{workflow | tasks: [new_task | tasks]}
  end

  @doc """
  Adds a method to the workflow definition.
  """
  @spec add_method(t(), String.t(), function()) :: t()
  def add_method(%__MODULE__{methods: methods} = workflow, name, method_fn) do
    new_method = {name, method_fn}
    %{workflow | methods: [new_method | methods]}
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

  defp validate_goals(goals, errors) do
    Enum.reduce(goals, errors, fn goal, acc ->
      case goal do
        {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) ->
          acc
        _ ->
          ["Invalid goal format: #{inspect(goal)}" | acc]
      end
    end)
  end

  defp validate_tasks(tasks, errors) do
    Enum.reduce(tasks, errors, fn {name, task_fn}, acc ->
      cond do
        not is_binary(name) -> ["Task name must be string: #{inspect(name)}" | acc]
        not is_function(task_fn, 2) -> ["Task must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_methods(methods, errors) do
    Enum.reduce(methods, errors, fn {name, method_fn}, acc ->
      cond do
        not is_binary(name) -> ["Method name must be string: #{inspect(name)}" | acc]
        not is_function(method_fn, 2) -> ["Method must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end
end
