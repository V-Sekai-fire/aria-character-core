# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.AgentEntity.OwnershipManagement do
  @moduledoc "Ownership management operations for Timeline.AgentEntity.\n\nHandles ownership relationships between agents and entities, including\nownership checking, transfer, and removal.\n"
  @type entity :: Timeline.AgentEntity.entity()
  @doc "Checks if an entity is owned by a specific agent.\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.create_entity(\n    ...>   \"room\",\n    ...>   \"Conference Room\",\n    ...>   %{},\n    ...>   owner_agent_id: \"facility_manager\"\n    ...> )\n    iex> Timeline.AgentEntity.OwnershipManagement.owned_by?(entity, \"facility_manager\")\n    true\n    iex> Timeline.AgentEntity.OwnershipManagement.owned_by?(entity, \"other_agent\")\n    false\n\n"
  @spec owned_by?(entity(), String.t()) :: boolean()
  def owned_by?(%{type: :entity, owner_agent_id: owner_id}, agent_id) do
    owner_id == agent_id
  end

  def owned_by?(_, _) do
    false
  end

  @doc "Checks if an entity has an owner.\n\n## Examples\n\n    iex> owned_entity = Timeline.AgentEntity.create_entity(\n    ...>   \"room\",\n    ...>   \"Conference Room\",\n    ...>   %{},\n    ...>   owner_agent_id: \"facility_manager\"\n    ...> )\n    iex> Timeline.AgentEntity.OwnershipManagement.has_owner?(owned_entity)\n    true\n    iex> unowned_entity = Timeline.AgentEntity.create_entity(\"item\", \"Free Item\")\n    iex> Timeline.AgentEntity.OwnershipManagement.has_owner?(unowned_entity)\n    false\n\n"
  @spec has_owner?(entity()) :: boolean()
  def has_owner?(%{type: :entity, owner_agent_id: owner_id}) do
    not is_nil(owner_id)
  end

  def has_owner?(_) do
    false
  end

  @doc "Transfers ownership of an entity to a new agent.\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.create_entity(\n    ...>   \"room\",\n    ...>   \"Conference Room\",\n    ...>   %{},\n    ...>   owner_agent_id: \"old_manager\"\n    ...> )\n    iex> updated_entity = Timeline.AgentEntity.OwnershipManagement.transfer_ownership(entity, \"new_manager\")\n    iex> updated_entity.owner_agent_id\n    \"new_manager\"\n\n"
  @spec transfer_ownership(entity(), String.t()) :: entity()
  def transfer_ownership(%{type: :entity} = entity, new_owner_id) do
    %{entity | owner_agent_id: new_owner_id}
  end

  @doc "Removes ownership from an entity (makes it unowned).\n\n## Examples\n\n    iex> entity = Timeline.AgentEntity.create_entity(\n    ...>   \"room\",\n    ...>   \"Conference Room\",\n    ...>   %{},\n    ...>   owner_agent_id: \"manager\"\n    ...> )\n    iex> unowned_entity = Timeline.AgentEntity.OwnershipManagement.remove_ownership(entity)\n    iex> unowned_entity.owner_agent_id\n    nil\n\n"
  @spec remove_ownership(entity()) :: entity()
  def remove_ownership(%{type: :entity} = entity) do
    %{entity | owner_agent_id: nil}
  end
end
