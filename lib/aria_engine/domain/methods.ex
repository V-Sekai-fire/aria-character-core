# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain.Methods do
  @moduledoc """
  Handles method-related operations for the planning domain.
  """


  @type t :: Domain.Core.t()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type task_method_fn :: (AriaEngine.StateV2.t(), list() -> list() | false)
  @type goal_method_fn :: (AriaEngine.StateV2.t(), list() -> list() | false)
  @type named_method :: {method_name(), task_method_fn() | goal_method_fn()}

  @doc """
  Adds a task method to the domain.

  Task methods decompose tasks into subtasks/actions/goals.
  Method name is required for blacklisting, logging, and error reporting.
  """
  @spec add_task_method(t(), task_name(), String.t(), task_method_fn()) :: t()
  def add_task_method(%{task_methods: methods} = domain, task_name, method_name, method_fn)
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
  def add_task_method(%{} = domain, task_name, method_fn) 
      when is_binary(task_name) and is_function(method_fn, 2) do
    method_name = Domain.Utils.infer_method_name(method_fn)
    add_task_method(domain, task_name, method_name, method_fn)
  end

  @doc """
  Adds multiple task methods for a task.
  
  Accepts a list of {method_name, method_function} tuples or plain functions.
  For plain functions, method names are automatically inferred.
  """
  @spec add_task_methods(t(), task_name(), [{String.t(), task_method_fn()}] | [task_method_fn()]) :: t()
  def add_task_methods(%{} = domain, task_name, method_tuples_or_functions)
      when is_binary(task_name) and is_list(method_tuples_or_functions) do
    Enum.reduce(method_tuples_or_functions, domain, fn
      {method_name, method_fn}, acc_domain when is_binary(method_name) ->
        add_task_method(acc_domain, task_name, method_name, method_fn)
      method_fn, acc_domain when is_function(method_fn, 2) ->
        inferred_method_name = Domain.Utils.infer_method_name(method_fn)
        add_task_method(acc_domain, task_name, inferred_method_name, method_fn)
    end)
  end

  @doc """
  Adds a unigoal method to the domain.

  Unigoal methods achieve single predicate-based goals.
  Method name is required for blacklisting, logging, and error reporting.
  """
  @spec add_unigoal_method(t(), String.t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%{unigoal_methods: methods} = domain, goal_type, method_name, method_fn)
      when is_binary(goal_type) and is_binary(method_name) and is_function(method_fn, 2) do
    named_method = {method_name, method_fn}
    current_methods = Map.get(methods, goal_type, [])
    updated_methods = current_methods ++ [named_method]
    %{domain | unigoal_methods: Map.put(methods, goal_type, updated_methods)}
  end

  @doc """
  Adds a unigoal method to the domain with automatic method name inference.

  The method name is automatically derived from the function reference string representation.
  For example, `&ensure_workflow_completed/2` becomes "ensure_workflow_completed".
  """
  @spec add_unigoal_method(t(), String.t(), goal_method_fn()) :: t()
  def add_unigoal_method(%{} = domain, goal_type, method_fn)
      when is_binary(goal_type) and is_function(method_fn, 2) do
    method_name = Domain.Utils.infer_method_name(method_fn)
    add_unigoal_method(domain, goal_type, method_name, method_fn)
  end

  @doc """
  Adds multiple unigoal methods for a goal type.
  
  Accepts a list of {method_name, method_function} tuples.
  """
  @spec add_unigoal_methods(t(), String.t(), [{String.t(), goal_method_fn()}]) :: t()
  def add_unigoal_methods(%{} = domain, goal_type, method_tuples)
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
  def add_multigoal_method(%{multigoal_methods: methods} = domain, method_name, method_fn)
      when is_binary(method_name) and is_function(method_fn, 2) do
    %{domain | multigoal_methods: [{method_name, method_fn} | methods]}
  end

  @doc """
  Adds a multigoal method to the domain with automatic name inference.
  """
  @spec add_multigoal_method(t(), goal_method_fn()) :: t()
  def add_multigoal_method(%{} = domain, method_fn) when is_function(method_fn, 2) do
    method_name = Domain.Utils.infer_method_name(method_fn)
    add_multigoal_method(domain, method_name, method_fn)
  end

  @doc """
  Gets task methods for a task name.
  
  Returns a list of {method_name, method_function} tuples.
  """
  @spec get_task_methods(t(), task_name()) :: [named_method()]
  def get_task_methods(%{task_methods: methods}, task_name) do
    Map.get(methods, task_name, [])
  end

  @doc """
  Gets unigoal methods for a goal type.
  
  Returns a list of {method_name, method_function} tuples.
  """
  @spec get_unigoal_methods(t(), String.t()) :: [named_method()]
  def get_unigoal_methods(%{unigoal_methods: methods}, goal_type) do
    Map.get(methods, goal_type, [])
  end

  @doc """
  Gets all multigoal methods.
  """
  @spec get_multigoal_methods(t()) :: [named_method()]
  def get_multigoal_methods(%{multigoal_methods: methods}) do
    methods
  end

  @doc """
  Gets goal methods for a predicate. 
  
  This is an alias for get_unigoal_methods to maintain compatibility.
  Returns a list of {method_name, method_function} tuples.
  """
  @spec get_goal_methods(t(), String.t()) :: [named_method()]
  def get_goal_methods(%{} = domain, predicate) do
    get_unigoal_methods(domain, predicate)
  end

  @doc """
  Gets a specific method by name.
  
  This function returns the first method function for the given predicate.
  With the tuple-based implementation, it extracts the function part.
  """
  @spec get_method(t(), String.t()) :: goal_method_fn() | nil
  def get_method(%{unigoal_methods: methods}, method_name) do
    # Treat method_name as a predicate name and return the first method function
    case Map.get(methods, method_name, []) do
      [] -> nil
      [{_name, method_fn} | _] -> method_fn
    end
  end

  @doc """
  Checks if task methods exist for a task.
  """
  @spec has_task_methods?(t(), task_name()) :: boolean()
  def has_task_methods?(%{task_methods: methods}, task_name) do
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
  def has_unigoal_methods?(%{unigoal_methods: methods}, goal_type) do
    case Map.get(methods, goal_type) do
      nil -> false
      [] -> false
      _ -> true
    end
  end
end
