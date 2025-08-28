# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.UnifiedDomain do
  @moduledoc """
  Unified domain creation system for AriaCore.

  This module implements Phase 3 of the ADR-181 implementation plan:
  enabling module-based domain pattern with automatic registration.

  Uses the sociable testing approach by bridging new module-based domains
  with existing Domain system rather than reimplementing domain logic.

  ## Purpose

  Provides a clean interface for creating domains from modules that use
  @action and @task_method attributes, while leveraging all existing
  AriaCore systems for entity management, temporal processing, and state.

  ## Usage

      defmodule CookingDomain do
        use AriaCore.Domain

        @action duration: "PT2H",
                requires_entities: [%{type: "agent", capabilities: [:cooking]}]
        def cook_meal(state, [meal_id]) do
          AriaCore.set_fact(state, "meal_status", meal_id, "ready")
        end
      end

      # Create domain from module
      domain = AriaCore.UnifiedDomain.create_from_module(CookingDomain)

      # Domain is fully compatible with existing systems
      {:ok, plan} = AriaCore.plan(domain, initial_state, goals)
  """

  @doc """
  Creates a domain from a module that uses @action and @task_method attributes.

  This function implements the sociable testing approach by leveraging
  existing AriaCore systems rather than reimplementing domain logic.

  ## Parameters

  - `domain_module`: Module that uses AriaCore.Domain and defines actions/methods

  ## Returns

  A fully configured AriaCore.Domain struct that's compatible with all
  existing planning and execution systems.

  ## Examples

      iex> defmodule TestDomain do
      ...>   use AriaCore.Domain
      ...>   @action duration: "PT1H", requires_entities: []
      ...>   def simple_action(state, []), do: state
      ...> end
      iex> domain = AriaCore.UnifiedDomain.create_from_module(TestDomain)
      iex> AriaCore.Domain.list_actions(domain)
      [:simple_action]
  """
  def create_from_module(domain_module) do
    # Always use manual processing to ensure we get an AriaCore.Domain struct
    # The module's create_domain() function returns AriaEngineCore.Domain.Core
    # but we need AriaCore.Domain for compatibility with the rest of the system
    create_domain_manually(domain_module)
  end

  @doc """
  Creates multiple domains from a list of modules.

  Useful for batch processing or creating domain hierarchies.

  ## Examples

      iex> modules = [CookingDomain, CleaningDomain, MaintenanceDomain]
      iex> domains = AriaCore.UnifiedDomain.create_from_modules(modules)
      iex> length(domains)
      3
  """
  def create_from_modules(domain_modules) when is_list(domain_modules) do
    Enum.map(domain_modules, &create_from_module/1)
  end

  @doc """
  Merges multiple domains into a single unified domain.

  Combines actions, methods, entities, and temporal specifications
  from multiple domains while preserving all functionality.

  ## Parameters

  - `domains`: List of AriaCore.Domain structs to merge
  - `options`: Optional merge configuration

  ## Examples

      iex> defmodule CookingDomain do
      ...>   use AriaCore.Domain
      ...>   @action duration: "PT1H", requires_entities: []
      ...>   def cook_meal(state, []), do: state
      ...> end
      iex> defmodule CleaningDomain do
      ...>   use AriaCore.Domain
      ...>   @action duration: "PT30M", requires_entities: []
      ...>   def clean_kitchen(state, []), do: state
      ...> end
      iex> cooking_domain = AriaCore.UnifiedDomain.create_from_module(CookingDomain)
      iex> cleaning_domain = AriaCore.UnifiedDomain.create_from_module(CleaningDomain)
      iex> unified = AriaCore.UnifiedDomain.merge_domains([cooking_domain, cleaning_domain])
      iex> length(AriaCore.Domain.list_actions(unified)) > 1
      true
  """
  def merge_domains(domains, options \\ []) when is_list(domains) do
    case domains do
      [] -> AriaCore.Domain.new()
      [single_domain] -> single_domain
      [first | rest] -> Enum.reduce(rest, first, &merge_two_domains(&2, &1, options))
    end
  end

  @doc """
  Validates that a module is properly configured for domain creation.

  Checks that the module uses AriaCore.Domain and has valid action/method definitions.

  ## Examples

      iex> defmodule ValidDomain do
      ...>   use AriaCore.Domain
      ...>   @action duration: "PT1H", requires_entities: []
      ...>   def test_action(state, []), do: state
      ...> end
      iex> AriaCore.UnifiedDomain.validate_domain_module(ValidDomain)
      :ok

      iex> defmodule InvalidModule do
      ...>   # Missing use AriaCore.Domain
      ...>   def some_function(), do: :ok
      ...> end
      iex> AriaCore.UnifiedDomain.validate_domain_module(InvalidModule)
      {:error, "Module does not use AriaCore.Domain"}
  """
  def validate_domain_module(domain_module) do
    with :ok <- check_module_uses_domain(domain_module),
         :ok <- check_action_metadata_format(domain_module),
         :ok <- check_method_metadata_format(domain_module) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets comprehensive information about a domain module.

  Returns detailed information about actions, methods, entities, and temporal specs.

  ## Examples

      iex> info = AriaCore.UnifiedDomain.get_domain_info(CookingDomain)
      iex> Map.has_key?(info, :actions)
      true
  """
  def get_domain_info(domain_module) do
    %{
      module: domain_module,
      actions: get_action_metadata(domain_module),
      methods: get_method_metadata(domain_module),
      entity_requirements: extract_entity_requirements(domain_module),
      temporal_specifications: extract_temporal_specifications(domain_module),
      validation_status: validate_domain_module(domain_module)
    }
  end

  @doc """
  Creates a domain registry for managing multiple domains.

  Useful for applications that need to work with multiple domain types.
  """
  def create_domain_registry(domain_modules) when is_list(domain_modules) do
    domains = create_from_modules(domain_modules)

    registry = Enum.zip(domain_modules, domains) |> Enum.into(%{})

    %{
      domains: registry,
      created_at: DateTime.utc_now(),
      total_actions: count_total_actions(domains),
      total_methods: count_total_methods(domains)
    }
  end

  # Private implementation functions

  defp create_domain_manually(domain_module) do
    # LEVERAGE existing Domain.new() (no rewrite needed)
    base_domain = AriaCore.Domain.new(domain_module)

    # Extract @action attributes using Phase 1 work
    actions = get_action_metadata(domain_module)

    # Extract @command attributes using Phase 1 work
    commands = get_command_metadata(domain_module)

    # Extract @task_method attributes using Phase 1 work
    methods = get_method_metadata(domain_module)

    # Extract @unigoal_method attributes using Phase 1 work
    unigoals = get_unigoal_metadata(domain_module)

    # Extract @multigoal_method attributes using Phase 1 work
    multigoals = get_multigoal_metadata(domain_module)

    # Extract @multitodo_method attributes using Phase 1 work
    multitodos = get_multitodo_metadata(domain_module)

    # Process actions using existing systems (SOCIABLE approach)
    domain_with_actions = process_module_actions(base_domain, actions, domain_module)

    # Process commands using existing systems (SOCIABLE approach)
    domain_with_commands = process_module_commands(domain_with_actions, commands, domain_module)

    # Process methods using existing systems (SOCIABLE approach)
    domain_with_methods = process_module_methods(domain_with_commands, methods, domain_module)

    # Process unigoal methods using existing systems (SOCIABLE approach)
    domain_with_unigoals = process_module_unigoals(domain_with_methods, unigoals, domain_module)

    # Process multigoal methods using existing systems (SOCIABLE approach)
    domain_with_multigoals = process_module_multigoals(domain_with_unigoals, multigoals, domain_module)

    # Process multitodo methods using existing systems (SOCIABLE approach)
    domain_with_multitodos = process_module_multitodos(domain_with_multigoals, multitodos, domain_module)

    # Set up entity registry (LEVERAGE existing entity system)
    entity_registry = create_entity_registry_from_actions(actions)
    domain_with_entities = AriaCore.Domain.set_entity_registry(domain_with_multitodos, entity_registry)

    # Set up temporal specifications (LEVERAGE existing temporal system)
    temporal_specs = create_temporal_specifications_from_actions(actions)
    AriaCore.Domain.set_temporal_specifications(domain_with_entities, temporal_specs)
  end

  defp get_action_metadata(domain_module) do
    if function_exported?(domain_module, :__action_metadata__, 0) do
      domain_module.__action_metadata__()
    else
      []
    end
  end

  defp get_command_metadata(domain_module) do
    if function_exported?(domain_module, :__command_metadata__, 0) do
      domain_module.__command_metadata__()
    else
      []
    end
  end

  defp get_method_metadata(domain_module) do
    if function_exported?(domain_module, :__method_metadata__, 0) do
      domain_module.__method_metadata__()
    else
      []
    end
  end

  defp get_unigoal_metadata(domain_module) do
    if function_exported?(domain_module, :__unigoal_metadata__, 0) do
      domain_module.__unigoal_metadata__()
    else
      []
    end
  end

  defp get_multigoal_metadata(domain_module) do
    if function_exported?(domain_module, :__multigoal_metadata__, 0) do
      domain_module.__multigoal_metadata__()
    else
      []
    end
  end

  defp get_multitodo_metadata(domain_module) do
    if function_exported?(domain_module, :__multitodo_metadata__, 0) do
      domain_module.__multitodo_metadata__()
    else
      []
    end
  end

  defp process_module_actions(domain, actions, domain_module) do
    Enum.reduce(actions, domain, fn {action_name, metadata}, acc ->
      # Extract the function name if it's a tuple
      clean_action_name = case action_name do
        {name, _arity} -> name
        name when is_atom(name) -> name
      end

      # LEVERAGE existing action conversion (Phase 1 work)
      action_spec = AriaCore.ActionAttributes.convert_action_metadata(metadata, action_name, domain_module)
      AriaCore.Domain.add_action(acc, clean_action_name, action_spec)
    end)
  end

  defp process_module_commands(domain, commands, domain_module) do
    Enum.reduce(commands, domain, fn {command_name, metadata}, acc ->
      # Extract the function name if it's a tuple
      clean_command_name = case command_name do
        {name, _arity} -> name
        name when is_atom(name) -> name
      end

      # LEVERAGE existing command conversion (Phase 1 work)
      command_spec = AriaCore.ActionAttributes.convert_command_metadata(metadata, command_name, domain_module)
      AriaCore.Domain.add_action(acc, clean_command_name, command_spec)
    end)
  end

  defp process_module_methods(domain, methods, domain_module) do
    Enum.reduce(methods, domain, fn {method_name, metadata}, acc ->
      # Extract the function name if it's a tuple
      clean_method_name = case method_name do
        {name, _arity} -> name
        name when is_atom(name) -> name
      end

      # LEVERAGE existing method conversion (Phase 1 work)
      method_spec = AriaCore.ActionAttributes.convert_method_metadata(metadata, method_name, domain_module)
      AriaCore.Domain.add_method(acc, clean_method_name, method_spec)
    end)
  end

  defp process_module_unigoals(domain, unigoals, domain_module) do
    Enum.reduce(unigoals, domain, fn {unigoal_name, metadata}, acc ->
      # Extract the function name if it's a tuple
      clean_unigoal_name = case unigoal_name do
        {name, _arity} -> name
        name when is_atom(name) -> name
      end

      # LEVERAGE existing unigoal conversion (Phase 1 work)
      unigoal_spec = AriaCore.ActionAttributes.convert_unigoal_metadata(metadata, unigoal_name, domain_module)
      AriaCore.Domain.add_unigoal_method(acc, clean_unigoal_name, unigoal_spec)
    end)
  end

  defp process_module_multigoals(domain, multigoals, domain_module) do
    Enum.reduce(multigoals, domain, fn {multigoal_name, _metadata}, acc ->
      # Extract the function name if it's a tuple
      clean_multigoal_name = case multigoal_name do
        {name, _arity} -> name
        name when is_atom(name) -> name
      end

      # LEVERAGE existing multigoal conversion (Phase 1 work)
      multigoal_fn = AriaCore.ActionAttributes.convert_multigoal_metadata(multigoal_name, multigoal_name, domain_module)
      # Add as regular method with multigoal_fn field
      method_spec = %{multigoal_fn: multigoal_fn}
      AriaCore.Domain.add_method(acc, clean_multigoal_name, method_spec)
    end)
  end

  defp process_module_multitodos(domain, multitodos, domain_module) do
    Enum.reduce(multitodos, domain, fn {multitodo_name, _metadata}, acc ->
      # Extract the function name if it's a tuple
      clean_multitodo_name = case multitodo_name do
        {name, _arity} -> name
        name when is_atom(name) -> name
      end

      # LEVERAGE existing multitodo conversion (Phase 1 work)
      multitodo_fn = AriaCore.ActionAttributes.convert_multitodo_metadata(multitodo_name, multitodo_name, domain_module)
      # Add as regular method with multitodo_fn field
      method_spec = %{multitodo_fn: multitodo_fn}
      AriaCore.Domain.add_method(acc, clean_multitodo_name, method_spec)
    end)
  end

  defp create_entity_registry_from_actions(actions) do
    # LEVERAGE existing entity registry creation (Phase 1 work)
    AriaCore.ActionAttributes.create_entity_registry(actions)
  end

  defp create_temporal_specifications_from_actions(actions) do
    # LEVERAGE existing temporal specifications creation (Phase 1 work)
    AriaCore.ActionAttributes.create_temporal_specifications(actions)
  end

  defp merge_two_domains(domain1, domain2, _options) do
    # Merge actions
    merged_actions = Map.merge(domain1.actions, domain2.actions)

    # Merge methods
    merged_methods = Map.merge(domain1.methods, domain2.methods)

    # Merge entity registries
    merged_entities = merge_entity_registries(domain1.entity_registry, domain2.entity_registry)

    # Merge temporal specifications
    merged_temporal = merge_temporal_specifications(domain1.temporal_specifications, domain2.temporal_specifications)

    %{domain1 |
      actions: merged_actions,
      methods: merged_methods,
      entity_registry: merged_entities,
      temporal_specifications: merged_temporal
    }
  end

  defp merge_entity_registries(registry1, registry2) do
    # LEVERAGE existing entity registry merging
    # For now, simple merge - could be more sophisticated
    %{registry1 |
      entity_types: Map.merge(registry1.entity_types, registry2.entity_types),
      capability_index: Map.merge(registry1.capability_index, registry2.capability_index)
    }
  end

  defp merge_temporal_specifications(specs1, specs2) do
    # LEVERAGE existing temporal specifications merging
    %{specs1 |
      action_durations: Map.merge(specs1.action_durations, specs2.action_durations),
      temporal_constraints: Map.merge(specs1.temporal_constraints, specs2.temporal_constraints)
    }
  end

  defp check_module_uses_domain(domain_module) do
    # Check if module has the required functions from using AriaCore.Domain
    # Must have at least one of the action attribute functions
    cond do
      function_exported?(domain_module, :__action_metadata__, 0) -> :ok
      function_exported?(domain_module, :__method_metadata__, 0) -> :ok
      function_exported?(domain_module, :__unigoal_metadata__, 0) -> :ok
      function_exported?(domain_module, :create_domain, 0) -> :ok
      true -> {:error, "Module does not use AriaCore.Domain"}
    end
  end

  defp check_action_metadata_format(domain_module) do
    actions = get_action_metadata(domain_module)

    invalid_actions = Enum.filter(actions, fn
      {name, metadata} when is_atom(name) and is_list(metadata) -> false
      _ -> true
    end)

    case invalid_actions do
      [] -> :ok
      invalid -> {:error, "Invalid action metadata format: #{inspect(invalid)}"}
    end
  end

  defp check_method_metadata_format(domain_module) do
    methods = get_method_metadata(domain_module)

    invalid_methods = Enum.filter(methods, fn
      {name, metadata} when is_atom(name) and (is_list(metadata) or is_map(metadata)) -> false
      _ -> true
    end)

    case invalid_methods do
      [] -> :ok
      invalid -> {:error, "Invalid method metadata format: #{inspect(invalid)}"}
    end
  end

  defp extract_entity_requirements(domain_module) do
    actions = get_action_metadata(domain_module)

    actions
    |> Enum.flat_map(fn {_name, metadata} ->
      metadata[:requires_entities] || []
    end)
    |> Enum.uniq()
  end

  defp extract_temporal_specifications(domain_module) do
    actions = get_action_metadata(domain_module)

    actions
    |> Enum.map(fn {name, metadata} ->
      {name, metadata[:duration]}
    end)
    |> Enum.filter(fn {_name, duration} -> duration != nil end)
    |> Enum.into(%{})
  end

  defp count_total_actions(domains) do
    domains
    |> Enum.map(&length(AriaCore.Domain.list_actions(&1)))
    |> Enum.sum()
  end

  defp count_total_methods(domains) do
    domains
    |> Enum.map(&length(AriaCore.Domain.list_methods(&1)))
    |> Enum.sum()
  end
end
