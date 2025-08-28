# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.MethodManagement do
  @moduledoc """
  Method management implementation migrated from AriaEngineCore.Domain.Methods.

  This module provides method management functionality for domains,
  now properly located in AriaCore following umbrella app architectural boundaries.
  """

  require Logger

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
    methods = Map.get(domain, :multigoal_methods, [])
    updated_methods = [{method_name, method_fn} | methods]
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
  Add multitodo method to a domain (3-arity version).
  """
  @spec add_multitodo_method(map(), String.t(), function()) :: map()
  def add_multitodo_method(domain, method_name, method_fn) do
    methods = Map.get(domain, :multitodo_methods, [])
    updated_methods = [{method_name, method_fn} | methods]
    Map.put(domain, :multitodo_methods, updated_methods)
  end

  @doc """
  Add multitodo method to a domain (2-arity version).
  """
  @spec add_multitodo_method(map(), function()) :: map()
  def add_multitodo_method(domain, method_fn) do
    method_name = "multitodo_method_#{System.unique_integer([:positive])}"
    add_multitodo_method(domain, method_name, method_fn)
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
  @spec get_multigoal_methods(map()) :: list()
  def get_multigoal_methods(domain) do
    Map.get(domain, :multigoal_methods, [])
  end

  @doc """
  Get all multitodo methods.
  """
  @spec get_multitodo_methods(map()) :: list()
  def get_multitodo_methods(domain) do
    Map.get(domain, :multitodo_methods, [])
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
    # Search through task methods (map of task_name -> list of {name, fn})
    task_methods = Map.get(domain, :task_methods, %{})
    task_result = Enum.find_value(task_methods, fn {_task_name, methods} ->
      Enum.find_value(methods, fn {name, fn_val} ->
        if name == method_name, do: fn_val, else: nil
      end)
    end)

    if task_result do
      task_result
    else
      # Search through unigoal methods (map of goal_type -> map of name -> fn)
      unigoal_methods = Map.get(domain, :unigoal_methods, %{})
      unigoal_result = Enum.find_value(unigoal_methods, fn {_goal_type, methods} ->
        Map.get(methods, method_name)
      end)

      if unigoal_result do
        unigoal_result
      else
        # Search through multigoal methods (list of {name, fn})
        multigoal_methods = Map.get(domain, :multigoal_methods, [])
        multigoal_result = Enum.find_value(multigoal_methods, fn {name, fn_val} ->
          if name == method_name, do: fn_val, else: nil
        end)

        if multigoal_result do
          multigoal_result
        else
          # Search through multitodo methods (list of {name, fn})
          multitodo_methods = Map.get(domain, :multitodo_methods, [])
          Enum.find_value(multitodo_methods, fn {name, fn_val} ->
            if name == method_name, do: fn_val, else: nil
          end)
        end
      end
    end
  end

  @doc """
  Adds a method to the domain based on its type.
  This is a generic entry point for adding methods.
  """
  @spec add_method(map(), String.t(), map()) :: map()
  def add_method(domain, method_name, %{type: :task_method, decomposition_fn: fn_val}) do
    add_task_method(domain, method_name, fn_val)
  end
  def add_method(domain, method_name, %{type: :unigoal_method, predicate: predicate, goal_fn: fn_val}) do
    add_unigoal_method(domain, predicate, method_name, fn_val)
  end
  def add_method(domain, method_name, %{type: :multigoal_method, multigoal_fn: fn_val}) do
    add_multigoal_method(domain, method_name, fn_val)
  end
  def add_method(domain, method_name, %{type: :multitodo_method, multitodo_fn: fn_val}) do
    add_multitodo_method(domain, method_name, fn_val)
  end
  def add_method(domain, method_name, _other) do
    Logger.warning("Unsupported method type for #{method_name}. Method not added.")
    domain
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

  @doc """
  Remove task methods for a specific task.
  """
  @spec remove_task_methods(map(), String.t()) :: map()
  def remove_task_methods(domain, task_name) do
    methods = Map.get(domain, :task_methods, %{})
    updated_methods = Map.delete(methods, task_name)
    Map.put(domain, :task_methods, updated_methods)
  end

  @doc """
  Remove unigoal methods for a specific goal type.
  """
  @spec remove_unigoal_methods(map(), String.t()) :: map()
  def remove_unigoal_methods(domain, goal_type) do
    methods = Map.get(domain, :unigoal_methods, %{})
    updated_methods = Map.delete(methods, goal_type)
    Map.put(domain, :unigoal_methods, updated_methods)
  end

  @doc """
  Clear all multigoal methods.
  """
  @spec clear_multigoal_methods(map()) :: map()
  def clear_multigoal_methods(domain) do
    Map.put(domain, :multigoal_methods, [])
  end

  @doc """
  Clear all multitodo methods.
  """
  @spec clear_multitodo_methods(map()) :: map()
  def clear_multitodo_methods(domain) do
    Map.put(domain, :multitodo_methods, [])
  end

  @doc """
  Get method counts by type.
  """
  @spec get_method_counts(map()) :: map()
  def get_method_counts(domain) do
    %{
      task_methods: domain |> Map.get(:task_methods, %{}) |> map_size(),
      unigoal_methods: domain |> Map.get(:unigoal_methods, %{}) |> map_size(),
      multigoal_methods: domain |> Map.get(:multigoal_methods, []) |> length(),
      multitodo_methods: domain |> Map.get(:multitodo_methods, []) |> length()
    }
  end
end
