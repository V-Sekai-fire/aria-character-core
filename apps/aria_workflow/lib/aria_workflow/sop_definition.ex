# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.SOPDefinition do
  @moduledoc """
  Represents a Standard Operating Procedure (SOP) definition.

  An SOP definition contains all the information needed to plan and execute
  a standard operating procedure, including goals, tasks, methods, documentation,
  and metadata.
  """

  alias AriaWorkflow.Multigoal

  @type t :: %__MODULE__{
    id: String.t(),
    goals: [goal_spec()],
    tasks: %{String.t() => function()},
    methods: %{String.t() => function()},
    documentation: %{atom() => String.t()},
    metadata: %{atom() => term()}
  }

  @type goal_spec :: {String.t(), String.t(), String.t()}

  defstruct [
    :id,
    goals: [],
    tasks: [],
    methods: [],
    documentation: %{},
    metadata: %{}
  ]

  @doc """
  Creates a new SOP definition.
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
  Converts SOP goals to an AriaWorkflow.Multigoal.
  """
  @spec to_multigoal(t()) :: {:ok, AriaWorkflow.Multigoal.t()} | {:error, term()}
  def to_multigoal(%__MODULE__{goals: goals}) do
    try do
      multigoal = 
        goals
        |> Enum.reduce(AriaWorkflow.Multigoal.new(), fn {pred, subj, obj}, acc ->
          AriaWorkflow.Multigoal.add_goal(acc, pred, subj, obj)
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
    case Map.get(tasks, task_name) do
      nil -> {:error, :not_found}
      task_fn -> {:ok, task_fn}
    end
  end

  @doc """
  Gets a method function by name.
  """
  @spec get_method(t(), String.t()) :: {:ok, function()} | {:error, :not_found}
  def get_method(%__MODULE__{methods: methods}, method_name) do
    case Map.get(methods, method_name) do
      nil -> {:error, :not_found}
      method_fn -> {:ok, method_fn}
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
  Validates the SOP definition for completeness and correctness.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%__MODULE__{} = sop) do
    errors = []
    
    errors = if String.trim(sop.id) == "", do: ["SOP ID cannot be empty" | errors], else: errors
    errors = if Enum.empty?(sop.goals), do: ["SOP must have at least one goal" | errors], else: errors
    errors = validate_goals(sop.goals, errors)
    errors = validate_tasks(sop.tasks, errors)
    errors = validate_methods(sop.methods, errors)
    
    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Adds a goal to the SOP definition.
  """
  @spec add_goal(t(), String.t(), String.t(), String.t()) :: t()
  def add_goal(%__MODULE__{goals: goals} = sop, predicate, subject, object) do
    new_goal = {predicate, subject, object}
    %{sop | goals: [new_goal | goals]}
  end

  @doc """
  Adds a task to the SOP definition.
  """
  @spec add_task(t(), String.t(), function()) :: t()
  def add_task(%__MODULE__{tasks: tasks} = sop, name, task_fn) do
    %{sop | tasks: Map.put(tasks, name, task_fn)}
  end

  @doc """
  Adds a method to the SOP definition.
  """
  @spec add_method(t(), String.t(), function()) :: t()
  def add_method(%__MODULE__{methods: methods} = sop, name, method_fn) do
    %{sop | methods: Map.put(methods, name, method_fn)}
  end

  @doc """
  Adds documentation to the SOP definition.
  """
  @spec add_documentation(t(), atom(), String.t()) :: t()
  def add_documentation(%__MODULE__{documentation: docs} = sop, key, content) do
    %{sop | documentation: Map.put(docs, key, content)}
  end

  @doc """
  Updates metadata for the SOP definition.
  """
  @spec put_metadata(t(), atom(), term()) :: t()
  def put_metadata(%__MODULE__{metadata: meta} = sop, key, value) do
    %{sop | metadata: Map.put(meta, key, value)}
  end

  # Private helpers

  defp tasks_to_map(tasks) when is_list(tasks) do
    Enum.into(tasks, %{})
  end
  defp tasks_to_map(tasks) when is_map(tasks), do: tasks

  defp methods_to_map(methods) when is_list(methods) do
    Enum.into(methods, %{})
  end
  defp methods_to_map(methods) when is_map(methods), do: methods

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
