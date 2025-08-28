# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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
  defdelegate get_entity_registry(domain), to: AriaCore.Domain
  defdelegate set_temporal_specifications(domain, specifications), to: AriaCore.Domain
  defdelegate get_temporal_specifications(domain), to: AriaCore.Domain

  # Legacy Domain Planning API (migrated from AriaEngineCore.Domain.Core)
  # NOTE: These functions are implemented directly below as mocks
  # defdelegate new_legacy_domain(), to: AriaCore.DomainPlanning
  # defdelegate new_legacy_domain(name), to: AriaCore.DomainPlanning
  # defdelegate validate_legacy_domain(domain), to: AriaCore.DomainPlanning
  # defdelegate add_action_to_legacy_domain(domain, name, action), to: AriaCore.DomainPlanning
  # defdelegate get_durative_action_from_legacy_domain(domain, name), to: AriaCore.DomainPlanning
  # defdelegate convert_to_legacy_domain(domain), to: AriaCore.DomainPlanning
  # defdelegate convert_from_legacy_domain(legacy_domain), to: AriaCore.DomainPlanning

  # Action Execution API (migrated from AriaEngineCore.Domain.Actions)
  defdelegate add_action_to_domain(domain, name, action_fn, metadata \\ %{}), to: AriaCore.ActionExecution, as: :add_action
  defdelegate add_actions_to_domain(domain, new_actions), to: AriaCore.ActionExecution, as: :add_actions
  defdelegate get_action_from_domain(domain, name), to: AriaCore.ActionExecution, as: :get_action
  defdelegate get_action_metadata_from_domain(domain, name), to: AriaCore.ActionExecution, as: :get_action_metadata
  defdelegate has_action_in_domain?(domain, name), to: AriaCore.ActionExecution, as: :has_action?
  defdelegate execute_action_in_domain(domain, state, action_name, args), to: AriaCore.ActionExecution, as: :execute_action
  defdelegate list_actions_in_domain(domain), to: AriaCore.ActionExecution, as: :list_actions
  defdelegate remove_action_from_domain(domain, name), to: AriaCore.ActionExecution, as: :remove_action
  defdelegate update_action_metadata_in_domain(domain, name, new_metadata), to: AriaCore.ActionExecution, as: :update_action_metadata
  defdelegate get_all_actions_with_metadata_from_domain(domain), to: AriaCore.ActionExecution, as: :get_all_actions_with_metadata
  defdelegate validate_actions_in_domain(domain), to: AriaCore.ActionExecution, as: :validate_actions

  # Method Management API (migrated from AriaEngineCore.Domain.Methods)
  defdelegate add_task_methods_to_domain(domain, task_name, method_tuples_or_functions), to: AriaCore.MethodManagement, as: :add_task_methods
  defdelegate add_task_method_to_domain(domain, task_name, method_name, method_fn), to: AriaCore.MethodManagement, as: :add_task_method
  defdelegate add_task_method_to_domain(domain, task_name, method_fn), to: AriaCore.MethodManagement, as: :add_task_method
  defdelegate add_unigoal_method_to_domain(domain, goal_type, method_name, method_fn), to: AriaCore.MethodManagement, as: :add_unigoal_method
  defdelegate add_unigoal_method_to_domain(domain, goal_type, method_fn), to: AriaCore.MethodManagement, as: :add_unigoal_method
  defdelegate add_unigoal_methods_to_domain(domain, goal_type, method_tuples), to: AriaCore.MethodManagement, as: :add_unigoal_methods
  defdelegate add_multigoal_method_to_domain(domain, method_name, method_fn), to: AriaCore.MethodManagement, as: :add_multigoal_method
  defdelegate add_multigoal_method_to_domain(domain, method_fn), to: AriaCore.MethodManagement, as: :add_multigoal_method
  defdelegate add_multitodo_method_to_domain(domain, method_name, method_fn), to: AriaCore.MethodManagement, as: :add_multitodo_method
  defdelegate add_multitodo_method_to_domain(domain, method_fn), to: AriaCore.MethodManagement, as: :add_multitodo_method
  defdelegate get_task_methods_from_domain(domain, task_name), to: AriaCore.MethodManagement, as: :get_task_methods
  defdelegate get_unigoal_methods_from_domain(domain, goal_type), to: AriaCore.MethodManagement, as: :get_unigoal_methods
  defdelegate get_multigoal_methods_from_domain(domain), to: AriaCore.MethodManagement, as: :get_multigoal_methods
  defdelegate get_multitodo_methods_from_domain(domain), to: AriaCore.MethodManagement, as: :get_multitodo_methods
  defdelegate get_goal_methods_from_domain(domain, predicate), to: AriaCore.MethodManagement, as: :get_goal_methods
  defdelegate get_method_from_domain(domain, method_name), to: AriaCore.MethodManagement, as: :get_method
  defdelegate add_method_to_domain(domain, method_name, method_spec), to: AriaCore.MethodManagement, as: :add_method
  defdelegate has_task_methods_in_domain?(domain, task_name), to: AriaCore.MethodManagement, as: :has_task_methods?
  defdelegate has_unigoal_methods_in_domain?(domain, goal_type), to: AriaCore.MethodManagement, as: :has_unigoal_methods?
  defdelegate get_method_counts_from_domain(domain), to: AriaCore.MethodManagement, as: :get_method_counts

  # Domain Utilities API (migrated from AriaEngineCore.Domain.Utils)
  defdelegate infer_method_name(fun), to: AriaCore.DomainUtils
  defdelegate verify_goal(state, method_name, state_var, args, desired_values, depth, verbose), to: AriaCore.DomainUtils
  defdelegate domain_summary(domain), to: AriaCore.DomainUtils, as: :summary
  defdelegate add_porcelain_actions_to_domain(domain), to: AriaCore.DomainUtils, as: :add_porcelain_actions
  defdelegate create_complete_domain(name \\ "complete"), to: AriaCore.DomainUtils

  # Action Execution API
  defdelegate execute_action(domain, state, action_name, args), to: AriaCore.ActionExecution

  # Legacy Domain Planning Mock Functions
  @doc """
  Creates a new legacy domain structure for backward compatibility.
  """
  def new_legacy_domain() do
    %{
      name: "default_legacy_domain",
      actions: %{},
      methods: %{task: %{}, unigoal: %{}, multigoal: [], multitodo: []},
      entity_registry: %{},
      temporal_specifications: %{},
      type: :legacy
    }
  end

  @doc """
  Creates a new named legacy domain structure.
  """
  def new_legacy_domain(name) do
    %{
      name: name,
      actions: %{},
      methods: %{task: %{}, unigoal: %{}, multigoal: [], multitodo: []},
      entity_registry: %{},
      temporal_specifications: %{},
      type: :legacy
    }
  end

  @doc """
  Validates a legacy domain structure.
  """
  def validate_legacy_domain(domain) when is_map(domain) do
    required_keys = [:name, :actions, :methods, :entity_registry, :temporal_specifications]

    case Enum.all?(required_keys, &Map.has_key?(domain, &1)) do
      true -> {:ok, domain}
      false -> {:error, "Invalid domain structure - missing required keys"}
    end
  end

  def validate_legacy_domain(_domain) do
    {:error, "Domain must be a map"}
  end

  @doc """
  Adds an action to a legacy domain.
  """
  def add_action_to_legacy_domain(domain, action_name, action_spec) do
    updated_actions = Map.put(domain.actions, action_name, action_spec)
    {:ok, %{domain | actions: updated_actions}}
  end

  @doc """
  Gets a durative action from a legacy domain.
  """
  def get_durative_action_from_legacy_domain(domain, action_name) do
    case Map.get(domain.actions, action_name) do
      nil -> {:error, "Action #{action_name} not found"}
      action -> {:ok, action}
    end
  end

  # Additional Mock Functions for Undefined References
  def execute_action_mock(_domain, state, action_name, args) do
    {:ok, {state, %{action: action_name, args: args, result: "mock_execution"}}}
  end

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

  # State Management API - Using canonical AriaState
  defdelegate new_state(), to: AriaState, as: :new
  defdelegate set_fact(state, predicate, subject, value), to: AriaState
  defdelegate get_fact(state, predicate, subject), to: AriaState
  defdelegate remove_fact(state, predicate, subject), to: AriaState
  defdelegate copy_state(state), to: AriaState, as: :copy

  # Additional state operations using AriaState
  defdelegate has_subject?(state, predicate, subject), to: AriaState
  defdelegate get_subjects_with_fact(state, predicate, value), to: AriaState
  defdelegate get_subjects_with_predicate(state, predicate), to: AriaState
  defdelegate to_triples(state), to: AriaState
  defdelegate from_triples(triples), to: AriaState
  defdelegate merge(state1, state2), to: AriaState
  defdelegate matches?(state, predicate, subject, value), to: AriaState
  defdelegate exists?(state, predicate, value, subject_filter \\ nil), to: AriaState
  defdelegate forall?(state, predicate, value, subject_filter), to: AriaState
  defdelegate evaluate_condition(state, condition), to: AriaState

  # Compatibility functions for AriaCore.Relational API
  @doc """
  Checks if a goal is satisfied by the current state.
  Provides compatibility with AriaCore.Relational API.
  """
  def satisfies_goal?(state, goal) do
    case goal do
      {predicate, subject, value} ->
        AriaState.matches?(state, predicate, subject, value)
      _ ->
        false
    end
  end

  @doc """
  Checks if multiple goals are all satisfied.
  Provides compatibility with AriaCore.Relational API.
  """
  def satisfies_goals?(state, goals) when is_list(goals) do
    Enum.all?(goals, &satisfies_goal?(state, &1))
  end

  @doc """
  Applies multiple state changes atomically.
  Provides compatibility with AriaCore.Relational API.
  """
  def apply_changes(state, changes) when is_list(changes) do
    Enum.reduce(changes, state, fn {predicate, subject, value}, acc ->
      AriaState.set_fact(acc, predicate, subject, value)
    end)
  end

  @doc """
  Queries facts using pattern matching.
  Provides compatibility with AriaCore.Relational API.
  """
  def query_state(state, pattern) do
    case pattern do
      {predicate, :_, :_} ->
        # Get all facts with this predicate
        state
        |> AriaState.to_triples()
        |> Enum.filter(fn {pred, _subj, _val} -> pred == predicate end)

      {:_, subject, :_} ->
        # Get all facts about this subject
        state
        |> AriaState.to_triples()
        |> Enum.filter(fn {_pred, subj, _val} -> subj == subject end)

      {predicate, subject, :_} ->
        # Get the value for this predicate/subject pair
        case AriaState.get_fact(state, predicate, subject) do
          nil -> []
          value -> [{predicate, subject, value}]
        end

      {predicate, subject, value} ->
        # Check if this exact triple exists
        case AriaState.matches?(state, predicate, subject, value) do
          true -> [{predicate, subject, value}]
          false -> []
        end

      _ ->
        []
    end
  end

  @doc """
  Gets all facts in the state.
  Provides compatibility with AriaCore.Relational API.
  """
  def all_facts(state) do
    AriaState.to_triples(state)
  end

  @doc """
  Sets a temporal fact with timestamp (compatibility function).
  Note: AriaState doesn't support temporal facts yet,
  so this just sets a regular fact for now.
  """
  def set_temporal_fact(state, predicate, subject, value, _timestamp \\ nil) do
    AriaState.set_fact(state, predicate, subject, value)
  end

  @doc """
  Gets the history of changes for a fact (compatibility function).
  Note: AriaState doesn't support temporal facts yet,
  so this returns empty list for now.
  """
  def get_fact_history(_state, _predicate, _subject) do
    []
  end

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
  Registers all attribute-defined actions and methods with a domain.

  This function retrieves the specs stored by the attribute compiler and
  registers them with the provided domain instance.

  ## Parameters

  - `domain`: Domain instance to register with
  - `module`: Module that has attribute-defined actions/methods

  ## Examples

      iex> domain = AriaCore.new_domain(:test)
      iex> domain = AriaCore.register_attribute_specs(domain, MyDomainModule)
      iex> AriaCore.list_actions(domain)
      [:pickup, :putdown, :stack]
  """
  def register_attribute_specs(domain, module) do
    # Call the module's registration function to populate Process dictionary
    if function_exported?(module, :__register_action_attributes__, 0) do
      module.__register_action_attributes__()
    end

    # Retrieve and register action specs
    domain_with_actions = case Process.get({module, :action_specs}) do
      nil -> domain
      action_specs ->
        Enum.reduce(action_specs, domain, fn {action_name, spec}, acc_domain ->
          # Convert atom action names to strings for consistent lookup
          action_name_str = if is_atom(action_name), do: Atom.to_string(action_name), else: action_name
          add_action_to_domain(acc_domain, action_name_str, spec.action_fn, spec)
        end)
    end

    # Retrieve and register method specs (task methods)
    domain_with_methods = case Process.get({module, :method_specs}) do
      nil -> domain_with_actions
      method_specs ->
        Enum.reduce(method_specs, domain_with_actions, fn {method_name, method_fn}, acc_domain ->
          # Use method name as atom (not string) for consistent lookup
          add_task_method_to_domain(acc_domain, method_name, method_name, method_fn)
        end)
    end

    # Retrieve and register unigoal specs
    domain_with_unigoals = case Process.get({module, :unigoal_specs}) do
      nil -> domain_with_methods
      unigoal_specs ->
        Enum.reduce(unigoal_specs, domain_with_methods, fn {method_name, spec}, acc_domain ->
          # Register the unigoal method with the full spec (not just the function)
          add_unigoal_method(acc_domain, method_name, spec)
        end)
    end

    # Clean up Process dictionary
    Process.delete({module, :action_specs})
    Process.delete({module, :method_specs})
    Process.delete({module, :unigoal_specs})

    domain_with_unigoals
  end

  @doc """
  Macro for using AriaCore in modules.

  This enables the @action, @task_method, and @unigoal_method attributes for domain definition.
  """
  defmacro __using__(_opts) do
    quote do
      use AriaCore.ActionAttributes
    end
  end
end
