# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.AgentEntity do
  @moduledoc """
  Defines the semantic distinction between agents and entities in the timeline system.

  This module implements the agent vs entity distinction as specified in ADR-046,
  providing clear semantic types and operations for different kinds of temporal
  participants.

  ## Definitions

  ### Agent
  An autonomous entity capable of:
  - Making decisions
  - Taking actions
  - Having intentions and goals
  - Responding to events
  - Initiating temporal processes

  Examples: AI characters, NPCs, players, autonomous systems

  ### Entity
  A passive object that:
  - Exists in time
  - Can be acted upon
  - Has properties that change over time
  - Does not initiate actions independently
  - Participates in temporal relationships

  Examples: items, locations, resources, states, conditions

  ## Specialized Modules

  This module delegates to specialized sub-modules for different aspects of functionality:

  - `Timeline.AgentEntity.AgentManagement` - Agent creation and validation
  - `Timeline.AgentEntity.EntityManagement` - Entity creation and validation
  - `Timeline.AgentEntity.CapabilityManagement` - Capability checking and management
  - `Timeline.AgentEntity.StateTransitions` - Agent/entity state transitions
  - `Timeline.AgentEntity.PropertyManagement` - Property getting/setting
  - `Timeline.AgentEntity.OwnershipManagement` - Entity ownership operations
  - `Timeline.AgentEntity.Validation` - Participant validation

  ## Usage

      iex> alias Timeline.AgentEntity
      iex> agent = AgentEntity.create_agent("aria", "Aria VTuber", %{personality: "helpful"})
      iex> AgentEntity.agent?(agent)
      true
      iex> entity = AgentEntity.create_entity("conference_room", "Conference Room A", %{capacity: 10})
      iex> AgentEntity.entity?(entity)
      true

  ## References

  - ADR-046: Interval Notation Usability (agent vs entity debate)
  - ADR-078: Timeline Module PC-2 STN Implementation
  """

  alias Timeline.AgentEntity.AgentManagement
  alias Timeline.AgentEntity.EntityManagement
  alias Timeline.AgentEntity.CapabilityManagement
  alias Timeline.AgentEntity.StateTransitions
  alias Timeline.AgentEntity.PropertyManagement
  alias Timeline.AgentEntity.OwnershipManagement
  alias Timeline.AgentEntity.Validation

  @type agent :: %{
          type: :agent,
          id: String.t(),
          name: String.t(),
          capabilities: [atom()],
          properties: map(),
          metadata: map()
        }

  @type entity :: %{
          type: :entity,
          id: String.t(),
          name: String.t(),
          owner_agent_id: String.t() | nil,
          properties: map(),
          metadata: map()
        }

  @type hybrid :: %{
          type: :hybrid,
          id: String.t(),
          name: String.t(),
          current_mode: :agent | :entity,
          agent_capabilities: [atom()],
          properties: map(),
          metadata: map()
        }

  @type participant :: agent() | entity() | hybrid()

  # ==================== AGENT MANAGEMENT ====================

  @doc """
  Creates a new agent.

  Delegates to `Timeline.AgentEntity.AgentManagement.create_agent/4`.
  """
  defdelegate create_agent(id, name, properties \\ %{}, opts \\ []), to: AgentManagement

  @doc """
  Checks if a participant is an agent.

  Delegates to `Timeline.AgentEntity.AgentManagement.agent?/1`.
  """
  defdelegate agent?(participant), to: AgentManagement

  # ==================== ENTITY MANAGEMENT ====================

  @doc """
  Creates a new entity.

  Delegates to `Timeline.AgentEntity.EntityManagement.create_entity/4`.
  """
  defdelegate create_entity(id, name, properties \\ %{}, opts \\ []), to: EntityManagement

  @doc """
  Checks if a participant is an entity.

  Delegates to `Timeline.AgentEntity.EntityManagement.entity?/1`.
  """
  defdelegate entity?(participant), to: EntityManagement

  # ==================== CAPABILITY MANAGEMENT ====================

  @doc """
  Checks if an agent has a specific capability.

  Delegates to `Timeline.AgentEntity.CapabilityManagement.has_capability?/2`.
  """
  defdelegate has_capability?(participant, capability), to: CapabilityManagement

  @doc """
  Adds a capability to an agent.

  Delegates to `Timeline.AgentEntity.CapabilityManagement.add_capability/2`.
  """
  defdelegate add_capability(agent, capability), to: CapabilityManagement

  @doc """
  Removes action capabilities from a participant.

  Delegates to `Timeline.AgentEntity.CapabilityManagement.remove_capabilities/2`.
  """
  defdelegate remove_capabilities(participant, capabilities_to_remove), to: CapabilityManagement

  @doc """
  Adds action capabilities to a participant.

  Delegates to `Timeline.AgentEntity.CapabilityManagement.add_capabilities/2`.
  """
  defdelegate add_capabilities(participant, new_capabilities), to: CapabilityManagement

  @doc """
  Checks if a participant can perform an action.

  Delegates to `Timeline.AgentEntity.CapabilityManagement.can_perform_action?/2`.
  """
  defdelegate can_perform_action?(participant, action), to: CapabilityManagement

  @doc """
  Dynamically determines if a participant is currently acting as an agent.

  Delegates to `Timeline.AgentEntity.CapabilityManagement.is_currently_agent?/1`.
  """
  defdelegate is_currently_agent?(participant), to: CapabilityManagement

  # ==================== STATE TRANSITIONS ====================

  @doc """
  Transitions a participant to agent state.

  Delegates to `Timeline.AgentEntity.StateTransitions.transition_to_agent/2`.
  """
  defdelegate transition_to_agent(participant, action_capabilities), to: StateTransitions

  @doc """
  Transitions a participant to entity state.

  Delegates to `Timeline.AgentEntity.StateTransitions.transition_to_entity/1`.
  """
  defdelegate transition_to_entity(participant), to: StateTransitions

  # ==================== PROPERTY MANAGEMENT ====================

  @doc """
  Updates properties of a participant.

  Delegates to `Timeline.AgentEntity.PropertyManagement.update_properties/2`.
  """
  defdelegate update_properties(participant, new_properties), to: PropertyManagement

  @doc """
  Gets a property value from a participant.

  Delegates to `Timeline.AgentEntity.PropertyManagement.get_property/2`.
  """
  defdelegate get_property(participant, property_key), to: PropertyManagement

  @doc """
  Sets a property value for a participant.

  Delegates to `Timeline.AgentEntity.PropertyManagement.set_property/3`.
  """
  defdelegate set_property(participant, property_key, value), to: PropertyManagement

  # ==================== OWNERSHIP MANAGEMENT ====================

  @doc """
  Checks if an entity is owned by a specific agent.

  Delegates to `Timeline.AgentEntity.OwnershipManagement.owned_by?/2`.
  """
  defdelegate owned_by?(entity, agent_id), to: OwnershipManagement

  @doc """
  Checks if an entity has an owner.

  Delegates to `Timeline.AgentEntity.OwnershipManagement.has_owner?/1`.
  """
  defdelegate has_owner?(entity), to: OwnershipManagement

  @doc """
  Transfers ownership of an entity to a new agent.

  Delegates to `Timeline.AgentEntity.OwnershipManagement.transfer_ownership/2`.
  """
  defdelegate transfer_ownership(entity, new_owner_id), to: OwnershipManagement

  @doc """
  Removes ownership from an entity.

  Delegates to `Timeline.AgentEntity.OwnershipManagement.remove_ownership/1`.
  """
  defdelegate remove_ownership(entity), to: OwnershipManagement

  # ==================== VALIDATION ====================

  @doc """
  Validates that a participant is properly formed.

  Delegates to `Timeline.AgentEntity.Validation.valid?/1`.
  """
  defdelegate valid?(participant), to: Validation
end
