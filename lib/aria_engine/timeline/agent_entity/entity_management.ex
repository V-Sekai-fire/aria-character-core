# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.AgentEntity.EntityManagement do
  @moduledoc """
  Entity creation and management operations for Timeline.AgentEntity.

  Handles the creation, validation, and basic operations for entities in the
  timeline system.
  """

  @type entity :: AriaEngine.Timeline.AgentEntity.entity()
  @type participant :: AriaEngine.Timeline.AgentEntity.participant()

  @doc """
  Creates a new entity.

  ## Parameters

  - `id`: Unique identifier for the entity
  - `name`: Human-readable name
  - `properties`: Entity-specific properties (e.g., location, state)
  - `opts`: Optional parameters including:
    - `:owner_agent_id` - ID of the agent that owns this entity
    - `:metadata` - Additional metadata

  ## Examples

      iex> entity = Timeline.AgentEntity.EntityManagement.create_entity(
      ...>   "conference_room",
      ...>   "Conference Room A",
      ...>   %{capacity: 10, location: "Building 1, Floor 2"},
      ...>   owner_agent_id: "facility_manager",
      ...>   metadata: %{building_id: "bldg_1"}
      ...> )
      iex> entity.type
      :entity
      iex> entity.name
      "Conference Room A"

  """
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

  @doc """
  Checks if a participant is an entity.

  ## Examples

      iex> entity = Timeline.AgentEntity.EntityManagement.create_entity("room", "Conference Room")
      iex> Timeline.AgentEntity.EntityManagement.entity?(entity)
      true

  """
  @spec entity?(participant()) :: boolean()
  def entity?(%{type: :entity}), do: true
  def entity?(_), do: false

  @doc """
  Validates that an entity is properly formed.

  ## Examples

      iex> entity = Timeline.AgentEntity.EntityManagement.create_entity("room", "Conference Room")
      iex> Timeline.AgentEntity.EntityManagement.valid_entity?(entity)
      true

  """
  @spec valid_entity?(participant()) :: boolean()
  def valid_entity?(%{type: :entity, id: id, name: name})
      when is_binary(id) and is_binary(name) do
    String.length(id) > 0 and String.length(name) > 0
  end

  def valid_entity?(_), do: false
end
