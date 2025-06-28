defmodule AriaEngineCore.Domain.Methods do
  @moduledoc """
  Mock implementation of AriaEngineCore.Domain.Methods for compilation.

  This module provides method management functionality for domains.
  Currently mocked with basic functionality to enable compilation.
  """

  @doc """
  Add task methods to a domain.
  """
  @spec add_task_methods(map(), String.t(), list()) :: map()
  def add_task_methods(domain, task_name, method_tuples_or_functions) do
    methods = Map.get(domain, :task_methods, %{})
    updated_methods = Map.put(methods, task_name, method_tuples_or_functions)
    Map.put(domain, :task_methods, updated_methods)
  end

  @doc """
  Add a single task method to a domain (4-arity version).
  """
  @spec add_task_method(map(), String.t(), String.t(), function()) :: map()
  def add_task_method(domain, task_name, method_name, method_fn) do
    methods = Map.get(domain, :task_methods, %{})
    task_methods = Map.get(methods, task_name, [])
    updated_task_methods = [{method_name, method_fn} | task_methods]
    updated_methods = Map.put(methods, task_name, updated_task_methods)
    Map.put(domain, :task_methods, updated_methods)
  end

  @doc """
  Add a single task method to a domain (3-arity version).
  """
  @spec add_task_method(map(), String.t(), function()) :: map()
  def add_task_method(domain, task_name, method_fn) do
    method_name = "method_#{System.unique_integer([:positive])}"
    add_task_method(domain, task_name, method_name, method_fn)
  end

  @doc """
  Add unigoal method to a domain (4-arity version).
  """
  @spec add_unigoal_method(map(), String.t(), String.t(), function()) :: map()
  def add_unigoal_method(domain, goal_type, method_name, method_fn) do
    methods = Map.get(domain, :unigoal_methods, %{})
    goal_methods = Map.get(methods, goal_type, %{})
    updated_goal_methods = Map.put(goal_methods, method_name, method_fn)
    updated_methods = Map.put(methods, goal_type, updated_goal_methods)
    Map.put(domain, :unigoal_methods, updated_methods)
  end

  @doc """
  Add unigoal method to a domain (3-arity version).
  """
  @spec add_unigoal_method(map(), String.t(), function()) :: map()
  def add_unigoal_method(domain, goal_type, method_fn) do
    # Infer method name from function
    method_name = "method_#{System.unique_integer([:positive])}"
    add_unigoal_method(domain, goal_type, method_name, method_fn)
  end

  @doc """
  Add multiple unigoal methods to a domain.
  """
  @spec add_unigoal_methods(map(), String.t(), list()) :: map()
  def add_unigoal_methods(domain, goal_type, method_tuples) do
    Enum.reduce(method_tuples, domain, fn {method_name, method_fn}, acc_domain ->
      add_unigoal_method(acc_domain, goal_type, method_name, method_fn)
    end)
  end

  @doc """
  Add multigoal method to a domain (3-arity version).
  """
  @spec add_multigoal_method(map(), String.t(), function()) :: map()
  def add_multigoal_method(domain, method_name, method_fn) do
    methods = Map.get(domain, :multigoal_methods, %{})
    updated_methods = Map.put(methods, method_name, method_fn)
    Map.put(domain, :multigoal_methods, updated_methods)
  end

  @doc """
  Add multigoal method to a domain (2-arity version).
  """
  @spec add_multigoal_method(map(), function()) :: map()
  def add_multigoal_method(domain, method_fn) do
    method_name = "multigoal_method_#{System.unique_integer([:positive])}"
    add_multigoal_method(domain, method_name, method_fn)
  end

  @doc """
  Get task methods for a specific task.
  """
  @spec get_task_methods(map(), String.t()) :: list()
  def get_task_methods(domain, task_name) do
    domain
    |> Map.get(:task_methods, %{})
    |> Map.get(task_name, [])
  end

  @doc """
  Get unigoal methods for a specific goal type.
  """
  @spec get_unigoal_methods(map(), String.t()) :: map()
  def get_unigoal_methods(domain, goal_type) do
    domain
    |> Map.get(:unigoal_methods, %{})
    |> Map.get(goal_type, %{})
  end

  @doc """
  Get all multigoal methods.
  """
  @spec get_multigoal_methods(map()) :: map()
  def get_multigoal_methods(domain) do
    Map.get(domain, :multigoal_methods, %{})
  end

  @doc """
  Get goal methods for a specific predicate.
  """
  @spec get_goal_methods(map(), String.t()) :: map()
  def get_goal_methods(domain, predicate) do
    get_unigoal_methods(domain, predicate)
  end

  @doc """
  Get a specific method by name.
  """
  @spec get_method(map(), String.t()) :: function() | nil
  def get_method(domain, method_name) do
    # Search through all method types
    all_methods = %{}
    |> Map.merge(Map.get(domain, :task_methods, %{}))
    |> Map.merge(Map.get(domain, :multigoal_methods, %{}))

    # Also search unigoal methods
    unigoal_methods = Map.get(domain, :unigoal_methods, %{})
    unigoal_flat = Enum.reduce(unigoal_methods, %{}, fn {_goal_type, methods}, acc ->
      Map.merge(acc, methods)
    end)

    all_methods
    |> Map.merge(unigoal_flat)
    |> Map.get(method_name)
  end

  @doc """
  Check if domain has task methods for a specific task.
  """
  @spec has_task_methods?(map(), String.t()) :: boolean()
  def has_task_methods?(domain, task_name) do
    domain
    |> Map.get(:task_methods, %{})
    |> Map.has_key?(task_name)
  end

  @doc """
  Check if domain has unigoal methods for a specific goal type.
  """
  @spec has_unigoal_methods?(map(), String.t()) :: boolean()
  def has_unigoal_methods?(domain, goal_type) do
    domain
    |> Map.get(:unigoal_methods, %{})
    |> Map.has_key?(goal_type)
  end
end
