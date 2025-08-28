# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Entity.Management do
  @moduledoc """
  Entity and capability management system for AriaCore.

  This module provides the entity registry and capability matching system
  that supports the @action attribute requirements. It implements the
  sociable testing approach by providing a complete entity management
  system that can be leveraged by the attribute processing.

  ## Entity Types

  Entities represent resources that can be allocated to actions:
  - **Agents**: Characters, NPCs, or AI entities with capabilities
  - **Objects**: Tools, equipment, or items with specific properties
  - **Locations**: Spaces or areas with environmental capabilities

  ## Capabilities

  Capabilities define what an entity can do or provide:
  - **Skills**: cooking, crafting, combat, etc.
  - **Properties**: heating, storage, transportation, etc.
  - **States**: operational, available, busy, etc.

  ## Usage

      # Create registry
      registry = AriaCore.Entity.Management.new_registry()

      # Register entity types
      registry = AriaCore.Entity.Management.register_entity_type(registry, %{
        type: "agent",
        capabilities: [:cooking, :cleaning],
        properties: %{skill_level: :intermediate}
      })

      # Match entities for action requirements
      {:ok, matches} = AriaCore.Entity.Management.match_entities(registry, [
        %{type: "agent", capabilities: [:cooking]}
      ])
  """

  defstruct [
    :entity_types,
    :capability_index,
    :allocation_state,
    :constraints
  ]

  @type registry :: %__MODULE__{
    entity_types: map(),
    capability_index: map(),
    allocation_state: map(),
    constraints: map()
  }

  @type entity_requirement :: %{
    type: String.t(),
    capabilities: [atom()],
    properties: map(),
    constraints: map()
  }

  @type entity_match :: %{
    entity_id: String.t(),
    entity_type: String.t(),
    capabilities: [atom()],
    allocation_cost: number()
  }

  @doc """
  Creates a new empty entity registry.

  ## Examples

      iex> registry = AriaCore.Entity.Management.new_registry()
      iex> registry.entity_types
      %{}
  """
  def new_registry() do
    %__MODULE__{
      entity_types: %{},
      capability_index: %{},
      allocation_state: %{},
      constraints: %{}
    }
  end

  @doc """
  Registers a new entity type in the registry.

  ## Parameters

  - `registry`: The entity registry
  - `entity_spec`: Map containing type, capabilities, and properties

  ## Examples

      iex> registry = AriaCore.Entity.Management.new_registry()
      iex> entity_spec = %{
      ...>   type: "chef",
      ...>   capabilities: [:cooking, :food_prep],
      ...>   properties: %{skill_level: :expert, speed: :fast}
      ...> }
      iex> registry = AriaCore.Entity.Management.register_entity_type(registry, entity_spec)
      iex> Map.has_key?(registry.entity_types, "chef")
      true
  """
  def register_entity_type(%__MODULE__{} = registry, entity_spec) do
    entity_type = entity_spec[:type] || entity_spec["type"]
    capabilities = entity_spec[:capabilities] || entity_spec["capabilities"] || []

    # Add to entity types
    updated_types = Map.put(registry.entity_types, entity_type, entity_spec)

    # Update capability index for fast lookup
    updated_index = update_capability_index(registry.capability_index, entity_type, capabilities)

    %{registry |
      entity_types: updated_types,
      capability_index: updated_index
    }
  end

  @doc """
  Matches entities that satisfy the given requirements.

  ## Parameters

  - `registry`: The entity registry
  - `requirements`: List of entity requirement specifications

  ## Returns

  `{:ok, matches}` where matches is a list of entity_match structs,
  or `{:error, reason}` if no suitable entities are found.

  ## Examples

      iex> registry = setup_test_registry()
      iex> requirements = [%{type: "agent", capabilities: [:cooking]}]
      iex> {:ok, matches} = AriaCore.Entity.Management.match_entities(registry, requirements)
      iex> length(matches) > 0
      true
  """
  def match_entities(%__MODULE__{} = registry, requirements) when is_list(requirements) do
    case find_entity_matches(registry, requirements) do
      [] -> {:error, "No entities found matching requirements"}
      matches -> {:ok, matches}
    end
  end

  @doc """
  Normalizes an entity requirement specification.

  Converts various input formats to the standard entity requirement format.
  """
  def normalize_requirement(requirement) when is_map(requirement) do
    %{
      type: requirement[:type] || requirement["type"] || "unknown",
      capabilities: requirement[:capabilities] || requirement["capabilities"] || [],
      properties: requirement[:properties] || requirement["properties"] || %{},
      constraints: requirement[:constraints] || requirement["constraints"] || %{}
    }
  end

  def normalize_requirement(requirement) do
    # Handle other formats or return as-is
    requirement
  end

  @doc """
  Validates that the entity registry is well-formed.

  Checks that all entity types have valid specifications and that
  the capability index is consistent.
  """
  def validate_registry(%__MODULE__{} = registry) do
    with :ok <- validate_entity_types(registry.entity_types),
         :ok <- validate_capability_index(registry.capability_index, registry.entity_types) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Allocates entities for a specific action.

  Marks entities as busy and tracks allocation for resource management.
  """
  def allocate_entities(%__MODULE__{} = registry, entity_matches, action_id) do
    # Update allocation state
    updated_allocation =
      Enum.reduce(entity_matches, registry.allocation_state, fn match, acc ->
        Map.put(acc, match.entity_id, %{
          action_id: action_id,
          allocated_at: DateTime.utc_now(),
          capabilities_used: match.capabilities
        })
      end)

    %{registry | allocation_state: updated_allocation}
  end

  @doc """
  Releases entities from allocation.

  Marks entities as available again after action completion.
  """
  def release_entities(%__MODULE__{} = registry, entity_ids) when is_list(entity_ids) do
    updated_allocation =
      Enum.reduce(entity_ids, registry.allocation_state, fn entity_id, acc ->
        Map.delete(acc, entity_id)
      end)

    %{registry | allocation_state: updated_allocation}
  end

  @doc """
  Gets all entities of a specific type.
  """
  def get_entities_by_type(%__MODULE__{} = registry, entity_type) do
    case Map.get(registry.entity_types, entity_type) do
      nil -> []
      entity_spec -> [entity_spec]
    end
  end

  @doc """
  Gets all entities with a specific capability.
  """
  def get_entities_by_capability(%__MODULE__{} = registry, capability) do
    case Map.get(registry.capability_index, capability) do
      nil -> []
      entity_types ->
        Enum.map(entity_types, fn entity_type ->
          Map.get(registry.entity_types, entity_type)
        end)
        |> Enum.filter(&(&1 != nil))
    end
  end

  # Private implementation functions

  defp update_capability_index(index, entity_type, capabilities) do
    Enum.reduce(capabilities, index, fn capability, acc ->
      entity_types = Map.get(acc, capability, [])
      Map.put(acc, capability, [entity_type | entity_types] |> Enum.uniq())
    end)
  end

  defp find_entity_matches(registry, requirements) do
    Enum.flat_map(requirements, fn requirement ->
      normalized_req = normalize_requirement(requirement)
      find_matches_for_requirement(registry, normalized_req)
    end)
  end

  defp find_matches_for_requirement(registry, requirement) do
    # Find entities by type
    type_matches = get_entities_by_type(registry, requirement.type)

    # Filter by capabilities
    capability_matches = filter_by_capabilities(type_matches, requirement.capabilities)

    # Filter by properties
    property_matches = filter_by_properties(capability_matches, requirement.properties)

    # Filter by constraints
    constraint_matches = filter_by_constraints(property_matches, requirement.constraints)

    # Convert to match format
    Enum.map(constraint_matches, fn entity_spec ->
      %{
        entity_id: generate_entity_id(entity_spec),
        entity_type: entity_spec[:type] || entity_spec["type"],
        capabilities: entity_spec[:capabilities] || entity_spec["capabilities"] || [],
        allocation_cost: calculate_allocation_cost(entity_spec, requirement)
      }
    end)
  end

  defp filter_by_capabilities(entities, required_capabilities) when is_list(required_capabilities) do
    Enum.filter(entities, fn entity ->
      entity_capabilities = entity[:capabilities] || entity["capabilities"] || []
      Enum.all?(required_capabilities, fn req_cap ->
        Enum.member?(entity_capabilities, req_cap)
      end)
    end)
  end

  defp filter_by_capabilities(entities, _), do: entities

  defp filter_by_properties(entities, required_properties) when map_size(required_properties) > 0 do
    Enum.filter(entities, fn entity ->
      entity_properties = entity[:properties] || entity["properties"] || %{}
      Enum.all?(required_properties, fn {key, value} ->
        Map.get(entity_properties, key) == value
      end)
    end)
  end

  defp filter_by_properties(entities, _), do: entities

  defp filter_by_constraints(entities, constraints) when map_size(constraints) > 0 do
    # Apply additional constraints (availability, location, etc.)
    Enum.filter(entities, fn entity ->
      apply_constraints(entity, constraints)
    end)
  end

  defp filter_by_constraints(entities, _), do: entities

  defp apply_constraints(_entity, _constraints) do
    # Placeholder for constraint application logic
    # Could check availability, location proximity, etc.
    true
  end

  defp generate_entity_id(entity_spec) do
    # Generate unique ID for entity instance
    entity_type = entity_spec[:type] || entity_spec["type"] || "unknown"
    timestamp = System.system_time(:millisecond)
    "#{entity_type}_#{timestamp}"
  end

  defp calculate_allocation_cost(entity_spec, requirement) do
    # Calculate cost of allocating this entity for this requirement
    base_cost = 1.0

    # Factor in entity properties
    properties = entity_spec[:properties] || entity_spec["properties"] || %{}
    skill_multiplier = case properties[:skill_level] do
      :expert -> 0.8
      :intermediate -> 1.0
      :novice -> 1.2
      _ -> 1.0
    end

    # Factor in capability overlap
    entity_caps = entity_spec[:capabilities] || entity_spec["capabilities"] || []
    required_caps = requirement.capabilities || []
    overlap_bonus = length(entity_caps -- required_caps) * 0.1

    base_cost * skill_multiplier - overlap_bonus
  end

  defp validate_entity_types(entity_types) do
    Enum.reduce_while(entity_types, :ok, fn {type, spec}, _acc ->
      case validate_entity_spec(type, spec) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, "Entity type #{type}: #{reason}"}}
      end
    end)
  end

  defp validate_entity_spec(_type, spec) when is_map(spec) do
    # Basic validation - could be expanded
    cond do
      not Map.has_key?(spec, :type) and not Map.has_key?(spec, "type") ->
        {:error, "Missing type field"}

      true -> :ok
    end
  end

  defp validate_entity_spec(_type, _spec) do
    {:error, "Entity specification must be a map"}
  end

  defp validate_capability_index(index, entity_types) do
    # Validate that capability index is consistent with entity types
    indexed_types = index |> Map.values() |> List.flatten() |> Enum.uniq()
    registered_types = Map.keys(entity_types)

    case indexed_types -- registered_types do
      [] -> :ok
      orphaned -> {:error, "Capability index references unknown types: #{inspect(orphaned)}"}
    end
  end

  @doc """
  Creates a test registry with sample entities for testing and examples.

  ## Examples

      iex> registry = setup_test_registry()
      iex> Map.has_key?(registry.entity_types, "agent")
      true
  """
  def setup_test_registry() do
    new_registry()
    |> register_entity_type(%{
      type: "agent",
      capabilities: [:cooking, :cleaning, :serving],
      properties: %{skill_level: :intermediate, speed: :normal}
    })
    |> register_entity_type(%{
      type: "equipment",
      capabilities: [:heating, :cooling, :storage],
      properties: %{capacity: 10, efficiency: :high}
    })
    |> register_entity_type(%{
      type: "kitchen",
      capabilities: [:food_prep, :cooking, :storage],
      properties: %{size: :large, equipment_count: 5}
    })
  end
end
