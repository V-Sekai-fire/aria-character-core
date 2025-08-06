# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.DomainPlanning do
  @moduledoc """
  Domain planning implementation migrated from AriaEngineCore.Domain.Core.

  This module provides the core domain management functionality that was previously
  in AriaEngineCore, now properly located in AriaCore following umbrella app
  architectural boundaries.

  Supports both legacy GTPyhop-style domains and modern attribute-based domains.
  """

  require Logger

  # Type definitions for compatibility with AriaEngineCore
  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type action_fn :: (AriaState.t(), list() -> AriaState.t() | false)
  @type task_method_fn :: (AriaState.t(), list() -> list() | false)
  @type goal_method_fn :: (AriaState.t(), list() -> list() | false)
  @type named_method :: {method_name(), task_method_fn() | goal_method_fn()}

  # Legacy domain structure for compatibility
  @type legacy_domain :: %{
          name: String.t(),
          actions: %{action_name() => action_fn()},
          action_metadata: %{action_name() => map()},
          task_methods: %{task_name() => [named_method()]},
          unigoal_methods: %{String.t() => [named_method()]},
          multigoal_methods: [named_method()],
          multitodo_methods: [named_method()],
          durative_actions: %{atom() => map()}
        }

  @doc """
  Creates a new legacy-style planning domain for compatibility.

  This maintains compatibility with AriaEngineCore.Domain.Core while
  being implemented in the proper location (AriaCore).
  """
  @spec new_legacy_domain(String.t()) :: legacy_domain()
  def new_legacy_domain(name \\ "default") do
    %{
      name: name,
      actions: %{},
      action_metadata: %{},
      task_methods: %{},
      unigoal_methods: %{},
      multigoal_methods: [],
      multitodo_methods: [],
      durative_actions: %{}
    }
  end

  @doc """
  Validates a legacy domain structure.

  ## Parameters
  - `domain`: Domain to validate

  ## Returns
  - `{:ok, domain}`: Valid domain
  - `{:error, reason}`: Invalid domain with reason
  """
  @spec validate_legacy_domain(legacy_domain()) :: {:ok, legacy_domain()} | {:error, String.t()}
  def validate_legacy_domain(%{} = domain) when is_map(domain) do
    cond do
      domain[:name] == "" or domain[:name] == nil ->
        {:error, "Domain name cannot be empty"}
      not is_map(domain[:actions]) ->
        {:error, "Actions must be a map"}
      not is_map(domain[:action_metadata]) ->
        {:error, "Action metadata must be a map"}
      not is_map(domain[:task_methods]) ->
        {:error, "Task methods must be a map"}
      not is_map(domain[:unigoal_methods]) ->
        {:error, "Unigoal methods must be a map"}
      not is_list(domain[:multigoal_methods]) ->
        {:error, "Multigoal methods must be a list"}
      not is_list(domain[:multitodo_methods]) ->
        {:error, "Multitodo methods must be a list"}
      not is_map(domain[:durative_actions]) ->
        {:error, "Durative actions must be a map"}
      true ->
        {:ok, domain}
    end
  end

  def validate_legacy_domain(_) do
    {:error, "Not a valid domain map"}
  end

  @doc """
  Retrieves a durative action from a legacy domain by name.
  """
  @spec get_durative_action_from_legacy_domain(legacy_domain(), atom()) :: map() | nil
  def get_durative_action_from_legacy_domain(%{durative_actions: durative_actions}, name) do
    Map.get(durative_actions, name)
  end

  @doc """
  Converts a modern AriaCore.Domain to legacy format for compatibility.
  """
  @spec convert_to_legacy_domain(AriaCore.Domain.t()) :: legacy_domain()
  def convert_to_legacy_domain(%AriaCore.Domain{} = domain) do
    %{
      name: Atom.to_string(domain.name),
      actions: domain.actions,
      action_metadata: %{},
      task_methods: domain.methods,
      unigoal_methods: domain.unigoal_methods,
      multigoal_methods: [],
      multitodo_methods: [],
      durative_actions: %{}
    }
  end

  @doc """
  Converts a legacy domain to modern AriaCore.Domain format.
  """
  @spec convert_from_legacy_domain(legacy_domain()) :: AriaCore.Domain.t()
  def convert_from_legacy_domain(%{} = legacy_domain) do
    domain_name =
      case legacy_domain[:name] do
        name when is_binary(name) -> String.to_atom(name)
        name when is_atom(name) -> name
        _ -> :converted_domain
      end

    %AriaCore.Domain{
      name: domain_name,
      actions: legacy_domain[:actions] || %{},
      methods: legacy_domain[:task_methods] || %{},
      unigoal_methods: legacy_domain[:unigoal_methods] || %{},
      entity_registry: AriaCore.Entity.Management.new_registry(),
      temporal_specifications: AriaCore.Temporal.Interval.new_specifications(),
      state_predicates: %{}
    }
  end
end
