# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity.EntityManagement do
  @moduledoc "Entity creation and management operations for Timeline.AgentEntity.\n\nHandles the creation, validation, and basic operations for entities in the\ntimeline system.\n"
  @type entity :: Timeline.AgentEntity.entity()
  @type participant :: Timeline.AgentEntity.participant()
  @doc "Creates a new entity.\n\n## Parameters\n\n- `id`: Unique identifier for the entity\n- `name`: Human-readable name\n- `properties`: Entity-specific properties (e.g., location, state)\n- `opts`: Optional parameters including:\n  - `:owner_agent_id` - ID of the agent that owns this entity\n  - `:metadata` - Additional metadata\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.EntityManagement.create_entity(\n    ...>   \"conference_room\",\n    ...>   \"Conference Room A\",\n    ...>   %{capacity: 10, location: \"Building 1, Floor 2\"},\n    ...>   owner_agent_id: \"facility_manager\",\n    ...>   metadata: %{building_id: \"bldg_1\"}\n    ...> )\n    iex> entity.type\n    :entity\n    iex> entity.name\n    \"Conference Room A\"\n\n"
  @spec create_entity(String.t(), String.t(), map(), keyword()) :: entity()
  def create_entity(id, name, properties \\ %{}, opts \\ []) do
    %{
      type: :entity,
      id: id,
      name: name,
      owner_agent_id: Keyword.get(opts, :owner_agent_id),
      properties: properties,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc "Checks if a participant is an entity.\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.EntityManagement.create_entity(\"room\", \"Conference Room\")\n    iex> Timeline.AgentEntity.EntityManagement.entity?(entity)\n    true\n\n"
  @spec entity?(participant()) :: boolean()
  def entity?(%{type: :entity}) do
    true
  end

  def entity?(_) do
    false
  end

  @doc "Validates that an entity is properly formed.\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.EntityManagement.create_entity(\"room\", \"Conference Room\")\n    iex> Timeline.AgentEntity.EntityManagement.valid_entity?(entity)\n    true\n\n"
  @spec valid_entity?(participant()) :: boolean()
  def valid_entity?(%{type: :entity, id: id, name: name})
      when is_binary(id) and is_binary(name) do
    String.length(id) > 0 and String.length(name) > 0
  end

  def valid_entity?(_) do
    false
  end
end
