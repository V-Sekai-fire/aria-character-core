# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Domain do
  @moduledoc """
  Core domain management system for AriaCore.

  Provides the foundational domain structure that supports both legacy
  function-based action definitions and the new @action attribute system.

  This module implements the sociable testing approach by leveraging
  existing systems while providing a clean interface for domain creation.
  """

  defstruct [
    :name,
    :actions,
    :methods,
    :unigoal_methods,
    :entity_registry,
    :temporal_specifications,
    :state_predicates
  ]

  @type t :: %__MODULE__{
    name: atom(),
    actions: map(),
    methods: map(),
    unigoal_methods: map(),
    entity_registry: AriaCore.Entity.Management.registry(),
    temporal_specifications: AriaCore.Temporal.Interval.specifications(),
    state_predicates: map()
  }

  @doc """
  Creates a new empty domain.

  ## Examples

      iex> domain = AriaCore.Domain.new()
      iex> domain.actions
      %{}
  """
  def new(name \\ :default_domain) do
    %__MODULE__{
      name: name,
      actions: %{},
      methods: %{},
      unigoal_methods: %{},
      entity_registry: AriaCore.Entity.Management.new_registry(),
      temporal_specifications: AriaCore.Temporal.Interval.new_specifications(),
      state_predicates: %{}
    }
  end

  @doc """
  Adds an action to the domain.

  Supports both legacy action specifications and new attribute-based actions.

  ## Examples

      iex> domain = AriaCore.Domain.new()
      iex> action_spec = %{
      ...>   duration: AriaCore.Temporal.Interval.fixed(7200),
      ...>   entity_requirements: [],
      ...>   action_fn: &cook_meal/2
      ...> }
      iex> domain = AriaCore.Domain.add_action(domain, :cook_meal, action_spec)
      iex> Map.has_key?(domain.actions, :cook_meal)
      true
  """
  def add_action(%__MODULE__{} = domain, action_name, action_spec) when is_atom(action_name) do
    %{domain | actions: Map.put(domain.actions, action_name, action_spec)}
  end

  @doc """
  Adds a task method to the domain.

  Task methods provide decomposition strategies for complex goals.
  """
  def add_method(%__MODULE__{} = domain, method_name, method_spec) when is_atom(method_name) do
    %{domain | methods: Map.put(domain.methods, method_name, method_spec)}
  end

  @doc """
  Adds a unigoal method to the domain.

  Unigoal methods provide single goal achievement strategies according to ADR-181.
  They handle prerequisite checking, action selection, and verification for one specific goal predicate.
  """
  def add_unigoal_method(%__MODULE__{} = domain, method_name, unigoal_spec) when is_atom(method_name) do
    %{domain | unigoal_methods: Map.put(domain.unigoal_methods, method_name, unigoal_spec)}
  end

  @doc """
  Sets the entity registry for the domain.

  The entity registry manages entity types, capabilities, and allocation.
  """
  def set_entity_registry(%__MODULE__{} = domain, registry) do
    %{domain | entity_registry: registry}
  end

  @doc """
  Gets the entity registry for the domain.

  The entity registry manages entity types, capabilities, and allocation.
  """
  def get_entity_registry(%__MODULE__{} = domain) do
    domain.entity_registry
  end

  @doc """
  Sets the temporal specifications for the domain.

  Temporal specifications define duration patterns and temporal constraints.
  """
  def set_temporal_specifications(%__MODULE__{} = domain, specifications) do
    %{domain | temporal_specifications: specifications}
  end

  @doc """
  Gets the temporal specifications for the domain.

  Temporal specifications define duration patterns and temporal constraints.
  """
  def get_temporal_specifications(%__MODULE__{} = domain) do
    domain.temporal_specifications
  end

  @doc """
  Lists all actions in the domain.
  """
  def list_actions(%__MODULE__{} = domain) do
    Map.keys(domain.actions)
  end

  @doc """
  Gets an action specification by name.
  """
  def get_action(%__MODULE__{} = domain, action_name) do
    Map.get(domain.actions, action_name)
  end

  @doc """
  Gets a method specification by name.
  """
  def get_method(%__MODULE__{} = domain, method_name) do
    Map.get(domain.methods, method_name)
  end

  @doc """
  Lists all method names in the domain.
  """
  def list_methods(%__MODULE__{} = domain) do
    Map.keys(domain.methods)
  end

  @doc """
  Gets a unigoal method specification by name.
  """
  def get_unigoal_method(%__MODULE__{} = domain, method_name) do
    Map.get(domain.unigoal_methods, method_name)
  end

  @doc """
  Lists all unigoal method names in the domain.
  """
  def list_unigoal_methods(%__MODULE__{} = domain) do
    Map.keys(domain.unigoal_methods)
  end

  @doc """
  Gets unigoal methods for a specific predicate.
  """
  def get_unigoal_methods_for_predicate(%__MODULE__{} = domain, predicate) do
    domain.unigoal_methods
    |> Enum.filter(fn {_name, spec} -> spec.predicate == predicate end)
    |> Enum.into(%{})
  end

  @doc """
  Validates that the domain is well-formed.

  Checks that all actions have valid specifications and that
  entity requirements can be satisfied.
  """
  def validate(%__MODULE__{} = domain) do
    with :ok <- validate_actions(domain),
         :ok <- validate_methods(domain),
         :ok <- validate_entity_requirements(domain) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private validation functions

  defp validate_actions(%__MODULE__{actions: actions}) do
    Enum.reduce_while(actions, :ok, fn {name, spec}, _acc ->
      case validate_action_spec(name, spec) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, "Action #{name}: #{reason}"}}
      end
    end)
  end

  defp validate_action_spec(_name, %{duration: duration, action_fn: action_fn})
       when is_function(action_fn, 2) do
    case AriaCore.Temporal.Interval.validate(duration) do
      :ok -> :ok
      {:error, reason} -> {:error, "Invalid duration: #{reason}"}
    end
  end

  defp validate_action_spec(_name, spec) do
    {:error, "Invalid action specification: #{inspect(spec)}"}
  end

  defp validate_methods(%__MODULE__{methods: methods}) do
    Enum.reduce_while(methods, :ok, fn {name, spec}, _acc ->
      case validate_method_spec(name, spec) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, "Method #{name}: #{reason}"}}
      end
    end)
  end

  defp validate_method_spec(_name, %{decomposition_fn: decomposition_fn})
       when is_function(decomposition_fn, 2) do
    :ok
  end

  defp validate_method_spec(_name, spec) do
    {:error, "Invalid method specification: #{inspect(spec)}"}
  end

  defp validate_entity_requirements(%__MODULE__{} = domain) do
    AriaCore.Entity.Management.validate_registry(domain.entity_registry)
  end

  @doc """
  Macro for using AriaCore.Domain in modules.

  This enables the @action, @task_method, and @unigoal_method attributes for domain definition.
  """
  defmacro __using__(_opts) do
    quote do
      use AriaCore.ActionAttributes
      import AriaCore.Domain
    end
  end
end
