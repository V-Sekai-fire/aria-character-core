# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.AgentEntity.OwnershipManagement do
  @moduledoc """
  Ownership management operations for Timeline.AgentEntity.

  Handles ownership relationships between agents and entities, including
  ownership checking, transfer, and removal.
  """

  @type entity :: Timeline.AgentEntity.entity()

  @doc """
  Checks if an entity is owned by a specific agent.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "facility_manager"
      ...> )
      iex> Timeline.AgentEntity.OwnershipManagement.owned_by?(entity, "facility_manager")
      true
      iex> Timeline.AgentEntity.OwnershipManagement.owned_by?(entity, "other_agent")
      false

  """
  @spec owned_by?(entity(), String.t()) :: boolean()
  def owned_by?(%{type: :entity, owner_agent_id: owner_id}, agent_id) do
    owner_id == agent_id
  end

  def owned_by?(_, _), do: false

  @doc """
  Checks if an entity has an owner.

  ## Examples

      iex> owned_entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "facility_manager"
      ...> )
      iex> Timeline.AgentEntity.OwnershipManagement.has_owner?(owned_entity)
      true
      iex> unowned_entity = Timeline.AgentEntity.create_entity("item", "Free Item")
      iex> Timeline.AgentEntity.OwnershipManagement.has_owner?(unowned_entity)
      false

  """
  @spec has_owner?(entity()) :: boolean()
  def has_owner?(%{type: :entity, owner_agent_id: owner_id}) do
    not is_nil(owner_id)
  end

  def has_owner?(_), do: false

  @doc """
  Transfers ownership of an entity to a new agent.

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "old_manager"
      ...> )
      iex> updated_entity = Timeline.AgentEntity.OwnershipManagement.transfer_ownership(entity, "new_manager")
      iex> updated_entity.owner_agent_id
      "new_manager"

  """
  @spec transfer_ownership(entity(), String.t()) :: entity()
  def transfer_ownership(%{type: :entity} = entity, new_owner_id) do
    %{entity | owner_agent_id: new_owner_id}
  end

  @doc """
  Removes ownership from an entity (makes it unowned).

  ## Examples

      iex> entity = Timeline.AgentEntity.create_entity(
      ...>   "room",
      ...>   "Conference Room",
      ...>   %{},
      ...>   owner_agent_id: "manager"
      ...> )
      iex> unowned_entity = Timeline.AgentEntity.OwnershipManagement.remove_ownership(entity)
      iex> unowned_entity.owner_agent_id
      nil

  """
  @spec remove_ownership(entity()) :: entity()
  def remove_ownership(%{type: :entity} = entity) do
    %{entity | owner_agent_id: nil}
  end
end
