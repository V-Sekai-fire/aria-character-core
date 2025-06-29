# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCore do
  @moduledoc """
  External API for AriaCore - Core domain management and temporal processing.

  This module provides the public interface for AriaCore functionality, including:
  - Domain creation and management
  - Action and method registration
  - Entity and capability management
  - Temporal interval processing
  - State management operations

  All cross-app communication should use this external API rather than importing
  internal AriaCore modules directly.

  ## Domain Management

      # Create a new domain
      domain = AriaCore.new_domain(:cooking_domain)

      # Add actions to domain
      action_spec = %{
        duration: AriaCore.fixed_duration(3600),
        entity_requirements: [%{type: "chef", capabilities: [:cooking]}],
        action_fn: &cook_meal/2
      }
      domain = AriaCore.add_action(domain, :cook_meal, action_spec)

  ## Entity Management

      # Create entity registry
      registry = AriaCore.new_entity_registry()

      # Register entity types
      registry = AriaCore.register_entity_type(registry, %{
        type: "chef",
        capabilities: [:cooking, :food_prep],
        properties: %{skill_level: :expert}
      })

  ## Temporal Processing

      # Parse ISO 8601 durations
      duration = AriaCore.parse_duration("PT2H30M")

      # Create duration specifications
      fixed_dur = AriaCore.fixed_duration(3600)
      variable_dur = AriaCore.variable_duration(1800, 7200)

  ## State Management

      # Create new state
      state = AriaCore.new_state()

      # Set and get facts
      state = AriaCore.set_fact(state, "status", "chef_1", "available")
      {:ok, status} = AriaCore.get_fact(state, "status", "chef_1")
  """

  # Domain Management API
  defdelegate new_domain(), to: AriaCore.Domain, as: :new
  defdelegate new_domain(name), to: AriaCore.Domain, as: :new
  defdelegate add_action(domain, action_name, action_spec), to: AriaCore.Domain
  defdelegate add_method(domain, method_name, method_spec), to: AriaCore.Domain
  defdelegate add_unigoal_method(domain, method_name, unigoal_spec), to: AriaCore.Domain
  defdelegate list_actions(domain), to: AriaCore.Domain
  defdelegate list_methods(domain), to: AriaCore.Domain
  defdelegate list_unigoal_methods(domain), to: AriaCore.Domain
  defdelegate get_method(domain, method_name), to: AriaCore.Domain
  defdelegate get_unigoal_method(domain, method_name), to: AriaCore.Domain
  defdelegate get_unigoal_methods_for_predicate(domain, predicate), to: AriaCore.Domain
  defdelegate validate_domain(domain), to: AriaCore.Domain, as: :validate
  defdelegate set_entity_registry(domain, registry), to: AriaCore.Domain
  defdelegate set_temporal_specifications(domain, specifications), to: AriaCore.Domain

  # Planning and Execution API
  defdelegate plan(domain, state, goals), to: AriaEngineCore, as: :plan
  defdelegate run_lazy(domain, state, goals), to: AriaEngineCore, as: :run_lazy
  defdelegate run_lazy_tree(domain, state, solution_tree), to: AriaEngineCore, as: :run_lazy_tree

  # Entity Management API
  defdelegate new_entity_registry(), to: AriaCore.Entity.Management, as: :new_registry
  defdelegate register_entity_type(registry, entity_spec), to: AriaCore.Entity.Management
  defdelegate match_entities(registry, requirements), to: AriaCore.Entity.Management
  defdelegate normalize_requirement(requirement), to: AriaCore.Entity.Management
  defdelegate validate_entity_registry(registry), to: AriaCore.Entity.Management, as: :validate_registry
  defdelegate allocate_entities(registry, entity_matches, action_id), to: AriaCore.Entity.Management
  defdelegate release_entities(registry, entity_ids), to: AriaCore.Entity.Management
  defdelegate get_entities_by_type(registry, entity_type), to: AriaCore.Entity.Management
  defdelegate get_entities_by_capability(registry, capability), to: AriaCore.Entity.Management

  # Temporal Processing API
  defdelegate new_temporal_specifications(), to: AriaCore.Temporal.Interval, as: :new_specifications
  defdelegate parse_duration(duration_string), to: AriaCore.Temporal.Interval, as: :parse_iso8601
  defdelegate fixed_duration(seconds), to: AriaCore.Temporal.Interval, as: :fixed
  defdelegate variable_duration(min_seconds, max_seconds), to: AriaCore.Temporal.Interval, as: :variable
  defdelegate conditional_duration(condition_map), to: AriaCore.Temporal.Interval, as: :conditional
  defdelegate add_action_duration(specs, action_name, duration), to: AriaCore.Temporal.Interval
  defdelegate add_temporal_constraint(specs, action_name, constraint), to: AriaCore.Temporal.Interval, as: :add_constraint
  defdelegate validate_duration(duration), to: AriaCore.Temporal.Interval, as: :validate
  defdelegate calculate_duration(duration, state \\ %{}, resources \\ %{}), to: AriaCore.Temporal.Interval
  defdelegate get_action_duration(specs, action_name), to: AriaCore.Temporal.Interval
  defdelegate get_action_constraints(specs, action_name), to: AriaCore.Temporal.Interval
  defdelegate create_execution_pattern(pattern_type, actions), to: AriaCore.Temporal.Interval

  # Temporal Converter API
  defdelegate convert_durative_action(durative_action), to: AriaCore.TemporalConverter
  defdelegate extract_simple_action(durative_action), to: AriaCore.TemporalConverter
  defdelegate build_method_decomposition(durative_action), to: AriaCore.TemporalConverter
  defdelegate validate_conversion(original, converted), to: AriaCore.TemporalConverter
  defdelegate is_legacy_durative_action?(action_spec), to: AriaCore.TemporalConverter
  defdelegate convert_batch(legacy_actions), to: AriaCore.TemporalConverter

  # State Management API
  defdelegate new_state(), to: AriaCore.State.Relational, as: :new
  defdelegate set_fact(state, predicate, subject, value), to: AriaCore.State.Relational
  defdelegate get_fact(state, predicate, subject), to: AriaCore.State.Relational
  defdelegate remove_fact(state, predicate, subject), to: AriaCore.State.Relational
  defdelegate satisfies_goal?(state, goal), to: AriaCore.State.Relational
  defdelegate satisfies_goals?(state, goals), to: AriaCore.State.Relational
  defdelegate apply_changes(state, changes), to: AriaCore.State.Relational
  defdelegate query_state(state, pattern), to: AriaCore.State.Relational, as: :query
  defdelegate all_facts(state), to: AriaCore.State.Relational
  defdelegate set_temporal_fact(state, predicate, subject, value), to: AriaCore.State.Relational
  defdelegate get_fact_history(state, predicate, subject), to: AriaCore.State.Relational
  defdelegate copy_state(state), to: AriaCore.State.Relational, as: :copy

  # Unified Domain API
  defdelegate create_domain_from_module(domain_module), to: AriaCore.UnifiedDomain, as: :create_from_module
  defdelegate create_domains_from_modules(modules), to: AriaCore.UnifiedDomain, as: :create_from_modules
  defdelegate merge_domains(domains, options \\ []), to: AriaCore.UnifiedDomain
  defdelegate validate_domain_module(domain_module), to: AriaCore.UnifiedDomain
  defdelegate get_domain_info(domain_module), to: AriaCore.UnifiedDomain

  @doc """
  Creates a complete domain setup with entity registry and temporal specifications.

  This is a convenience function that combines domain creation with entity and
  temporal setup in one call.

  ## Parameters

  - `name`: Domain name (atom)
  - `options`: Configuration options
    - `:entities`: List of entity specifications to register
    - `:temporal_specs`: Temporal specifications to apply

  ## Examples

      iex> entities = [%{type: "chef", capabilities: [:cooking]}]
      iex> domain = AriaCore.setup_domain(:cooking, entities: entities)
      iex> AriaCore.list_actions(domain)
      []
  """
  def setup_domain(name, options \\ []) do
    domain = new_domain(name)

    # Set up entity registry if provided
    domain_with_entities = case Keyword.get(options, :entities) do
      nil -> domain
      entities ->
        registry = Enum.reduce(entities, new_entity_registry(), fn entity_spec, acc ->
          register_entity_type(acc, entity_spec)
        end)
        set_entity_registry(domain, registry)
    end

    # Set up temporal specifications if provided
    case Keyword.get(options, :temporal_specs) do
      nil -> domain_with_entities
      specs -> set_temporal_specifications(domain_with_entities, specs)
    end
  end

  @doc """
  Processes action metadata and creates a complete action specification.

  This function handles the conversion from attribute metadata to full action specs,
  including duration parsing and entity requirement normalization.

  ## Parameters

  - `metadata`: Action metadata from @action attributes
  - `action_name`: Name of the action
  - `module`: Module defining the action

  ## Examples

      iex> metadata = %{duration: "PT1H", requires_entities: [%{type: "chef"}]}
      iex> spec = AriaCore.process_action_metadata(metadata, :cook_meal, MyModule)
      iex> spec.duration
      {:fixed, 3600}
  """
  def process_action_metadata(metadata, action_name, module) do
    AriaCore.ActionAttributes.convert_action_metadata(metadata, action_name, module)
  end

  @doc """
  Creates an entity registry from action metadata.

  Extracts entity requirements from all actions and builds a complete registry.

  ## Parameters

  - `action_metadata`: Map of action names to metadata

  ## Examples

      iex> metadata = %{cook_meal: %{requires_entities: [%{type: "chef"}]}}
      iex> registry = AriaCore.create_entity_registry_from_actions(metadata)
      iex> AriaCore.get_entities_by_type(registry, "chef")
      [%{type: "chef"}]
  """
  def create_entity_registry_from_actions(action_metadata) do
    AriaCore.ActionAttributes.create_entity_registry(action_metadata)
  end

  @doc """
  Creates temporal specifications from action metadata.

  Extracts duration specifications from all actions and builds temporal specs.

  ## Parameters

  - `action_metadata`: Map of action names to metadata

  ## Examples

      iex> metadata = %{cook_meal: %{duration: "PT1H"}}
      iex> specs = AriaCore.create_temporal_specs_from_actions(metadata)
      iex> AriaCore.get_action_duration(specs, :cook_meal)
      {:fixed, 3600}
  """
  def create_temporal_specs_from_actions(action_metadata) do
    AriaCore.ActionAttributes.create_temporal_specifications(action_metadata)
  end

  @doc """
  Macro for using AriaCore in modules.

  This enables the @action, @task_method, and @unigoal_method attributes for domain definition.
  """
  defmacro __using__(_opts) do
    quote do
      use AriaCore.Domain
    end
  end
end
